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

// MARK: - Temporary Debug State (remove once banner issue is confirmed fixed)
final class BannerDebugState: ObservableObject {
    static let shared = BannerDebugState()
    @Published var lastStatus: String = "Not attempted yet"
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

        BannerDebugState.shared.lastStatus = "Requesting... adSize=\(adSize.adSize.size.width)x\(adSize.adSize.size.height)"
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
            // BannerAdView must always have a real, non-zero frame — the SDK
            // validates the container's size at load() time, and collapsing
            // it to 0x0 while unloaded (the previous approach) caused every
            // request to fail with "Invalid ad width or height" before it
            // even had a chance to fill. Reserve the real size up front and
            // only toggle visibility, not layout size.
            BannerAdView(adUnitID: adUnitID, adSize: adSize, isLoaded: $isAdLoaded)
                .frame(height: adSize.height)
                .frame(maxWidth: .infinity)
                .background(isAdLoaded ? Color(.systemGray6) : Color.clear)
                .cornerRadius(isAdLoaded ? 8 : 0)
                .opacity(isAdLoaded ? 1 : 0)

            // TEMP DEBUG — remove once confirmed fixed.
            Text("banner debug: \(debugState.lastStatus)")
                .font(.system(size: 9))
                .foregroundColor(.red)
                .lineLimit(3)
                .multilineTextAlignment(.center)
        }
    }
}
