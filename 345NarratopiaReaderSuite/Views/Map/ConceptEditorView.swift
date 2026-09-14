import SwiftUI

struct ConceptEditorView: View {
    @EnvironmentObject private var store: DeskStore
    @Environment(\.dismiss) private var dismiss

    let conceptID: UUID?
    let fallbackPoint: (Double, Double)

    @State private var title: String = ""
    @State private var note: String = ""
    @State private var themeId: UUID?
    @State private var attempted = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    BannerHeader(
                        image: "BannerMap",
                        kicker: conceptID == nil ? "NEW NODE" : "REVISE",
                        title: conceptID == nil ? "Add Concept" : "Edit Concept",
                        subtitle: "Name the idea. Drag it later on the navy canvas."
                    )
                    InlineField(
                        caption: "TITLE",
                        placeholder: "Concept title",
                        text: $title,
                        warning: TitleGuard.warning(for: title, attempted: attempted)
                    )
                    InlineField(
                        caption: "NOTE",
                        placeholder: "A short gloss",
                        text: $note,
                        tall: true
                    )
                    ThemeMenu(themeId: $themeId)
                    DeskButton(title: "Save Concept") {
                        attempted = true
                        guard let bookId = store.selectedBookID else { return }
                        let point = existingPoint ?? fallbackPoint
                        if store.upsertConcept(
                            id: conceptID,
                            bookId: bookId,
                            title: title,
                            note: note,
                            themeId: themeId,
                            x: point.0,
                            y: point.1
                        ) {
                            dismiss()
                        }
                    }

                    relatedSection
                }
                .padding(20)
            }
            .readingCanvas()
            .navigationTitle(conceptID == nil ? "Add Concept" : "Edit Concept")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Palette.accent)
                }
            }
            .onAppear {
                if let conceptID, let concept = store.concepts.first(where: { item in item.id == conceptID }) {
                    title = concept.title
                    note = concept.note
                    themeId = concept.themeId
                }
            }
        }
    }

    private var existingPoint: (Double, Double)? {
        guard let conceptID, let concept = store.concepts.first(where: { item in item.id == conceptID }) else {
            return nil
        }
        return (concept.x, concept.y)
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
                    motif: relatedNoteLine(for: note)
                )
            }
            ForEach(relatedConcepts.prefix(4)) { concept in
                IndexCard(
                    title: concept.title,
                    detail: concept.note,
                    motif: atlasLine(for: concept)
                )
            }
        }
    }

    private var relatedNotes: [ReadingNote] {
        store.notesSharingMotif(themeId: themeId, excluding: nil)
    }

    private var relatedConcepts: [Concept] {
        store.conceptsSharingMotif(themeId: themeId, excluding: conceptID)
    }

    private func relatedNoteLine(for note: ReadingNote) -> String {
        let volume = store.book(id: note.bookId)?.title ?? "Volume"
        let place = TitleGuard.trimmed(note.locator)
        if place.isEmpty { return "Journal · \(volume)" }
        return "Journal · \(volume) · \(place)"
    }

    private func atlasLine(for concept: Concept) -> String {
        let volume = store.book(id: concept.bookId)?.title ?? "Volume"
        return "Atlas · \(volume)"
    }
}
