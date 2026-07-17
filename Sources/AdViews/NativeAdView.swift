import SwiftUI
import GoogleMobileAds
import UIKit

// MARK: - Loader / View Model
final class NativeAdLoaderViewModel: NSObject, ObservableObject, NativeAdLoaderDelegate {
    @Published var nativeAd: NativeAd?

    private var adLoader: AdLoader?
    private let adUnitID: String
    private var retryCount = 0
    private let maxRetryDelay: TimeInterval = 60

    init(adUnitID: String) {
        self.adUnitID = adUnitID
    }

    func loadAd() {
        var rootVC: UIViewController?
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        }
        let loader = AdLoader(adUnitID: adUnitID, rootViewController: rootVC, adTypes: [.native], options: nil)
        loader.delegate = self
        adLoader = loader
        loader.load(Request())
    }

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        retryCount = 0
        self.nativeAd = nativeAd
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        AppLogger.shared.error("Native ad failed to load: \(error.localizedDescription)")
        self.nativeAd = nil

        // Retry with exponential backoff instead of giving up permanently.
        let delay = min(5.0 * pow(2.0, Double(retryCount)), maxRetryDelay)
        retryCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.loadAd()
        }
    }
}

// MARK: - UIKit native ad view (required for the SDK to register/track clicks & impressions)
struct NativeAdContainerView: UIViewRepresentable {
    let nativeAd: NativeAd

    func makeUIView(context: Context) -> NativeAdView {
        let adView = NativeAdView()
        adView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        adView.layer.cornerRadius = 10
        adView.clipsToBounds = true

        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 6
        iconImageView.clipsToBounds = true
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        adView.iconView = iconImageView

        let headlineLabel = UILabel()
        headlineLabel.font = .boldSystemFont(ofSize: 15)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 2
        adView.headlineView = headlineLabel

        let topRow = UIStackView(arrangedSubviews: [iconImageView, headlineLabel])
        topRow.axis = .horizontal
        topRow.spacing = 8
        topRow.alignment = .center

        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        adView.mediaView = mediaView

        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = .lightGray
        bodyLabel.numberOfLines = 2
        adView.bodyView = bodyLabel

        let advertiserLabel = UILabel()
        advertiserLabel.font = .systemFont(ofSize: 11)
        advertiserLabel.textColor = .gray
        adView.advertiserView = advertiserLabel

        let ctaButton = UIButton(type: .system)
        ctaButton.titleLabel?.font = .boldSystemFont(ofSize: 13)
        ctaButton.backgroundColor = .systemGreen
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.layer.cornerRadius = 6
        // The SDK handles taps on behalf of the ad view — CTA button itself
        // must not intercept touches, or clicks won't be tracked correctly.
        ctaButton.isUserInteractionEnabled = false
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        adView.callToActionView = ctaButton

        let mainStack = UIStackView(arrangedSubviews: [topRow, mediaView, bodyLabel, advertiserLabel, ctaButton])
        mainStack.axis = .vertical
        mainStack.spacing = 6
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
            mainStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
            mainStack.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -8),
        ])

        populate(adView: adView, with: nativeAd)
        return adView
    }

    func updateUIView(_ uiView: NativeAdView, context: Context) {
        populate(adView: uiView, with: nativeAd)
    }

    private func populate(adView: NativeAdView, with nativeAd: NativeAd) {
        (adView.headlineView as? UILabel)?.text = nativeAd.headline

        (adView.bodyView as? UILabel)?.text = nativeAd.body
        adView.bodyView?.isHidden = nativeAd.body == nil

        (adView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        adView.iconView?.isHidden = nativeAd.icon == nil

        (adView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        adView.callToActionView?.isHidden = nativeAd.callToAction == nil

        (adView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        adView.advertiserView?.isHidden = nativeAd.advertiser == nil

        (adView.mediaView as? MediaView)?.mediaContent = nativeAd.mediaContent

        // Required last: associates the ad object with the populated view so
        // the SDK can track impressions/clicks on the assets above.
        adView.nativeAd = nativeAd
    }
}

// MARK: - Inline Native Ad (Auto-shows/hides based on ad load state)
struct InlineNativeAdView: View {
    let adUnitID: String
    @StateObject private var viewModel: NativeAdLoaderViewModel

    init(adUnitID: String) {
        self.adUnitID = adUnitID
        _viewModel = StateObject(wrappedValue: NativeAdLoaderViewModel(adUnitID: adUnitID))
    }

    var body: some View {
        Group {
            if let nativeAd = viewModel.nativeAd {
                NativeAdContainerView(nativeAd: nativeAd)
                    .frame(height: 280)
            }
        }
        .onAppear {
            // Kick off the load regardless of current state — unlike the
            // banner bug from earlier, this isn't gated behind isLoaded, so
            // there's no chicken-and-egg problem here.
            if viewModel.nativeAd == nil {
                viewModel.loadAd()
            }
        }
    }
}
