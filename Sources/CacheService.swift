import Foundation

class CacheService {
    static let shared = CacheService()

    private let fileManager = FileManager.default
    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    func save<T: Codable>(_ object: T, forKey key: String) {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        if let data = try? JSONEncoder().encode(object) {
            try? data.write(to: url)
        }
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func clearCache(forKey key: String) {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        try? fileManager.removeItem(at: url)
    }
}
