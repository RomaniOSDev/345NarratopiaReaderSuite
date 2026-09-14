import SwiftUI

struct LinkEditorView: View {
    @EnvironmentObject private var store: DeskStore
    @Environment(\.dismiss) private var dismiss

    let preferredFrom: UUID?
    let preferredTo: UUID?

    @State private var fromID: UUID?
    @State private var toID: UUID?
    @State private var label: String = ""
    @State private var editingLinkID: UUID?
    @State private var warning: String?
    @State private var pendingDelete: NoteLink?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    BannerHeader(
                        image: "BannerMap",
                        kicker: "THREADS",
                        title: editingLinkID == nil ? "Add Link" : "Edit Link",
                        subtitle: "Join two concepts with a labeled gold thread."
                    )

                    nodeMenu(caption: "FROM", selection: $fromID)
                    nodeMenu(caption: "TO", selection: $toID)
                    InlineField(
                        caption: "LABEL",
                        placeholder: "Optional thread name",
                        text: $label
                    )

                    if let warning {
                        Text(warning)
                            .font(ScholarType.caption)
                            .foregroundColor(Palette.accent)
                    }

                    DeskButton(title: editingLinkID == nil ? "Save Link" : "Update Link") {
                        saveLink()
                    }

                    if bookLinks.isEmpty == false {
                        Text("EXISTING")
                            .font(ScholarType.caption)
                            .tracking(1.4)
                            .foregroundColor(Palette.accent)
                        ForEach(bookLinks) { link in
                            IndexCard(
                                title: title(for: link),
                                detail: link.label.isEmpty ? "Unlabeled thread" : link.label,
                                emphasized: editingLinkID == link.id
                            ) {
                                HStack(spacing: 10) {
                                    Button("Edit") {
                                        load(link)
                                    }
                                    .font(ScholarType.caption)
                                    .foregroundColor(Palette.accent)
                                    Button("Delete") {
                                        pendingDelete = link
                                    }
                                    .font(ScholarType.caption)
                                    .foregroundColor(Palette.accent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .readingCanvas()
            .navigationTitle("Links")
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
            .confirmationDialog("Delete this link?", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if $0 == false { pendingDelete = nil } }
            ), titleVisibility: .visible) {
                Button("Delete Link", role: .destructive) {
                    if let pendingDelete {
                        store.deleteLink(pendingDelete.id)
                        if editingLinkID == pendingDelete.id {
                            editingLinkID = nil
                            label = ""
                        }
                    }
                    pendingDelete = nil
                }
                Button("Keep", role: .cancel) {
                    pendingDelete = nil
                }
            }
        }
    }

    private var nodes: [Concept] {
        guard let bookID = store.selectedBookID else { return [] }
        return store.concepts(for: bookID)
    }

    private var bookLinks: [NoteLink] {
        guard let bookID = store.selectedBookID else { return [] }
        return store.links(for: bookID)
    }

    private func nodeMenu(caption: String, selection: Binding<UUID?>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caption)
                .font(ScholarType.caption)
                .tracking(1.4)
                .foregroundColor(Palette.accent)
            Menu {
                ForEach(nodes) { node in
                    Button(node.title) {
                        selection.wrappedValue = node.id
                    }
                }
            } label: {
                HStack {
                    Text(name(for: selection.wrappedValue))
                        .font(ScholarType.body)
                        .foregroundColor(Palette.primary)
                    Spacer()
                    Text("Choose")
                        .font(ScholarType.caption)
                        .foregroundColor(Palette.accent)
                }
                .padding(12)
                .background(Palette.background.opacity(0.55))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Palette.accent.opacity(0.24), lineWidth: 1)
                }
            }
        }
    }

    private func hydrate() {
        if let preferredFrom, nodes.contains(where: { node in node.id == preferredFrom }) {
            fromID = preferredFrom
        } else {
            fromID = nodes.first?.id
        }
        if let preferredTo, nodes.contains(where: { node in node.id == preferredTo }) {
            toID = preferredTo
        } else {
            toID = nodes.first { node in node.id != fromID }?.id
        }
        if let fromID, let toID,
           let existing = bookLinks.first(where: { link in
               (link.fromID == fromID && link.toID == toID) ||
               (link.fromID == toID && link.toID == fromID)
           }) {
            load(existing)
        }
    }

    private func load(_ link: NoteLink) {
        editingLinkID = link.id
        fromID = link.fromID
        toID = link.toID
        label = link.label
        warning = nil
    }

    private func saveLink() {
        guard let fromID, let toID else {
            warning = "Choose two concepts to thread."
            return
        }
        if fromID == toID {
            warning = "A link needs two different nodes."
            return
        }
        if store.upsertLink(id: editingLinkID, fromID: fromID, toID: toID, label: label) {
            dismiss()
        } else {
            warning = "That thread already exists."
        }
    }

    private func name(for id: UUID?) -> String {
        guard let id else { return "Choose a node" }
        return nodes.first { node in node.id == id }?.title ?? "Choose a node"
    }

    private func title(for link: NoteLink) -> String {
        "\(name(for: link.fromID)) → \(name(for: link.toID))"
    }
}
