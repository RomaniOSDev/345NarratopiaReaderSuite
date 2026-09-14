import Foundation

struct ReadingNote: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var bookId: UUID
    var title: String
    var body: String
    var themeId: UUID?
    var locator: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        bookId: UUID,
        title: String,
        body: String,
        themeId: UUID? = nil,
        locator: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.title = title
        self.body = body
        self.themeId = themeId
        self.locator = locator
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        bookId = try container.decode(UUID.self, forKey: .bookId)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        themeId = try container.decodeIfPresent(UUID.self, forKey: .themeId)
        locator = try container.decodeIfPresent(String.self, forKey: .locator) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

struct NoteDraft: Codable, Equatable {
    var bookId: UUID
    var noteID: UUID?
    var title: String
    var body: String
    var themeId: UUID?
    var locator: String
}
