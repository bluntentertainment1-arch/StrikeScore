import SwiftUI

struct TeamLogoView: View {
    let teamName: String
    let localSpreadsheetURL: URL?
    let fallbackColor: Color
    let initials: String
    let size: CGFloat
    
    @State private var resolvedLogoURL: URL? = nil
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let url = resolvedLogoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure, .empty:
                        fallbackBlock
                    @unknown default:
                        fallbackBlock
                    }
                }
            } else if isLoading {
                ProgressView()
                    .scaleEffect(size * 0.02) // Dynamically scales indicator to fit bound size
            } else {
                fallbackBlock
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task {
            await resolveTeamLogo()
        }
    }
    
    private var fallbackBlock: some View {
        ZStack {
            fallbackColor
            Text(initials)
                .font(.system(size: size * 0.38, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
    }
    
    private func resolveTeamLogo() async {
        // Step 1: Check if the spreadsheet already has a valid direct web link filled out
        if let localURL = localSpreadsheetURL {
            self.resolvedLogoURL = localURL
            self.isLoading = false
            return
        }
        
        // Step 2: Fall back to querying your custom SportsDB search engine route
        if let apiURL = await SportsDBLogoService.shared.fetchLogoURL(for: teamName) {
            self.resolvedLogoURL = apiURL
        }
        
        self.isLoading = false
    }
}
