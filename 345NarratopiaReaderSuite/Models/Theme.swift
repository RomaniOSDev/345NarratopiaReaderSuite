import Foundation

struct Theme: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
