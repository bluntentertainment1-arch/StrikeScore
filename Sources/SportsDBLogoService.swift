import Foundation

class SportsDBLogoService {
    static let shared = SportsDBLogoService()
    private init() {}
    
    // In-memory cache to prevent duplicate network hits for the same club
    private var logoCache: [String: URL] = [:]
    
    func fetchLogoURL(for teamName: String) async -> URL? {
        let cleanName = teamName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return nil }
        
        // Return instantly if already looked up during this session
        if let cachedURL = logoCache[cleanName] {
            return cachedURL
        }
        
        // Safely encode spaces and characters for URL compatibility
        guard let encodedName = cleanName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.thesportsdb.com/api/v1/json/123/searchteams.php?t=\(encodedName)") else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(SportsDBResponse.self, from: data)
            
            if let badgeString = response.teams?.first?.strTeamBadge, let logoURL = URL(string: badgeString) {
                self.logoCache[cleanName] = logoURL
                return logoURL
            }
        } catch {
            print("SportsDB Lookup Error for '\(cleanName)': \(error.localizedDescription)")
        }
        
        return nil
    }
}

// MARK: - API Response Decodable Models
struct SportsDBResponse: Codable {
    let teams: [SportsDBTeam]?
}

struct SportsDBTeam: Codable {
    let strTeamBadge: String?
}
