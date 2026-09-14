import SwiftUI

struct ThemeEditorView: View {
    @EnvironmentObject private var store: DeskStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var attempted = false
    @State private var pendingDelete: Theme?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    BannerHeader(
                        image: "BannerJournal",
                        kicker: "MOTIFS",
                        title: "Themes",
                        subtitle: "Label cards and atlas nodes without crowding the shelf."
                    )

                    if store.themes.isEmpty {
                        EmptyPrompt(
                            title: "No motifs yet",
                            detail: "Add a first theme such as Motif, Argument, or Character."
                        )
                    } else {
                        ForEach(store.themes) { theme in
                            IndexCard(title: theme.name, detail: "Used across journal and atlas.") {
                                Button {
                                    pendingDelete = theme
                                } label: {
                                    Text("Remove")
                                        .font(ScholarType.caption)
                                        .foregroundColor(Palette.accent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    InlineField(
                        caption: "NEW MOTIF",
                        placeholder: "Theme name",
                        text: $name,
                        warning: TitleGuard.warning(for: name, attempted: attempted)
                    )
                    DeskButton(title: "Add Theme") {
                        attempted = true
                        if store.upsertTheme(id: nil, name: name) {
                            name = ""
                            attempted = false
                        }
                    }
                }
                .padding(20)
            }
            .readingCanvas()
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Palette.accent)
                }
            }
            .confirmationDialog("Delete this theme?", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if $0 == false { pendingDelete = nil } }
            ), titleVisibility: .visible) {
                Button("Delete Theme", role: .destructive) {
                    if let pendingDelete {
                        store.deleteTheme(pendingDelete.id)
                    }
                    pendingDelete = nil
                }
                Button("Keep", role: .cancel) {
                    pendingDelete = nil
                }
            }
        }
    }
}
