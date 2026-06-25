import SwiftUI
import GoogleMobileAds

enum BannerAdSize {
    case standard      // 320x50
    case mediumRectangle // 300x250 (square)
    case largeBanner   // 320x100
    case fullBanner    // 468x60

    var adSize: AdSize {
        switch self {
        case .standard:
            return AdSizeBanner
        case .mediumRectangle:
            return AdSizeMediumRectangle
        case .largeBanner:
            return AdSizeLargeBanner
        case .fullBanner:
            return AdSizeFullBanner
        }
    }

    var height: CGFloat {
        switch self {
        case .standard:
            return 50
        case .mediumRectangle:
            return 250
        case .largeBanner:
            return 100
        case .fullBanner:
            return 60
        }
    }
}

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    let adSize: BannerAdSize

    init(adUnitID: String, adSize: BannerAdSize = .standard) {
        self.adUnitID = adUnitID
        self.adSize = adSize
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize.adSize)
        bannerView.adUnitID = adUnitID

        // Resolves target warning safely using modern WindowScene lookups
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            bannerView.rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        }

        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

// MARK: - Inline Banner Ad Container (for inserting between list items)
struct InlineBannerAdView: View {
    let adUnitID: String
    let adSize: BannerAdSize

    var body: some View {
        BannerAdView(adUnitID: adUnitID, adSize: adSize)
            .frame(height: adSize.height)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}
