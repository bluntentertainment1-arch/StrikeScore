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
    private let league = 1      // World Cup
    private let season = 2022   // Use 2022 for World Cup data

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
            async let matchesTask = FootballAPIService.shared.fetchMatches(league: league, season: season)
            async let standingsTask = FootballAPIService.shared.fetchStandings(league: league, season: season)

            let (fetchedMatches, fetchedStandings) = try await (matchesTask, standingsTask)

            self.matches = fetchedMatches.sorted { m1, m2 in
                if m1.isLive && !m2.isLive { return true }
                if !m1.isLive && m2.isLive { return false }
                return m1.utcDate < m2.utcDate
            }

            self.standings = fetchedStandings

            CacheService.shared.save(fetchedMatches, forKey: "cachedMatches")
            CacheService.shared.save(fetchedStandings, forKey: "cachedStandings")

            AppLogger.shared.log("Data loaded: \(self.matches.count) matches, \(self.standings.count) standings")

        } catch FootballAPIService.APIError.rateLimited {
            errorMessage = "Rate limit reached. Wait a minute."
            loadFromCache()
        } catch FootballAPIService.APIError.httpError(let code, let message) {
            errorMessage = "API Error \(code): \(message)"
            AppLogger.shared.error("API HTTP Error: \(code) - \(message)")
            loadFromCache()
        } catch FootballAPIService.APIError.networkError(let error) {
            errorMessage = "Network error: \(error.localizedDescription)"
            AppLogger.shared.error("Network error: \(error)")
            loadFromCache()
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            AppLogger.shared.error("General error: \(error)")
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

            AppLogger.shared.log("CMS loaded: \(featured.count) featured, \(editorial.count) editorial")

        } catch {
            AppLogger.shared.error("CMS load error: \(error.localizedDescription)")
            loadCMSFromCache()
        }
    }

    private func loadFromCache() {
        if let cached: [Match] = CacheService.shared.load([Match].self, forKey: "cachedMatches") {
            self.matches = cached
            AppLogger.shared.log("Loaded \(cached.count) matches from cache")
        }
        if let cached: [GroupStanding] = CacheService.shared.load([GroupStanding].self, forKey: "cachedStandings") {
            self.standings = cached
            AppLogger.shared.log("Loaded \(cached.count) standings from cache")
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
