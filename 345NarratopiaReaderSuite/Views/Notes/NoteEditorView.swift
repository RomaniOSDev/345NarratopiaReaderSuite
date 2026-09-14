import SwiftUI

struct NoteEditorView: View {
    @EnvironmentObject private var store: DeskStore
    @Environment(\.dismiss) private var dismiss

    let noteID: UUID?

    @State private var workingNoteID: UUID?
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var themeId: UUID?
    @State private var locator: String = ""
    @State private var attempted = false
    @State private var didSave = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    BannerHeader(
                        image: "BannerJournal",
                        kicker: workingNoteID == nil ? "NEW CARD" : "REVISE",
                        title: workingNoteID == nil ? "Add Note" : "Edit Note",
                        subtitle: "Index cards need a title. Mark the page if you want to find it later."
                    )
                    InlineField(
                        caption: "TITLE",
                        placeholder: "Card title",
                        text: $title,
                        warning: TitleGuard.warning(for: title, attempted: attempted)
                    )
                    InlineField(
                        caption: "PASSAGE",
                        placeholder: "What stays with you",
                        text: $bodyText,
                        tall: true
                    )
                    InlineField(
                        caption: "WHERE",
                        placeholder: "Page, chapter, or leaf",
                        text: $locator
                    )
                    ThemeMenu(themeId: $themeId)
                    DeskButton(title: "Save Card") {
                        attempted = true
                        guard let bookId = store.selectedBookID else { return }
                        if store.upsertNote(
                            id: workingNoteID,
                            bookId: bookId,
                            title: title,
                            body: bodyText,
                            themeId: themeId,
                            locator: locator
                        ) {
                            didSave = true
                            store.clearNoteDraft()
                            dismiss()
                        }
                    }

                    relatedSection
                }
                .padding(20)
            }
            .readingCanvas()
            .navigationTitle(workingNoteID == nil ? "Add Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Palette.accent)
                }
            }
            .onAppear {
                hydrate()
            }
            .onDisappear {
                if didSave { return }
                store.captureNoteDraft(
                    noteID: workingNoteID,
                    title: title,
                    body: bodyText,
                    themeId: themeId,
                    locator: locator
                )
            }
        }
    }

    private var relatedNotes: [ReadingNote] {
        store.notesSharingMotif(themeId: themeId, excluding: workingNoteID)
    }

    private var relatedConcepts: [Concept] {
        store.conceptsSharingMotif(themeId: themeId, excluding: nil)
    }

    @ViewBuilder
    private var relatedSection: some View {
        if themeId != nil && (relatedNotes.isEmpty == false || relatedConcepts.isEmpty == false) {
            Text("MORE ON THIS MOTIF")
                .font(ScholarType.caption)
                .tracking(1.4)
                .foregroundColor(Palette.accent)
            ForEach(relatedNotes.prefix(4)) { note in
                IndexCard(
                    title: note.title,
                    detail: note.body,
                    motif: relatedMotifLine(for: note)
                )
                .onTapGesture {
                    loadRelated(note)
                }
            }
            ForEach(relatedConcepts.prefix(4)) { concept in
                IndexCard(
                    title: concept.title,
                    detail: concept.note,
                    motif: atlasMotifLine(for: concept)
                )
            }
        }
    }

    private func hydrate() {
        workingNoteID = noteID
        didSave = false
        if let noteID, let note = store.notes.first(where: { item in item.id == noteID }) {
            apply(note)
        }
        if let draft = store.noteDraft,
           draft.bookId == store.selectedBookID,
           draft.noteID == noteID {
            title = draft.title
            bodyText = draft.body
            themeId = draft.themeId
            locator = draft.locator
        }
    }

    private func apply(_ note: ReadingNote) {
        title = note.title
        bodyText = note.body
        themeId = note.themeId
        locator = note.locator
        store.rememberNote(note.id)
        if store.selectedBookID != note.bookId {
            store.selectBook(note.bookId)
        }
    }

    private func loadRelated(_ note: ReadingNote) {
        store.captureNoteDraft(
            noteID: workingNoteID,
            title: title,
            body: bodyText,
            themeId: themeId,
            locator: locator
        )
        workingNoteID = note.id
        apply(note)
        attempted = false
        didSave = false
    }

    private func relatedMotifLine(for note: ReadingNote) -> String {
        let volume = store.book(id: note.bookId)?.title ?? "Volume"
        let place = TitleGuard.trimmed(note.locator)
        if place.isEmpty { return volume }
        return "\(volume) · \(place)"
    }

    private func atlasMotifLine(for concept: Concept) -> String {
        let volume = store.book(id: concept.bookId)?.title ?? "Volume"
        return "Atlas · \(volume)"
    }
}
