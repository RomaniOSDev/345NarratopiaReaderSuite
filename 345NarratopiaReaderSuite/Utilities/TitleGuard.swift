import Foundation

enum TitleGuard {
    static func trimmed(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isPresent(_ raw: String) -> Bool {
        trimmed(raw).isEmpty == false
    }

    static func warning(for raw: String, attempted: Bool) -> String? {
        guard attempted, isPresent(raw) == false else { return nil }
        return "A title is required."
    }
}
