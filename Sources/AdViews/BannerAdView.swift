import SwiftUI
import GoogleMobileAds

enum BannerAdSize {
    case standard      // Adaptive anchored banner (Google-recommended over fixed 320x50)
    case mediumRectangle // 300x250 (square)
    case largeBanner   // 320x100
    case fullBanner    // 468x60

    /// Fixed sizes only. `.standard` has no fixed size — it's resolved at
    /// render time from the real available width via `resolvedAdSize(width:)`,
    /// since adaptive banners need to know the actual on-screen width.
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

    func resolvedAdSize(width: CGFloat) -> AdSize {
        if let fixed = fixedAdSize {
            return fixed
        }
        return currentOrientationAnchoredAdaptiveBanner(width: width)
    }
}

// MARK: - Temporary Debug State (remove once banner issue is confirmed fixed)
final class BannerDebugState: ObservableObject {
    static let shared = BannerDebugState()
    @Published var lastStatus: String = "Not attempted yet"
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

        BannerDebugState.shared.lastStatus = "Requesting... adSize=\(resolvedSize.size.width)x\(resolvedSize.size.height)"
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, BannerViewDelegate {
        var parent: BannerAdView
        private var retryCount = 0
        private let maxRetryDelay: TimeInterval = 60

        init(_ parent: BannerAdView) {
            self.parent = parent
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            retryCount = 0
            parent.isLoaded = true
            DispatchQueue.main.async {
                BannerDebugState.shared.lastStatus = "SUCCESS at \(Date().formatted(date: .omitted, time: .standard))"
            }
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            parent.isLoaded = false
            AppLogger.shared.error("Banner failed to load: \(error.localizedDescription)")
            let nsError = error as NSError
            DispatchQueue.main.async {
                BannerDebugState.shared.lastStatus = "FAIL [\(nsError.domain) \(nsError.code)]: \(nsError.localizedDescription) — retry #\(self.retryCount + 1)"
            }

            // Retry with exponential backoff instead of giving up permanently.
            let delay = min(5.0 * pow(2.0, Double(retryCount)), maxRetryDelay)
            retryCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak bannerView] in
                bannerView?.load(Request())
            }
        }
    }
}

// MARK: - Inline Banner Ad Container (Auto-shows/hides based on ad load state)
struct InlineBannerAdView: View {
    let adUnitID: String
    let adSize: BannerAdSize
    @State private var isAdLoaded = false
    @ObservedObject private var debugState = BannerDebugState.shared

    var body: some View {
        VStack(spacing: 2) {
            // GeometryReader gives the real available width so adaptive
            // banners can be sized correctly. BannerAdView always keeps a
            // real, non-zero frame — the SDK validates the container's size
            // at load() time, and collapsing it to 0x0 while unloaded caused
            // every request to fail with "Invalid ad width or height."
            GeometryReader { geo in
                let resolved = adSize.resolvedAdSize(width: geo.size.width)
                BannerAdView(adUnitID: adUnitID, resolvedSize: resolved, isLoaded: $isAdLoaded)
                    .background(isAdLoaded ? Color(.systemGray6) : Color.clear)
                    .cornerRadius(isAdLoaded ? 8 : 0)
                    .opacity(isAdLoaded ? 1 : 0)
                    .frame(width: geo.size.width, height: resolved.size.height)
            }
            .frame(height: adSize.fixedAdSize?.size.height ?? 50)
            .frame(maxWidth: .infinity)

            // TEMP DEBUG — remove once confirmed fixed.
            Text("banner debug: \(debugState.lastStatus)")
                .font(.system(size: 9))
                .foregroundColor(.red)
                .lineLimit(3)
                .multilineTextAlignment(.center)
        }
    }
}
