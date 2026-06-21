import Foundation

struct FeaturedMatch: Identifiable {
    let id: String
    let competition: String
    let homeTeam: String
    let awayTeam: String
    let matchDate: String
    let headline: String
    let subheadline: String
    let priority: Int
    let showUntil: Date
    let active: Bool

    var isVisible: Bool {
        active && showUntil > Date()
    }
}

struct EditorialItem: Identifiable {
    let id: String
    let headline: String
    let body: String
    let datePosted: String
    let active: Bool
}
