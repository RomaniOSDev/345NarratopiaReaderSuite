import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: DeskStore
    @State private var editorOpen = false
    @State private var statusFilter: ReadingStatus?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BannerHeader(
                    image: "BannerDesk",
                    kicker: "SHELF",
                    title: "The Library",
                    subtitle: "Add a volume, then keep notes and map its ideas."
                )

                if store.books.isEmpty == false {
                    statusFilterRow
                }

                if store.books.isEmpty {
                    EmptyPrompt(
                        title: "The shelf is bare",
                        detail: "Add a first volume to begin a journal and an atlas."
                    )
                } else if visibleBooks.isEmpty {
                    EmptyPrompt(
                        title: "Nothing in this state",
                        detail: "Clear the reading filter to see the whole shelf."
                    )
                } else {
                    ForEach(visibleBooks) { book in
                        NavigationLink {
                            BookDetailView(bookID: book.id)
                        } label: {
                            IndexCard(
                                title: book.title,
                                detail: book.author.isEmpty ? "Unknown hand" : book.author,
                                motif: selectedLabel(for: book),
                                emphasized: store.selectedBookID == book.id
                            ) {
                                Text("Open")
                                    .font(ScholarType.caption)
                                    .foregroundColor(Palette.accent)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                DeskButton(title: "Add Book") {
                    editorOpen = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .readingCanvas()
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editorOpen) {
            BookEditorView(bookID: nil)
        }
    }

    private var visibleBooks: [BookItem] {
        guard let statusFilter else { return store.books }
        return store.books.filter { book in book.status == statusFilter }
    }

    private func selectedLabel(for book: BookItem) -> String {
        let status = book.status.label
        if store.selectedBookID == book.id {
            return "Current · \(status)"
        }
        return "\(status) · \(store.notes(for: book.id).count) cards"
    }

    private var statusFilterRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("READING FILTER")
                .font(ScholarType.caption)
                .tracking(1.4)
                .foregroundColor(Palette.accent)
            Menu {
                Button("All volumes") {
                    statusFilter = nil
                }
                ForEach(ReadingStatus.allCases) { status in
                    Button(status.label) {
                        statusFilter = status
                    }
                }
            } label: {
                HStack {
                    Text(statusFilter?.label ?? "All volumes")
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
}
