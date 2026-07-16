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

// MARK: - Temporary Debug State (remove once banner issue is diagnosed)
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
        } else {
            BannerDebugState.shared.lastStatus = "WARNING: no rootViewController found at load time"
        }

        BannerDebugState.shared.lastStatus = "Requesting ad for \(adUnitID)..."
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
                BannerDebugState.shared.lastStatus = "SUCCESS: ad loaded at \(Date().formatted(date: .omitted, time: .standard))"
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
            // BannerAdView must stay mounted at all times so it can actually call
            // .load() (and retry on failure). Conditionally instantiating it here
            // meant it never loaded a single ad in the first place. Instead, keep
            // it in the tree and just collapse it visually until it has content.
            BannerAdView(adUnitID: adUnitID, adSize: adSize, isLoaded: $isAdLoaded)
                .frame(height: isAdLoaded ? adSize.height : 0)
                .frame(maxWidth: isAdLoaded ? .infinity : 0)
                .background(isAdLoaded ? Color(.systemGray6) : Color.clear)
                .cornerRadius(isAdLoaded ? 8 : 0)
                .opacity(isAdLoaded ? 1 : 0)
                .clipped()

            // TEMP DEBUG — remove once the banner issue is diagnosed.
            Text("banner debug: \(debugState.lastStatus)")
                .font(.system(size: 9))
                .foregroundColor(.red)
                .lineLimit(3)
                .multilineTextAlignment(.center)
        }
    }
}
