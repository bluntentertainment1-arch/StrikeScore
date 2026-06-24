import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {[span_21](start_span)[span_21](end_span)
    let adUnitID: String[span_22](start_span)[span_22](end_span)

    func makeUIView(context: Context) -> BannerView {[span_23](start_span)[span_23](end_span)
        // Instantiate using the modern prefixless class and size properties[span_24](start_span)[span_24](end_span)
        let bannerView = BannerView(adSize: AdSizeBanner)[span_25](start_span)[span_25](end_span)
        bannerView.adUnitID = adUnitID[span_26](start_span)[span_26](end_span)
        
        // ✅ FIXED: Modern UIWindowScene lookups without the GAD prefix or deprecated window references
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            bannerView.rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        }
        
        bannerView.load(Request())[span_27](start_span)[span_27](end_span)
        return bannerView[span_28](start_span)[span_28](end_span)
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}[span_29](start_span)[span_29](end_span)
}
