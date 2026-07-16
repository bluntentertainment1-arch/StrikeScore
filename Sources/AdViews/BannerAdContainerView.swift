import SwiftUI

struct BannerAdContainerView: View {
    @State private var isAdLoaded = false

    var body: some View {
        // See InlineBannerAdView: BannerAdView must stay mounted so it can
        // actually trigger a load/retry, not be gated behind isAdLoaded.
        BannerAdView(adUnitID: AdMobManager.bannerAdUnitID, isLoaded: $isAdLoaded)
            .frame(height: isAdLoaded ? 50 : 0)
            .opacity(isAdLoaded ? 1 : 0)
            .clipped()
    }
}
