import Foundation

struct EditorialItem: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let imageURL: String?
    let content: String?
    let date: Date?
    let headline: String?  // Required by FeaturedCardView.swift:21
    
    // Add other properties based on your ExcelCMS parsing logic
}
