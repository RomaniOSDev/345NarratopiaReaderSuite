import Combine
import Foundation

@MainActor
final class DeskStore: ObservableObject {
    @Published var books: [BookItem] = []
    @Published var themes: [Theme] = []
    @Published var concepts: [Concept] = []
    @Published var notes: [ReadingNote] = []
    @Published var noteLinks: [NoteLink] = []
    @Published var selectedBookID: UUID?
    @Published var lastViewedNoteID: UUID?
    @Published var lastVisitedNodeID: UUID?
    @Published var pinnedConceptID: UUID?
    @Published var noteDraft: NoteDraft?
    @Published var sessionAnchor: Date?
    @Published var sessionSecondsToday: Int = 0
    @Published var deskEpoch: Int = 0

    private var sessionDayStamp: String = ""

    init() {
        loadAll()
        if UserDefaults.standard.data(forKey: StorageKeys.books) == nil {
            seedSampleLibrary()
            persistAll()
        }
        rollSessionDay(Date())
    }

    var selectedBook: BookItem? {
        guard let selectedBookID else { return nil }
        return books.first { book in book.id == selectedBookID }
    }

    func notes(for bookID: UUID) -> [ReadingNote] {
        notes
            .filter { note in note.bookId == bookID }
            .sorted { lhs, rhs in lhs.createdAt > rhs.createdAt }
    }

    func concepts(for bookID: UUID) -> [Concept] {
        concepts.filter { concept in concept.bookId == bookID }
    }

    func links(for bookID: UUID) -> [NoteLink] {
        let ids = Set(concepts(for: bookID).map(\.id))
        return noteLinks.filter { link in
            ids.contains(link.fromID) && ids.contains(link.toID)
        }
    }

    func theme(id: UUID?) -> Theme? {
        guard let id else { return nil }
        return themes.first { theme in theme.id == id }
    }

    func book(id: UUID?) -> BookItem? {
        guard let id else { return nil }
        return books.first { book in book.id == id }
    }

    func selectBook(_ id: UUID?) {
        selectedBookID = id
        DefaultsBox.saveUUID(id, key: StorageKeys.selectedBookID)
        if let id {
            touchBook(id)
        }
    }

    func rememberNote(_ id: UUID?) {
        lastViewedNoteID = id
        DefaultsBox.saveUUID(id, key: StorageKeys.lastViewedNoteID)
    }

    func rememberNode(_ id: UUID?) {
        lastVisitedNodeID = id
        DefaultsBox.saveUUID(id, key: StorageKeys.lastVisitedNodeID)
    }

    func pinConcept(_ id: UUID?) {
        pinnedConceptID = id
        DefaultsBox.saveUUID(id, key: StorageKeys.pinnedConceptID)
    }

    func setBookStatus(_ id: UUID, _ status: ReadingStatus) {
        guard let index = books.firstIndex(where: { book in book.id == id }) else { return }
        books[index].status = status
        books[index].touchedAt = Date()
        persistBooks()
    }

    func upsertBook(id: UUID?, title: String, author: String, status: ReadingStatus) -> Bool {
        let cleaned = TitleGuard.trimmed(title)
        guard TitleGuard.isPresent(cleaned) else { return false }
        let writer = TitleGuard.trimmed(author)
        if let id, let index = books.firstIndex(where: { book in book.id == id }) {
            books[index].title = cleaned
            books[index].author = writer
            books[index].status = status
            books[index].touchedAt = Date()
        } else {
            let book = BookItem(title: cleaned, author: writer, status: status)
            books.append(book)
            selectBook(book.id)
        }
        persistBooks()
        return true
    }

    func deleteBook(_ id: UUID) {
        books.removeAll { book in book.id == id }
        let orphanConcepts = concepts.filter { concept in concept.bookId == id }.map(\.id)
        notes.removeAll { note in note.bookId == id }
        concepts.removeAll { concept in concept.bookId == id }
        noteLinks.removeAll { link in
            orphanConcepts.contains(link.fromID) || orphanConcepts.contains(link.toID)
        }
        if selectedBookID == id {
            selectBook(books.first?.id)
        }
        if let lastViewedNoteID, notes.contains(where: { note in note.id == lastViewedNoteID }) == false {
            rememberNote(nil)
        }
        if let lastVisitedNodeID, concepts.contains(where: { concept in concept.id == lastVisitedNodeID }) == false {
            rememberNode(nil)
        }
        if let pinnedConceptID, concepts.contains(where: { concept in concept.id == pinnedConceptID }) == false {
            pinConcept(nil)
        }
        if noteDraft?.bookId == id {
            clearNoteDraft()
        }
        persistAll()
    }

    func upsertTheme(id: UUID?, name: String) -> Bool {
        let cleaned = TitleGuard.trimmed(name)
        guard TitleGuard.isPresent(cleaned) else { return false }
        if let id, let index = themes.firstIndex(where: { theme in theme.id == id }) {
            themes[index].name = cleaned
        } else {
            themes.append(Theme(name: cleaned))
        }
        persistThemes()
        return true
    }

    func deleteTheme(_ id: UUID) {
        themes.removeAll { theme in theme.id == id }
        for index in notes.indices where notes[index].themeId == id {
            notes[index].themeId = nil
        }
        for index in concepts.indices where concepts[index].themeId == id {
            concepts[index].themeId = nil
        }
        persistThemes()
        persistNotes()
        persistConcepts()
    }

    func upsertNote(id: UUID?, bookId: UUID, title: String, body: String, themeId: UUID?, locator: String) -> Bool {
        let cleaned = TitleGuard.trimmed(title)
        guard TitleGuard.isPresent(cleaned) else { return false }
        let place = TitleGuard.trimmed(locator)
        if let id, let index = notes.firstIndex(where: { note in note.id == id }) {
            notes[index].title = cleaned
            notes[index].body = body
            notes[index].themeId = themeId
            notes[index].locator = place
            rememberNote(id)
        } else {
            let note = ReadingNote(bookId: bookId, title: cleaned, body: body, themeId: themeId, locator: place)
            notes.insert(note, at: 0)
            rememberNote(note.id)
        }
        touchBook(bookId)
        persistNotes()
        return true
    }

    func deleteNote(_ id: UUID) {
        notes.removeAll { note in note.id == id }
        if lastViewedNoteID == id {
            rememberNote(nil)
        }
        if noteDraft?.noteID == id {
            clearNoteDraft()
        }
        persistNotes()
    }

    func upsertConcept(
        id: UUID?,
        bookId: UUID,
        title: String,
        note: String,
        themeId: UUID?,
        x: Double,
        y: Double
    ) -> Bool {
        let cleaned = TitleGuard.trimmed(title)
        guard TitleGuard.isPresent(cleaned) else { return false }
        if let id, let index = concepts.firstIndex(where: { concept in concept.id == id }) {
            concepts[index].title = cleaned
            concepts[index].note = note
            concepts[index].themeId = themeId
            concepts[index].x = x
            concepts[index].y = y
            rememberNode(id)
        } else {
            let concept = Concept(
                title: cleaned,
                note: note,
                themeId: themeId,
                bookId: bookId,
                x: x,
                y: y
            )
            concepts.append(concept)
            rememberNode(concept.id)
        }
        touchBook(bookId)
        persistConcepts()
        return true
    }

    func moveConcept(id: UUID, x: Double, y: Double, persist: Bool) {
        guard let index = concepts.firstIndex(where: { concept in concept.id == id }) else { return }
        concepts[index].x = x
        concepts[index].y = y
        if persist {
            persistConcepts()
        }
    }

    func deleteConcept(_ id: UUID) {
        concepts.removeAll { concept in concept.id == id }
        noteLinks.removeAll { link in link.fromID == id || link.toID == id }
        if lastVisitedNodeID == id {
            rememberNode(nil)
        }
        if pinnedConceptID == id {
            pinConcept(nil)
        }
        persistConcepts()
        persistLinks()
    }

    func upsertLink(id: UUID?, fromID: UUID, toID: UUID, label: String) -> Bool {
        guard fromID != toID else { return false }
        let caption = TitleGuard.trimmed(label)
        if let id, let index = noteLinks.firstIndex(where: { link in link.id == id }) {
            noteLinks[index].fromID = fromID
            noteLinks[index].toID = toID
            noteLinks[index].label = caption
        } else {
            let duplicate = noteLinks.contains { link in
                (link.fromID == fromID && link.toID == toID) ||
                (link.fromID == toID && link.toID == fromID)
            }
            if duplicate { return false }
            noteLinks.append(NoteLink(fromID: fromID, toID: toID, label: caption))
        }
        persistLinks()
        return true
    }

    func deleteLink(_ id: UUID) {
        noteLinks.removeAll { link in link.id == id }
        persistLinks()
    }

    func nextConceptPoint(for bookID: UUID) -> (Double, Double) {
        let count = concepts(for: bookID).count
        let column = Double(count % 3)
        let row = Double(count / 3)
        return (92 + column * 118, 88 + row * 104)
    }

    func notesSharingMotif(themeId: UUID?, excluding noteID: UUID?) -> [ReadingNote] {
        guard let themeId else { return [] }
        return notes
            .filter { note in note.themeId == themeId && note.id != noteID }
            .sorted { lhs, rhs in lhs.createdAt > rhs.createdAt }
    }

    func conceptsSharingMotif(themeId: UUID?, excluding conceptID: UUID?) -> [Concept] {
        guard let themeId else { return [] }
        return concepts.filter { concept in
            concept.themeId == themeId && concept.id != conceptID
        }
    }

    func quietBooks(olderThan days: Int = 14) -> [BookItem] {
        let cutoff = Date().addingTimeInterval(-86_400 * Double(days))
        return books
            .filter { book in book.touchedAt < cutoff }
            .sorted { lhs, rhs in lhs.touchedAt < rhs.touchedAt }
    }

    func quoteOfTheDay() -> ReadingNote? {
        guard notes.isEmpty == false else { return nil }
        let ordered = notes.sorted { lhs, rhs in lhs.id.uuidString < rhs.id.uuidString }
        let day = Calendar.current.startOfDay(for: Date())
        let seed = Int(day.timeIntervalSince1970)
        let index = abs(seed) % ordered.count
        return ordered[index]
    }

    func captureNoteDraft(noteID: UUID?, title: String, body: String, themeId: UUID?, locator: String) {
        guard let bookId = selectedBookID else { return }
        let cleanedTitle = TitleGuard.trimmed(title)
        let cleanedBody = TitleGuard.trimmed(body)
        let place = TitleGuard.trimmed(locator)
        if cleanedTitle.isEmpty && cleanedBody.isEmpty && place.isEmpty && themeId == nil {
            if noteDraft?.noteID == noteID && noteDraft?.bookId == bookId {
                clearNoteDraft()
            }
            return
        }
        noteDraft = NoteDraft(
            bookId: bookId,
            noteID: noteID,
            title: title,
            body: body,
            themeId: themeId,
            locator: locator
        )
        persistDraft()
    }

    func clearNoteDraft() {
        noteDraft = nil
        DefaultsBox.remove(StorageKeys.noteDraft)
    }

    func beginSitting() {
        rollSessionDay(Date())
        guard sessionAnchor == nil else { return }
        sessionAnchor = Date()
        persistSession()
    }

    func pauseSitting() {
        rollSessionDay(Date())
        guard let sessionAnchor else { return }
        sessionSecondsToday += max(0, Int(Date().timeIntervalSince(sessionAnchor)))
        self.sessionAnchor = nil
        persistSession()
    }

    func sittingSeconds(at now: Date = Date()) -> Int {
        var total = sessionDayStamp == Self.dayStamp(now) ? sessionSecondsToday : 0
        if let sessionAnchor {
            total += max(0, Int(now.timeIntervalSince(sessionAnchor)))
        }
        return total
    }

    func sittingLabel(at now: Date = Date()) -> String {
        let seconds = sittingSeconds(at: now)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remain = seconds % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m \(remain)s"
        }
        return "\(remain)s"
    }

    func resetAllData() {
        pauseSitting()
        books = []
        themes = []
        concepts = []
        notes = []
        noteLinks = []
        selectedBookID = nil
        lastViewedNoteID = nil
        lastVisitedNodeID = nil
        pinnedConceptID = nil
        noteDraft = nil
        sessionSecondsToday = 0
        sessionAnchor = nil
        deskEpoch += 1
        persistAll()
        NotificationCenter.default.post(name: Notification.Name("dataReset"), object: nil)
    }

    private func touchBook(_ id: UUID) {
        guard let index = books.firstIndex(where: { book in book.id == id }) else { return }
        books[index].touchedAt = Date()
        persistBooks()
    }

    private func seedSampleLibrary() {
        let meditations = BookItem(
            title: "Meditations",
            author: "Marcus Aurelius",
            status: .inHand,
            touchedAt: Date().addingTimeInterval(-86_400 * 2)
        )
        let odyssey = BookItem(
            title: "The Odyssey",
            author: "Homer",
            status: .shelf,
            touchedAt: Date().addingTimeInterval(-86_400 * 20)
        )
        let room = BookItem(
            title: "A Room of One's Own",
            author: "Virginia Woolf",
            status: .finished,
            touchedAt: Date().addingTimeInterval(-86_400 * 16)
        )
        books = [meditations, odyssey, room]

        let motif = Theme(name: "Motif")
        let argument = Theme(name: "Argument")
        let character = Theme(name: "Character")
        themes = [motif, argument, character]

        let day: TimeInterval = 86_400
        notes = [
            ReadingNote(
                bookId: meditations.id,
                title: "The inner citadel",
                body: "The mind can keep its own weather, even when the city is loud.",
                themeId: argument.id,
                locator: "Book IV",
                createdAt: Date().addingTimeInterval(-day * 6)
            ),
            ReadingNote(
                bookId: meditations.id,
                title: "Morning page",
                body: "Begin the day by naming what is already enough.",
                themeId: motif.id,
                locator: "Book V",
                createdAt: Date().addingTimeInterval(-day * 3)
            ),
            ReadingNote(
                bookId: odyssey.id,
                title: "No one",
                body: "A name withheld becomes a weapon, then a wound.",
                themeId: character.id,
                locator: "Book IX",
                createdAt: Date().addingTimeInterval(-day * 4)
            ),
            ReadingNote(
                bookId: odyssey.id,
                title: "The wine-dark sea",
                body: "Distance is not emptiness. It is the space in which return is imagined.",
                themeId: motif.id,
                locator: "Book I",
                createdAt: Date().addingTimeInterval(-day * 1)
            ),
            ReadingNote(
                bookId: room.id,
                title: "A lock and a room",
                body: "Money and a door: the two conditions of a mind left alone with a book.",
                themeId: argument.id,
                locator: "Ch. 1",
                createdAt: Date().addingTimeInterval(-day * 2)
            ),
            ReadingNote(
                bookId: room.id,
                title: "Shakespeare's sister",
                body: "Genius needs a table, not a legend.",
                themeId: character.id,
                locator: "Ch. 3",
                createdAt: Date()
            )
        ]

        let duty = Concept(
            title: "Duty",
            note: "What is owed without audience.",
            themeId: argument.id,
            bookId: meditations.id,
            x: 92,
            y: 88
        )
        let weather = Concept(
            title: "Weather of mind",
            note: "Inner climate against the city's noise.",
            themeId: motif.id,
            bookId: meditations.id,
            x: 210,
            y: 88
        )
        let nobody = Concept(
            title: "Nobody",
            note: "A withheld name.",
            themeId: character.id,
            bookId: odyssey.id,
            x: 92,
            y: 88
        )
        let nostos = Concept(
            title: "Nostos",
            note: "The long way back.",
            themeId: motif.id,
            bookId: odyssey.id,
            x: 210,
            y: 140
        )
        concepts = [duty, weather, nobody, nostos]
        noteLinks = [
            NoteLink(fromID: duty.id, toID: weather.id, label: "steadies"),
            NoteLink(fromID: nobody.id, toID: nostos.id, label: "delays")
        ]
        selectedBookID = meditations.id
        lastViewedNoteID = notes.first?.id
        lastVisitedNodeID = duty.id
        pinnedConceptID = duty.id
    }

    private func loadAll() {
        books = DefaultsBox.load([BookItem].self, key: StorageKeys.books) ?? []
        themes = DefaultsBox.load([Theme].self, key: StorageKeys.themes) ?? []
        concepts = DefaultsBox.load([Concept].self, key: StorageKeys.concepts) ?? []
        notes = DefaultsBox.load([ReadingNote].self, key: StorageKeys.notes) ?? []
        noteLinks = DefaultsBox.load([NoteLink].self, key: StorageKeys.noteLinks) ?? []
        selectedBookID = DefaultsBox.loadUUID(key: StorageKeys.selectedBookID)
        lastViewedNoteID = DefaultsBox.loadUUID(key: StorageKeys.lastViewedNoteID)
        lastVisitedNodeID = DefaultsBox.loadUUID(key: StorageKeys.lastVisitedNodeID)
        pinnedConceptID = DefaultsBox.loadUUID(key: StorageKeys.pinnedConceptID)
        noteDraft = DefaultsBox.load(NoteDraft.self, key: StorageKeys.noteDraft)
        sessionSecondsToday = UserDefaults.standard.integer(forKey: StorageKeys.sessionSecondsToday)
        sessionDayStamp = UserDefaults.standard.string(forKey: StorageKeys.sessionDay) ?? ""
        let anchor = UserDefaults.standard.double(forKey: StorageKeys.sessionAnchor)
        sessionAnchor = anchor > 0 ? Date(timeIntervalSince1970: anchor) : nil
        if let selectedBookID, books.contains(where: { book in book.id == selectedBookID }) == false {
            self.selectedBookID = books.first?.id
        }
        if let pinnedConceptID, concepts.contains(where: { concept in concept.id == pinnedConceptID }) == false {
            self.pinnedConceptID = nil
        }
    }

    private func persistAll() {
        persistBooks()
        persistThemes()
        persistConcepts()
        persistNotes()
        persistLinks()
        DefaultsBox.saveUUID(selectedBookID, key: StorageKeys.selectedBookID)
        DefaultsBox.saveUUID(lastViewedNoteID, key: StorageKeys.lastViewedNoteID)
        DefaultsBox.saveUUID(lastVisitedNodeID, key: StorageKeys.lastVisitedNodeID)
        DefaultsBox.saveUUID(pinnedConceptID, key: StorageKeys.pinnedConceptID)
        persistDraft()
        persistSession()
    }

    private func persistBooks() {
        DefaultsBox.save(books, key: StorageKeys.books)
    }

    private func persistThemes() {
        DefaultsBox.save(themes, key: StorageKeys.themes)
    }

    private func persistConcepts() {
        DefaultsBox.save(concepts, key: StorageKeys.concepts)
    }

    private func persistNotes() {
        DefaultsBox.save(notes, key: StorageKeys.notes)
    }

    private func persistLinks() {
        DefaultsBox.save(noteLinks, key: StorageKeys.noteLinks)
    }

    private func persistDraft() {
        if let noteDraft {
            DefaultsBox.save(noteDraft, key: StorageKeys.noteDraft)
        } else {
            DefaultsBox.remove(StorageKeys.noteDraft)
        }
    }

    private func persistSession() {
        UserDefaults.standard.set(sessionSecondsToday, forKey: StorageKeys.sessionSecondsToday)
        UserDefaults.standard.set(sessionDayStamp, forKey: StorageKeys.sessionDay)
        if let sessionAnchor {
            UserDefaults.standard.set(sessionAnchor.timeIntervalSince1970, forKey: StorageKeys.sessionAnchor)
        } else {
            UserDefaults.standard.removeObject(forKey: StorageKeys.sessionAnchor)
        }
    }

    private func rollSessionDay(_ now: Date) {
        let stamp = Self.dayStamp(now)
        guard sessionDayStamp != stamp else { return }
        sessionSecondsToday = 0
        sessionDayStamp = stamp
        persistSession()
    }

    private static func dayStamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
