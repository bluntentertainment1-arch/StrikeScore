import SwiftUI

struct BannerAdContainerView: View {
    @State private var isAdLoaded = false

    var body: some View {
        Group {
            if isAdLoaded {
                BannerAdView(adUnitID: AdMobManager.bannerAdUnitID, isLoaded: $isAdLoaded)
                    .frame(height: 50)
            } else {
                EmptyView()
            }
        }
    }
}
