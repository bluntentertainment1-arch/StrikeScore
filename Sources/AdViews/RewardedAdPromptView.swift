import SwiftUI

struct RewardedAdPromptView: View {
    @State private var showingAd = false
    @State private var rewardEarned = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Support StrikeScore")
                .font(.title2)
                .fontWeight(.bold)

            Text("Watch a short video to support our app and keep it free!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button(action: {
                showingAd = true
            }) {
                Label("Watch Video", systemImage: "play.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}
