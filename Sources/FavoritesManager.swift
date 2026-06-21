import Foundation

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    @Published var favoriteMatchIDs: Set<String> = [] {
        didSet {
            saveFavorites()
        }
    }

    private let favoritesKey = "favorited_match_ids"

    init() {
        loadFavorites()
    }

    func isFavorited(_ matchID: String) -> Bool {
        favoriteMatchIDs.contains(matchID)
    }

    func toggleFavorite(_ matchID: String) {
        if favoriteMatchIDs.contains(matchID) {
            favoriteMatchIDs.remove(matchID)
            AppLogger.shared.log("Removed favorite: \(matchID)")
        } else {
            favoriteMatchIDs.insert(matchID)
            AppLogger.shared.log("Added favorite: \(matchID)")
        }
    }

    private func saveFavorites() {
        let array = Array(favoriteMatchIDs)
        UserDefaults.standard.set(array, forKey: favoritesKey)
    }

    private func loadFavorites() {
        if let array = UserDefaults.standard.stringArray(forKey: favoritesKey) {
            favoriteMatchIDs = Set(array)
        }
    }
}
