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
        
        do {
            // Your networking fetch engine runs here...
            
            // --- AUTOMATICALLY HOOK COMPLETED HEADLINES TO SYSTEM NOTIFICATIONS ---
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
