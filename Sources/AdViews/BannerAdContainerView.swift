import SwiftUI

struct BannerAdContainerView: View {
    var body: some View {
        VStack {
            BannerAdView(adUnitID: AdMobManager.bannerAdUnitID)
                .frame(height: 50)
        }
    }
}
