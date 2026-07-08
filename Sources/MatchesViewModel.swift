import Foundation
import Combine

@MainActor
class MatchesViewModel: ObservableObject {
    @Published var featuredMatches: [FeaturedMatch] = []
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
            let featured = try await ExcelCMSService.shared.fetchFeaturedMatches()

            // Organized scheduled entries sorted strictly according to scheduling dates/times
            self.featuredMatches = featured.sorted { (m1: FeaturedMatch, m2: FeaturedMatch) -> Bool in
                if m1.matchDate != m2.matchDate {
                    return m1.matchDate < m2.matchDate
                }
                return m1.matchTime < m2.matchTime
            }

            CacheService.shared.save(self.featuredMatches, forKey: "cachedFeatured")

            AppLogger.shared.log("CMS loaded: \(featured.count) featured sorted")

            NotificationManager.shared.scheduleDailyEditorialDigests(headlines: ["Discover Today's Top Football Matches & Fixtures"])
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
