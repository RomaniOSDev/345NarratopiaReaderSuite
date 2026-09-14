import SwiftUI

struct BookDetailView: View {
    @EnvironmentObject private var store: DeskStore
    @Environment(\.dismiss) private var dismiss

    let bookID: UUID

    @State private var editorOpen = false
    @State private var confirmDelete = false
    @State private var openJournal = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let book {
                    BannerHeader(
                        image: "BannerDesk",
                        kicker: "VOLUME",
                        title: book.title,
                        subtitle: book.author.isEmpty ? "Unknown hand" : book.author
                    )

                    IndexCard(
                        title: "Journal cards",
                        detail: "Passages kept for this volume.",
                        motif: "\(store.notes(for: bookID).count) cards"
                    )
                    IndexCard(
                        title: "Atlas nodes",
                        detail: "Ideas placed on the map.",
                        motif: "\(store.concepts(for: bookID).count) nodes"
                    )
                    Menu {
                        ForEach(ReadingStatus.allCases) { status in
                            Button(status.label) {
                                store.setBookStatus(bookID, status)
                            }
                        }
                    } label: {
                        IndexCard(
                            title: "Reading",
                            detail: book.status.label,
                            motif: quietLine(for: book)
                        )
                    }
                    .buttonStyle(.plain)

                    if isCurrent {
                        IndexCard(
                            title: "On the desk",
                            detail: "Journal and atlas write to this volume."
                        )
                    }

                    DeskButton(title: isCurrent ? "Open Journal" : "Use This Volume") {
                        store.selectBook(bookID)
                        if book.status == .shelf {
                            store.setBookStatus(bookID, .inHand)
                        }
                        openJournal = true
                    }

                    DeskButton(title: "Edit Book", emphasized: false) {
                        editorOpen = true
                    }

                    DeskButton(title: "Delete Book", emphasized: false) {
                        confirmDelete = true
                    }
                } else {
                    EmptyPrompt(
                        title: "Volume missing",
                        detail: "This book is no longer on the shelf."
                    )
                }
            }
            .padding(20)
        }
        .readingCanvas()
        .navigationTitle("Volume")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $openJournal) {
            NotesView()
        }
        .sheet(isPresented: $editorOpen) {
            BookEditorView(bookID: bookID)
        }
        .confirmationDialog("Delete this volume and its cards?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Book", role: .destructive) {
                store.deleteBook(bookID)
                dismiss()
            }
            Button("Keep", role: .cancel) {}
        }
    }

    private var book: BookItem? {
        store.books.first { item in item.id == bookID }
    }

    private var isCurrent: Bool {
        store.selectedBookID == bookID
    }

    private func quietLine(for book: BookItem) -> String {
        let days = Calendar.current.dateComponents([.day], from: book.touchedAt, to: Date()).day ?? 0
        if days <= 0 { return "Touched today" }
        if days == 1 { return "Touched yesterday" }
        return "Touched \(days) days ago"
    }
}
