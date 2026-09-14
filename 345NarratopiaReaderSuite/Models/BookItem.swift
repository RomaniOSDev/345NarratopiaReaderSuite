import Foundation

enum ReadingStatus: String, Codable, CaseIterable, Identifiable {
    case shelf
    case inHand
    case finished

    var id: String { rawValue }

    var label: String {
        switch self {
        case .shelf: return "On the shelf"
        case .inHand: return "In hand"
        case .finished: return "Finished"
        }
    }
}

struct BookItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var author: String
    var createdAt: Date
    var status: ReadingStatus
    var touchedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        createdAt: Date = Date(),
        status: ReadingStatus = .shelf,
        touchedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.createdAt = createdAt
        self.status = status
        self.touchedAt = touchedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decode(String.self, forKey: .author)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        status = try container.decodeIfPresent(ReadingStatus.self, forKey: .status) ?? .shelf
        touchedAt = try container.decodeIfPresent(Date.self, forKey: .touchedAt) ?? createdAt
    }
}
