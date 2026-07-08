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

// MARK: - Banner Ad View (Auto-shows when ad loads)
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    let adSize: BannerAdSize
    @Binding var isLoaded: Bool

    init(adUnitID: String, adSize: BannerAdSize = .standard, isLoaded: Binding<Bool> = .constant(true)) {
        self.adUnitID = adUnitID
        self.adSize = adSize
        self._isLoaded = isLoaded
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize.adSize)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            bannerView.rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        }

        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, BannerViewDelegate {
        var parent: BannerAdView

        init(_ parent: BannerAdView) {
            self.parent = parent
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            parent.isLoaded = true
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            parent.isLoaded = false
        }
    }
}

// MARK: - Inline Banner Ad Container (Auto-shows/hides based on ad load state)
struct InlineBannerAdView: View {
    let adUnitID: String
    let adSize: BannerAdSize
    @State private var isAdLoaded = false

    var body: some View {
        Group {
            if isAdLoaded {
                BannerAdView(adUnitID: adUnitID, adSize: adSize, isLoaded: $isAdLoaded)
                    .frame(height: adSize.height)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                EmptyView()
            }
        }
    }
}
