import Foundation

struct EditorialItem: Identifiable, Codable, Hashable {
    let id: String
    let headline: String
    let body: String
    let datePosted: String
    let active: Bool
}
