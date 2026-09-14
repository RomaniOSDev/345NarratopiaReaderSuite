import SwiftUI

struct ConceptMapView: View {
    @EnvironmentObject private var store: DeskStore

    @State private var conceptEditorOpen = false
    @State private var linkEditorOpen = false
    @State private var editingConceptID: UUID?
    @State private var selectedIDs: [UUID] = []
    @State private var pendingDeleteConcept: Concept?
    @State private var pendingDeleteLink: NoteLink?
    @State private var linkDraftFrom: UUID?
    @State private var linkDraftTo: UUID?
    @State private var canvasSize: CGSize = CGSize(width: 320, height: 420)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BannerHeader(
                    image: "BannerMap",
                    kicker: "ATLAS",
                    title: "Concept Map",
                    subtitle: currentVolumeLine
                )

                bookPicker

                if store.selectedBookID == nil {
                    EmptyPrompt(
                        title: "Choose a volume",
                        detail: "The atlas waits until a book is selected."
                    )
                } else if nodes.isEmpty {
                    EmptyPrompt(
                        title: "The canvas is empty",
                        detail: "Place a first idea, then thread gold lines between nodes."
                    )
                } else {
                    atlasBoard
                    if let caption = selectionCaption {
                        Text(caption)
                            .font(ScholarType.caption)
                            .foregroundColor(Palette.accent)
                    }
                }

                if store.selectedBookID != nil {
                    DeskButton(title: "Add Concept") {
                        editingConceptID = nil
                        conceptEditorOpen = true
                    }
                    DeskButton(title: "Add Link", emphasized: false) {
                        prepareLinkDraft()
                        linkEditorOpen = true
                    }
                    DeskButton(title: "Edit Links", emphasized: false) {
                        linkDraftFrom = nil
                        linkDraftTo = nil
                        linkEditorOpen = true
                    }
                    if let focused = focusedConcept {
                        DeskButton(title: "Edit Concept", emphasized: false) {
                            editingConceptID = focused.id
                            conceptEditorOpen = true
                        }
                        DeskButton(
                            title: store.pinnedConceptID == focused.id ? "Pinned to Atlas" : "Pin This Node",
                            emphasized: false
                        ) {
                            if store.pinnedConceptID == focused.id {
                                store.pinConcept(nil)
                            } else {
                                store.pinConcept(focused.id)
                            }
                        }
                        DeskButton(title: "Delete Concept", emphasized: false) {
                            pendingDeleteConcept = focused
                        }
                    }
                    if let pinned = pinnedInVolume {
                        DeskButton(title: "Return to Pin", emphasized: false) {
                            focusNode(pinned.id)
                        }
                    }
                    if let last = lastNodeInVolume, store.pinnedConceptID != last.id {
                        DeskButton(title: "Return to Last Node", emphasized: false) {
                            focusNode(last.id)
                        }
                    }
                }

                if bookLinks.isEmpty == false {
                    Text("THREADS")
                        .font(ScholarType.caption)
                        .tracking(1.4)
                        .foregroundColor(Palette.accent)
                    ForEach(bookLinks) { link in
                        IndexCard(
                            title: linkTitle(link),
                            detail: link.label.isEmpty ? "Unlabeled thread" : link.label
                        ) {
                            HStack(spacing: 10) {
                                Button("Edit") {
                                    linkDraftFrom = link.fromID
                                    linkDraftTo = link.toID
                                    linkEditorOpen = true
                                }
                                .font(ScholarType.caption)
                                .foregroundColor(Palette.accent)
                                Button("Delete") {
                                    pendingDeleteLink = link
                                }
                                .font(ScholarType.caption)
                                .foregroundColor(Palette.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .readingCanvas()
        .navigationTitle("Atlas")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $conceptEditorOpen) {
            ConceptEditorView(conceptID: editingConceptID, fallbackPoint: store.nextConceptPoint(for: store.selectedBookID ?? UUID()))
        }
        .sheet(isPresented: $linkEditorOpen) {
            LinkEditorView(preferredFrom: linkDraftFrom, preferredTo: linkDraftTo)
        }
        .confirmationDialog("Delete this concept and its threads?", isPresented: Binding(
            get: { pendingDeleteConcept != nil },
            set: { if $0 == false { pendingDeleteConcept = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Concept", role: .destructive) {
                if let pendingDeleteConcept {
                    store.deleteConcept(pendingDeleteConcept.id)
                    selectedIDs.removeAll { id in id == pendingDeleteConcept.id }
                }
                pendingDeleteConcept = nil
            }
            Button("Keep", role: .cancel) {
                pendingDeleteConcept = nil
            }
        }
        .confirmationDialog("Delete this link?", isPresented: Binding(
            get: { pendingDeleteLink != nil },
            set: { if $0 == false { pendingDeleteLink = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Link", role: .destructive) {
                if let pendingDeleteLink {
                    store.deleteLink(pendingDeleteLink.id)
                }
                pendingDeleteLink = nil
            }
            Button("Keep", role: .cancel) {
                pendingDeleteLink = nil
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

    private var focusedConcept: Concept? {
        if let last = selectedIDs.last, let match = nodes.first(where: { node in node.id == last }) {
            return match
        }
        if let remembered = store.lastVisitedNodeID {
            return nodes.first { node in node.id == remembered }
        }
        return nil
    }

    private var pinnedInVolume: Concept? {
        guard let pinnedConceptID = store.pinnedConceptID else { return nil }
        return nodes.first { node in node.id == pinnedConceptID }
    }

    private var lastNodeInVolume: Concept? {
        guard let lastVisitedNodeID = store.lastVisitedNodeID else { return nil }
        return nodes.first { node in node.id == lastVisitedNodeID }
    }

    private func focusNode(_ id: UUID) {
        store.rememberNode(id)
        selectedIDs = [id]
    }

    private var selectionCaption: String? {
        if selectedIDs.count == 2 {
            return "Two nodes marked. Use Add Link to thread them."
        }
        if let focused = focusedConcept {
            return "Selected: \(focused.title)"
        }
        return nil
    }

    private var currentVolumeLine: String {
        if let book = store.selectedBook {
            return "Gold nodes for \(book.title). Drag to arrange; buttons manage links."
        }
        return "Select a volume to chart its ideas."
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
                        selectedIDs = []
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

    private var atlasBoard: some View {
        GeometryReader { geo in
            ZStack {
                Palette.background
                Path { path in
                    for link in bookLinks {
                        guard
                            let from = nodes.first(where: { node in node.id == link.fromID }),
                            let to = nodes.first(where: { node in node.id == link.toID })
                        else { continue }
                        path.move(to: CGPoint(x: from.x, y: from.y))
                        path.addLine(to: CGPoint(x: to.x, y: to.y))
                    }
                }
                .stroke(Palette.accent, lineWidth: 1.6)

                ForEach(nodes) { concept in
                    ConceptNodeView(
                        title: concept.title,
                        selected: selectedIDs.contains(concept.id) || store.lastVisitedNodeID == concept.id,
                        pinned: store.pinnedConceptID == concept.id
                    )
                    .position(x: concept.x, y: concept.y)
                    .gesture(nodeDrag(concept))
                }
            }
            .coordinateSpace(name: "atlas")
            .frame(width: geo.size.width, height: 440)
            .clipped()
            .onAppear {
                canvasSize = CGSize(width: geo.size.width, height: 440)
            }
            .onChange(of: geo.size) { size in
                canvasSize = CGSize(width: size.width, height: 440)
            }
        }
        .frame(height: 440)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Palette.accent.opacity(0.45), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func nodeDrag(_ concept: Concept) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .named("atlas"))
            .onChanged { value in
                let x = clamped(value.location.x, lower: 56, upper: canvasSize.width - 56)
                let y = clamped(value.location.y, lower: 36, upper: canvasSize.height - 36)
                store.moveConcept(id: concept.id, x: x, y: y, persist: false)
            }
            .onEnded { value in
                let x = clamped(value.location.x, lower: 56, upper: canvasSize.width - 56)
                let y = clamped(value.location.y, lower: 36, upper: canvasSize.height - 36)
                store.moveConcept(id: concept.id, x: x, y: y, persist: true)
                store.rememberNode(concept.id)
                if abs(value.translation.width) < 4 && abs(value.translation.height) < 4 {
                    toggleSelection(concept.id)
                }
            }
    }

    private func toggleSelection(_ id: UUID) {
        store.rememberNode(id)
        if let index = selectedIDs.firstIndex(of: id) {
            selectedIDs.remove(at: index)
            return
        }
        selectedIDs.append(id)
        if selectedIDs.count > 2 {
            selectedIDs.removeFirst(selectedIDs.count - 2)
        }
    }

    private func prepareLinkDraft() {
        if selectedIDs.count == 2 {
            linkDraftFrom = selectedIDs[0]
            linkDraftTo = selectedIDs[1]
        } else if let focused = focusedConcept {
            linkDraftFrom = focused.id
            linkDraftTo = nodes.first { node in node.id != focused.id }?.id
        } else {
            linkDraftFrom = nodes.first?.id
            linkDraftTo = nodes.dropFirst().first?.id
        }
    }

    private func linkTitle(_ link: NoteLink) -> String {
        let from = nodes.first { node in node.id == link.fromID }?.title ?? "Idea"
        let to = nodes.first { node in node.id == link.toID }?.title ?? "Idea"
        return "\(from) → \(to)"
    }

    private func clamped(_ value: Double, lower: Double, upper: Double) -> Double {
        min(max(value, lower), max(lower, upper))
    }
}

private struct ConceptNodeView: View {
    let title: String
    let selected: Bool
    let pinned: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if pinned {
                    Circle()
                        .stroke(Palette.accent, lineWidth: 1.4)
                        .frame(width: 30, height: 30)
                }
                Circle()
                    .fill(Palette.accent)
                    .frame(width: selected ? 22 : 16, height: selected ? 22 : 16)
                    .overlay {
                        Circle()
                            .stroke(Palette.primary.opacity(selected ? 0.9 : 0.25), lineWidth: selected ? 2 : 1)
                    }
            }
            Text(title)
                .font(ScholarType.node)
                .foregroundColor(Palette.accent)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 108)
        }
    }
}
