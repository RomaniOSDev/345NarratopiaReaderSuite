import Foundation

struct Concept: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var note: String
    var themeId: UUID?
    var bookId: UUID
    var x: Double
    var y: Double

    init(
        id: UUID = UUID(),
        title: String,
        note: String,
        themeId: UUID? = nil,
        bookId: UUID,
        x: Double,
        y: Double
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.themeId = themeId
        self.bookId = bookId
        self.x = x
        self.y = y
    }
}
