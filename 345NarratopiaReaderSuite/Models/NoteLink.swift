import Foundation

struct NoteLink: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var fromID: UUID
    var toID: UUID
    var label: String

    init(
        id: UUID = UUID(),
        fromID: UUID,
        toID: UUID,
        label: String
    ) {
        self.id = id
        self.fromID = fromID
        self.toID = toID
        self.label = label
    }
}
