import SwiftUI

struct HomeHubView: View {
    @EnvironmentObject private var store: DeskStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("READING DESK")
                        .font(ScholarType.masthead)
                        .tracking(ScholarType.mastheadTracking)
                        .foregroundColor(Palette.primary)
                    Text("Keep volumes, card your passages, and thread ideas across a quiet atlas.")
                        .font(ScholarType.body)
                        .foregroundColor(Palette.primary.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)

                if let quote = store.quoteOfTheDay() {
                    NavigationLink {
                        NotesView()
                    } label: {
                        IndexCard(
                            title: "Today's passage",
                            detail: quote.body.isEmpty ? quote.title : quote.body,
                            motif: quoteMotif(for: quote)
                        ) {
                            Text("Open")
                                .font(ScholarType.caption)
                                .foregroundColor(Palette.accent)
                        }
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        store.selectBook(quote.bookId)
                        store.rememberNote(quote.id)
                    })
                }

                if let draft = store.noteDraft {
                    NavigationLink {
                        NotesView()
                    } label: {
                        IndexCard(
                            title: "A draft waits",
                            detail: draft.title.isEmpty ? "An unfinished card is still on the blotter." : draft.title,
                            motif: store.book(id: draft.bookId)?.title ?? "Continue"
                        ) {
                            Text("Open")
                                .font(ScholarType.caption)
                                .foregroundColor(Palette.accent)
                        }
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        store.selectBook(draft.bookId)
                    })
                }

                DeskSessionPanel()

                if quietBooks.isEmpty == false {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("QUIET SPINES")
                            .font(ScholarType.caption)
                            .tracking(1.4)
                            .foregroundColor(Palette.accent)
                        Text("Volumes untouched for fourteen days.")
                            .font(ScholarType.body)
                            .foregroundColor(Palette.primary.opacity(0.72))
                        ForEach(quietBooks) { book in
                            NavigationLink {
                                BookDetailView(bookID: book.id)
                            } label: {
                                IndexCard(
                                    title: book.title,
                                    detail: book.author.isEmpty ? "Unknown hand" : book.author,
                                    motif: book.status.label
                                ) {
                                    Text("Open")
                                        .font(ScholarType.caption)
                                        .foregroundColor(Palette.accent)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let resume = resumeCard {
                    NavigationLink {
                        NotesView()
                    } label: {
                        IndexCard(
                            title: "Resume the last card",
                            detail: resume.title,
                            motif: store.theme(id: resume.themeId)?.name ?? "Continue"
                        ) {
                            Text("Open")
                                .font(ScholarType.caption)
                                .foregroundColor(Palette.accent)
                        }
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    LibraryView()
                } label: {
                    ChapterPanel(
                        chapter: "CHAPTER I",
                        title: "The Library",
                        blurb: "Volumes you are keeping. Open a spine, then write.",
                        metric: volumeMetric,
                        banner: "BannerDesk"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    NotesView()
                } label: {
                    ChapterPanel(
                        chapter: "CHAPTER II",
                        title: "The Journal",
                        blurb: "Index cards for passages, questions, and asides.",
                        metric: journalMetric,
                        banner: "BannerJournal"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ConceptMapView()
                } label: {
                    ChapterPanel(
                        chapter: "CHAPTER III",
                        title: "The Atlas",
                        blurb: "Gold nodes on a navy canvas. Drag, then thread links.",
                        metric: atlasMetric,
                        banner: "BannerMap"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    LedgerView()
                } label: {
                    ChapterPanel(
                        chapter: "CHAPTER IV",
                        title: "The Record",
                        blurb: "Charts of cards, motifs, and the quiet streak of writing.",
                        metric: ledgerMetric,
                        banner: "BannerDesk"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .readingCanvas()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("STUDY")
                    .font(ScholarType.chapter)
                    .tracking(ScholarType.chapterTracking)
                    .foregroundColor(Palette.accent)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Text("Desk")
                        .font(ScholarType.caption)
                        .foregroundColor(Palette.accent)
                }
            }
        }
    }

    private var volumeMetric: String {
        let count = store.books.count
        if count == 0 { return "Empty shelf" }
        if count == 1 { return "1 volume" }
        return "\(count) volumes"
    }

    private var journalMetric: String {
        let count = store.notes.count
        if count == 0 { return "No cards yet" }
        if count == 1 { return "1 card" }
        return "\(count) cards"
    }

    private var atlasMetric: String {
        let count = store.concepts.count
        if count == 0 { return "No nodes yet" }
        if count == 1 { return "1 node" }
        return "\(count) nodes"
    }

    private var ledgerMetric: String {
        let count = store.notes.count + store.concepts.count
        if count == 0 { return "No marks yet" }
        if count == 1 { return "1 mark" }
        return "\(count) marks"
    }

    private var resumeCard: ReadingNote? {
        guard let lastViewedNoteID = store.lastViewedNoteID else { return nil }
        return store.notes.first { note in note.id == lastViewedNoteID }
    }

    private var quietBooks: [BookItem] {
        store.quietBooks()
    }

    private func quoteMotif(for quote: ReadingNote) -> String {
        let volume = store.book(id: quote.bookId)?.title ?? "Volume"
        let place = TitleGuard.trimmed(quote.locator)
        if place.isEmpty { return volume }
        return "\(volume) · \(place)"
    }
}

private struct DeskSessionPanel: View {
    @EnvironmentObject private var store: DeskStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            VStack(alignment: .leading, spacing: 10) {
                Text("A SITTING")
                    .font(ScholarType.caption)
                    .tracking(1.4)
                    .foregroundColor(Palette.accent)
                Text(store.sittingLabel(at: timeline.date))
                    .font(ScholarType.title)
                    .foregroundColor(Palette.primary)
                Text("Quiet time at the desk today. It clears at midnight.")
                    .font(ScholarType.body)
                    .foregroundColor(Palette.primary.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
                if store.sessionAnchor == nil {
                    DeskButton(title: "Sit") {
                        store.beginSitting()
                    }
                } else {
                    DeskButton(title: "Pause", emphasized: false) {
                        store.pauseSitting()
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface)
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Palette.accent.opacity(0.28), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
