import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        // Instantiate using the modern prefixless class and size properties
        let bannerView = BannerView(adSize: AdSizeBanner)
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
