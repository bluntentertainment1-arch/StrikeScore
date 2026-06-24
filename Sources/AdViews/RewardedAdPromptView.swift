import SwiftUI

struct RewardedAdPromptView: View {
    @State private var showingAlert = false
    @State private var alertMessage = ""

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
                AdMobManager.shared.showRewarded(onRewardEarned: { amount in
                    alertMessage = "Thank you for your support! You earned \(amount) points."
                    showingAlert = true
                }, onClose: {
                    // Fail safely if ad is closed early or cancelled
                })
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
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Reward Earned"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct RewardedAdPromptView_Previews: PreviewProvider {
    static var previews: some View {
        RewardedAdPromptView()
    }
}
