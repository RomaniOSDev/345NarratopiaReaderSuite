import SwiftUI

struct NotesView: View {
    @EnvironmentObject private var store: DeskStore
    @State private var editorOpen = false
    @State private var themeSheetOpen = false
    @State private var pendingDelete: ReadingNote?
    @State private var editingNoteID: UUID?
    @State private var query = ""
    @State private var motifFilter: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BannerHeader(
                    image: "BannerJournal",
                    kicker: "CARDS",
                    title: "The Journal",
                    subtitle: currentVolumeLine
                )

                bookPicker

                if store.selectedBookID != nil {
                    InlineField(
                        caption: "FIND",
                        placeholder: "Search titles, passages, or pages",
                        text: $query
                    )
                    motifFilterRow
                }

                if let draft = store.noteDraft, draft.bookId == store.selectedBookID {
                    IndexCard(
                        title: "A draft waits",
                        detail: draft.title.isEmpty ? "Unfinished card, still on the blotter." : draft.title,
                        motif: "Continue"
                    ) {
                        Text("Open")
                            .font(ScholarType.caption)
                            .foregroundColor(Palette.accent)
                    }
                    .onTapGesture {
                        editingNoteID = draft.noteID
                        editorOpen = true
                    }
                }

                if store.selectedBookID == nil {
                    EmptyPrompt(
                        title: "Choose a volume",
                        detail: "Open the library and add a book before writing cards."
                    )
                } else if store.notes(for: store.selectedBookID ?? UUID()).isEmpty {
                    EmptyPrompt(
                        title: "No cards yet",
                        detail: "Write a first passage, question, or aside for this volume."
                    )
                } else if cards.isEmpty {
                    EmptyPrompt(
                        title: "No matching cards",
                        detail: "Clear the search or motif filter to see the full journal."
                    )
                } else {
                    ForEach(cards) { note in
                        IndexCard(
                            title: note.title,
                            detail: note.body,
                            motif: motifLine(for: note),
                            emphasized: store.lastViewedNoteID == note.id
                        ) {
                            Button {
                                pendingDelete = note
                            } label: {
                                Text("Remove")
                                    .font(ScholarType.caption)
                                    .foregroundColor(Palette.accent)
                            }
                            .buttonStyle(.plain)
                        }
                        .onTapGesture {
                            store.rememberNote(note.id)
                            editingNoteID = note.id
                            editorOpen = true
                        }
                    }
                }

                if store.selectedBookID != nil {
                    DeskButton(title: "Add Note") {
                        editingNoteID = nil
                        editorOpen = true
                    }
                    if store.notes(for: store.selectedBookID ?? UUID()).isEmpty == false {
                        DeskButton(title: "Draw a Card", emphasized: false) {
                            drawCard()
                        }
                    }
                    DeskButton(title: "Motifs", emphasized: false) {
                        themeSheetOpen = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .readingCanvas()
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editorOpen) {
            NoteEditorView(noteID: editingNoteID)
        }
        .sheet(isPresented: $themeSheetOpen) {
            ThemeEditorView()
        }
        .confirmationDialog("Delete this card?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if $0 == false { pendingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Note", role: .destructive) {
                if let pendingDelete {
                    store.deleteNote(pendingDelete.id)
                }
                pendingDelete = nil
            }
            Button("Keep", role: .cancel) {
                pendingDelete = nil
            }
        }
    }

    private var cards: [ReadingNote] {
        guard let bookID = store.selectedBookID else { return [] }
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.notes(for: bookID).filter { note in
            let matchesQuery = needle.isEmpty
                || note.title.localizedCaseInsensitiveContains(needle)
                || note.body.localizedCaseInsensitiveContains(needle)
                || note.locator.localizedCaseInsensitiveContains(needle)
            let matchesMotif = motifFilter == nil || note.themeId == motifFilter
            return matchesQuery && matchesMotif
        }
    }

    private var currentVolumeLine: String {
        if let book = store.selectedBook {
            return "Cards for \(book.title)."
        }
        return "Select a volume to keep index cards."
    }

    private var bookPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VOLUME")
                .font(ScholarType.caption)
                .tracking(1.4)
                .foregroundColor(Palette.accent)
            Menu {
                ForEach(store.books) { book in
                    Button(book.title) {
                        store.selectBook(book.id)
                        query = ""
                        motifFilter = nil
                    }
                }
            } label: {
                HStack {
                    Text(store.selectedBook?.title ?? "None selected")
                        .font(ScholarType.body)
                        .foregroundColor(Palette.primary)
                    Spacer()
                    Text("Switch")
                        .font(ScholarType.caption)
                        .foregroundColor(Palette.accent)
                }
                .padding(12)
                .background(Palette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Palette.accent.opacity(0.24), lineWidth: 1)
                }
            }
        }
    }

    private var motifFilterRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MOTIF FILTER")
                .font(ScholarType.caption)
                .tracking(1.4)
                .foregroundColor(Palette.accent)
            Menu {
                Button("All motifs") {
                    motifFilter = nil
                }
                ForEach(store.themes) { theme in
                    Button(theme.name) {
                        motifFilter = theme.id
                    }
                }
            } label: {
                HStack {
                    Text(store.theme(id: motifFilter)?.name ?? "All motifs")
                        .font(ScholarType.body)
                        .foregroundColor(Palette.primary)
                    Spacer()
                    Text("Filter")
                        .font(ScholarType.caption)
                        .foregroundColor(Palette.accent)
                }
                .padding(12)
                .background(Palette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Palette.accent.opacity(0.24), lineWidth: 1)
                }
            }
        }
    }

    private func motifLine(for note: ReadingNote) -> String? {
        let theme = store.theme(id: note.themeId)?.name
        let place = TitleGuard.trimmed(note.locator)
        if place.isEmpty { return theme }
        if let theme { return "\(place) · \(theme)" }
        return place
    }

    private func drawCard() {
        guard let bookID = store.selectedBookID else { return }
        let pool = store.notes(for: bookID)
        guard let card = pool.randomElement() else { return }
        store.rememberNote(card.id)
        editingNoteID = card.id
        editorOpen = true
    }
}
