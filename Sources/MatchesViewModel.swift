import Foundation
import Combine

@MainActor
class MatchesViewModel: ObservableObject {
    @Published var featuredMatches: [FeaturedMatch] = []
    @Published var editorialItems: [EditorialItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cmsTimer: Timer?

    // Using Excel data only - API is unreliable for this demo
    func loadCMSData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let featuredTask = ExcelCMSService.shared.fetchFeaturedMatches()
            async let editorialTask = ExcelCMSService.shared.fetchEditorial()

            let (featured, editorial) = try await (featuredTask, editorialTask)
            self.featuredMatches = featured
            self.editorialItems = editorial

            CacheService.shared.save(featured, forKey: "cachedFeatured")
            CacheService.shared.save(editorial, forKey: "cachedEditorial")

            AppLogger.shared.log("CMS loaded: \(featured.count) featured, \(editorial.count) editorial")

        } catch {
            AppLogger.shared.error("CMS load error: \(error.localizedDescription)")
            loadCMSFromCache()
        }

        isLoading = false
    }

    private func loadCMSFromCache() {
        if let cached: [FeaturedMatch] = CacheService.shared.load([FeaturedMatch].self, forKey: "cachedFeatured") {
            self.featuredMatches = cached
        }
        if let cached: [EditorialItem] = CacheService.shared.load([EditorialItem].self, forKey: "cachedEditorial") {
            self.editorialItems = cached
        }
    }

    func startAutoRefresh() {
        cmsTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.excelRefreshInterval, repeats: true) { _ in
            Task { await self.loadCMSData() }
        }
    }

    func stopAutoRefresh() {
        cmsTimer?.invalidate()
        cmsTimer = nil
    }
}
