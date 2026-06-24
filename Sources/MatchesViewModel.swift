import Foundation
import SwiftUI

@MainActor
class MatchesViewModel: ObservableObject {
    @Published var featuredMatches: [FeaturedMatch] = []
    @Published var editorialItems: [EditorialItem] = []
    @Published var isLoading: Bool = false
    
    private let spreadsheetURLString = "https://docs.google.com/spreadsheets/d/e/2PACX-1vR6-S8Z4ZfN_Dby3v9M7Lp_B9K9Q3v2U7A1z4XyG8p9H2m5V7n_o_zQ_rA_xG1-p0q8wM2W2P6yLzO/pub?output=csv"
    
    func loadCMSData() async {
        guard !isLoading else { return }
        isLoading = true
        
        // Simulating the actual async network fetch from your CSV spreadsheet source
        do {
            // Your existing fetch code goes here...
            // e.g., let data = try await NetworkManager.shared.fetchData(from: spreadsheetURLString)
            // parser.parse(data)
            
            // --- AUTO TRIGGER DIGESTS FOR EDITORIAL HEADLINES ON SUCCESSFUL LOAD ---
            let headlinesList = self.editorialItems.map { $0.title }
            if !headlinesList.isEmpty {
                NotificationManager.shared.scheduleDailyEditorialDigests(headlines: headlinesList)
            }
            
        } catch {
            AppLogger.shared.error("Failed loading spreadsheet data: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}

// MARK: - Core Supporting Data Models
struct FeaturedMatch: Identifiable, Decodable {
    let id: Int
    let homeTeam: String
    let awayTeam: String
    let matchDate: String
    let matchTime: String
    let status: String
    let competition: String
    let group: String
    let homeFlagURL: String
    let awayFlagURL: String
    let homeFallbackColor: String
    let awayFallbackColor: String
    let displayScore: String
    
    func getTeamInitials(from name: String) -> String {
        let words = name.components(separatedBy: " ")
        let initials = words.compactMap { $0.first }.map { String($0) }.joined()
        return String(initials.prefix(2)).uppercased()
    }
}

struct EditorialItem: Identifiable, Decodable {
    let id: UUID
    let title: String
    let description: String
    let articleURL: String
    let imageURL: String
}
