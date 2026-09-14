import Foundation

enum DefaultsBox {
    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func loadUUID(key: String) -> UUID? {
        guard let raw = UserDefaults.standard.string(forKey: key) else { return nil }
        return UUID(uuidString: raw)
    }

    static func saveUUID(_ value: UUID?, key: String) {
        if let value {
            UserDefaults.standard.set(value.uuidString, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    static func remove(_ key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
