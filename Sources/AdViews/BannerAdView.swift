import SwiftUI
import GoogleMobileAds

enum BannerAdSize {
    case standard      // Adaptive anchored banner (Google-recommended over fixed 320x50)
    case mediumRectangle // 300x250 (square)
    case largeBanner   // 320x100
    case fullBanner    // 468x60

    var fixedAdSize: AdSize? {
        switch self {
        case .standard:
            return nil
        case .mediumRectangle:
            return AdSizeMediumRectangle
        case .largeBanner:
            return AdSizeLargeBanner
        case .fullBanner:
            return AdSizeFullBanner
        }
    }

    /// Resolved from the device's screen width rather than the SwiftUI
    /// layout tree. This is what lets the container safely collapse to zero
    /// height when there's no ad: if the size were derived from a
    /// GeometryReader inside a collapsed (0-height) parent, the reported
    /// width could come back 0 too, producing an invalid AdSize and an
    /// "Invalid ad width or height" load failure. Deriving from the screen
    /// directly avoids that coupling entirely.
    var resolvedAdSize: AdSize {
        if let fixed = fixedAdSize {
            return fixed
        }
        return currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)
    }
}

// MARK: - Banner Ad View (Auto-shows when ad loads)
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    let resolvedSize: AdSize
    @Binding var isLoaded: Bool

    init(adUnitID: String, resolvedSize: AdSize, isLoaded: Binding<Bool> = .constant(true)) {
        self.adUnitID = adUnitID
        self.resolvedSize = resolvedSize
        self._isLoaded = isLoaded
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: resolvedSize)
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
            AppLogger.shared.error("Banner failed to load: \(error.localizedDescription)")
            // No auto-retry here — repeated backoff retries across every
            // banner slot (plus interstitial/rewarded doing the same) is
            // what was hammering AdMob and triggering throttling. The
            // banner simply reloads when its view reappears — see
            // InlineBannerAdView's onAppear below.
        }
    }
}

// MARK: - Inline Banner Ad Container (Auto-shows/hides based on ad load state)
struct InlineBannerAdView: View {
    let adUnitID: String
    let adSize: BannerAdSize
    @State private var isAdLoaded = false
    @State private var reloadID = UUID()

    var body: some View {
        BannerAdView(adUnitID: adUnitID, resolvedSize: adSize.resolvedAdSize, isLoaded: $isAdLoaded)
            .id(reloadID)
            .background(isAdLoaded ? Color(.systemGray6) : Color.clear)
            .cornerRadius(isAdLoaded ? 8 : 0)
            .frame(height: isAdLoaded ? adSize.resolvedAdSize.size.height : 0)
            .frame(maxWidth: .infinity)
            .opacity(isAdLoaded ? 1 : 0)
            .clipped()
            .onAppear {
                // Banner no longer auto-retries on a timer. If it isn't
                // currently loaded, changing the id forces BannerAdView to
                // be recreated, which issues one fresh load.
                if !isAdLoaded {
                    reloadID = UUID()
                }
            }
    }
}
