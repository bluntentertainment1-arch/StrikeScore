import Foundation
import Combine

@MainActor
class MatchesViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var standings: [GroupStanding] = []
    @Published var featuredMatches: [FeaturedMatch] = []
    @Published var editorialItems: [EditorialItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var apiTimer: Timer?
    private var cmsTimer: Timer?
    private let competition = "WC"

    var liveMatches: [Match] {
        matches.filter { $0.isLive }
    }

    var finishedMatches: [Match] {
        matches.filter { $0.isFinished }
    }

    var upcomingMatches: [Match] {
        matches.filter { !$0.isLive && !$0.isFinished }
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let matchesTask = FootballAPIService.shared.fetchMatches(competition: competition)
            async let standingsTask = FootballAPIService.shared.fetchStandings(competition: competition)

            let (fetchedMatches, fetchedStandings) = try await (matchesTask, standingsTask)

            self.matches = fetchedMatches.sorted { m1, m2 in
                if m1.isLive && !m2.isLive { return true }
                if !m1.isLive && m2.isLive { return false }
                return m1.utcDate < m2.utcDate
            }

            self.standings = fetchedStandings.filter { $0.type == "TOTAL" }

            CacheService.shared.save(fetchedMatches, forKey: "cachedMatches")
            CacheService.shared.save(fetchedStandings, forKey: "cachedStandings")

        } catch FootballAPIService.APIError.rateLimited {
            errorMessage = "Rate limit reached. Wait a minute."
            loadFromCache()
        } catch {
            errorMessage = "Failed to load data. Using cached data."
            loadFromCache()
        }

        isLoading = false
    }

    func loadCMSData() async {
        do {
            async let featuredTask = ExcelCMSService.shared.fetchFeaturedMatches()
            async let editorialTask = ExcelCMSService.shared.fetchEditorial()

            let (featured, editorial) = try await (featuredTask, editorialTask)
            self.featuredMatches = featured
            self.editorialItems = editorial

            CacheService.shared.save(featured, forKey: "cachedFeatured")
            CacheService.shared.save(editorial, forKey: "cachedEditorial")

        } catch {
            loadCMSFromCache()
        }
    }

    private func loadFromCache() {
        if let cached: [Match] = CacheService.shared.load([Match].self, forKey: "cachedMatches") {
            self.matches = cached
        }
        if let cached: [GroupStanding] = CacheService.shared.load([GroupStanding].self, forKey: "cachedStandings") {
            self.standings = cached
        }
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
        apiTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.apiPollInterval, repeats: true) { _ in
            Task { await self.loadData() }
        }

        cmsTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.excelRefreshInterval, repeats: true) { _ in
            Task { await self.loadCMSData() }
        }
    }

    func stopAutoRefresh() {
        apiTimer?.invalidate()
        cmsTimer?.invalidate()
        apiTimer = nil
        cmsTimer = nil
    }
}
