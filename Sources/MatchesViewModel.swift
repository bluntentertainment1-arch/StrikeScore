import Foundation
import Combine

@MainActor
class MatchesViewModel: ObservableObject {
    @Published var featuredMatches: [FeaturedMatch] = []
    @Published var editorialItems: [EditorialItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cmsTimer: Timer?

    // Global arrays filtered automatically for Live layouts safely handling both tags
    var liveMatches: [FeaturedMatch] {
        featuredMatches.filter { $0.isLive || $0.status.uppercased() == "LIVE" || $0.status.uppercased() == "IN_PLAY" }
    }

    func loadCMSData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let featuredTask = ExcelCMSService.shared.fetchFeaturedMatches()
            async let editorialTask = ExcelCMSService.shared.fetchEditorial()

            let (featured, editorial) = try await (featuredTask, editorialTask)
            
            // Organized scheduled entries sorted strictly according to scheduling dates/times
            self.featuredMatches = featured.sorted { (m1: FeaturedMatch, m2: FeaturedMatch) -> Bool in
                if m1.matchDate != m2.matchDate {
                    return m1.matchDate < m2.matchDate
                }
                return m1.matchTime < m2.matchTime
            }
            self.editorialItems = editorial

            CacheService.shared.save(self.featuredMatches, forKey: "cachedFeatured")
            CacheService.shared.save(editorial, forKey: "cachedEditorial")

            AppLogger.shared.log("CMS loaded: \(featured.count) featured sorted, \(editorial.count) editorial")
            
            // ✅ INTEGRATED UPDATE: Safely schedule daily notification digests based on fresh content
            NotificationManager.shared.scheduleDailyEditorialDigests(headlines: ["Discover Todays Top Football News & Updates"])

        } catch {
            AppLogger.shared.error("CMS load error: \(error.localizedDescription)")
            loadCMSFromCache()
        }

        isLoading = false
    }

    private func loadCMSFromCache() {
        if let cached: [FeaturedMatch] = CacheService.shared.load([FeaturedMatch].self, forKey: "cachedFeatured") {
            self.featuredMatches = cached.sorted { 
                if $0.matchDate != $1.matchDate { return $0.matchDate < $1.matchDate }
                return $0.matchTime < $1.matchTime
            }
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
