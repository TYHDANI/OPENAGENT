import Foundation

/// Simple JSON file-based persistence for local data.
/// Uses the app's documents directory for storage.
final class PersistenceService {

    static let shared = PersistenceService()

    private let fileManager = FileManager.default
    private let documentsDirectory: URL

    init() {
        if let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            documentsDirectory = docs.appendingPathComponent("YieldSentinel", isDirectory: true)
        } else {
            documentsDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("YieldSentinel", isDirectory: true)
        }

        try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Generic Save/Load

    func save<T: Encodable>(_ value: T, key: String) {
        let url = documentsDirectory.appendingPathComponent("\(key).json")
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[PersistenceService] Failed to save \(key): \(error)")
        }
    }

    func load<T: Decodable>(key: String) -> T? {
        let url = documentsDirectory.appendingPathComponent("\(key).json")
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[PersistenceService] Failed to load \(key): \(error)")
            return nil
        }
    }

    func delete(key: String) {
        let url = documentsDirectory.appendingPathComponent("\(key).json")
        try? fileManager.removeItem(at: url)
    }

    func exists(key: String) -> Bool {
        let url = documentsDirectory.appendingPathComponent("\(key).json")
        return fileManager.fileExists(atPath: url.path)
    }

    // MARK: - Watchlist

    func loadWatchlist() -> [String] {
        load(key: "watchlist") ?? []
    }

    func saveWatchlist(_ ids: [String]) {
        save(ids, key: "watchlist")
    }

    // MARK: - Portfolio

    func loadPortfolio() -> [PortfolioPosition] {
        load(key: "portfolio") ?? []
    }

    func savePortfolio(_ positions: [PortfolioPosition]) {
        save(positions, key: "portfolio")
    }

    // MARK: - Previous Scores (for alert comparison)

    func loadPreviousScores() -> [String: Int] {
        load(key: "previousScores") ?? [:]
    }

    func savePreviousScores(_ scores: [String: Int]) {
        save(scores, key: "previousScores")
    }

    // MARK: - Cached Products

    func loadCachedProducts() -> [YieldProduct]? {
        load(key: "cachedProducts")
    }

    func saveCachedProducts(_ products: [YieldProduct]) {
        save(products, key: "cachedProducts")
    }
}
