import SwiftUI

struct BookEditorView: View {
    @EnvironmentObject private var store: DeskStore
    @Environment(\.dismiss) private var dismiss

    let bookID: UUID?

    @State private var title: String = ""
    @State private var author: String = ""
    @State private var status: ReadingStatus = .shelf
    @State private var attempted = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    BannerHeader(
                        image: "BannerDesk",
                        kicker: bookID == nil ? "NEW VOLUME" : "REVISE",
                        title: bookID == nil ? "Add Book" : "Edit Book",
                        subtitle: "A title is required. The author may remain blank."
                    )
                    InlineField(
                        caption: "TITLE",
                        placeholder: "Volume title",
                        text: $title,
                        warning: TitleGuard.warning(for: title, attempted: attempted)
                    )
                    InlineField(
                        caption: "AUTHOR",
                        placeholder: "Optional hand",
                        text: $author
                    )
                    StatusMenu(status: $status)
                    DeskButton(title: "Save Volume") {
                        attempted = true
                        if store.upsertBook(id: bookID, title: title, author: author, status: status) {
                            dismiss()
                        }
                    }
                }
                .padding(20)
            }
            .readingCanvas()
            .navigationTitle(bookID == nil ? "Add Book" : "Edit Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Palette.accent)
                }
            }
            .onAppear {
                if let bookID, let book = store.books.first(where: { item in item.id == bookID }) {
                    title = book.title
                    author = book.author
                    status = book.status
                }
            }
        }
    }
}
