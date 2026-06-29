import SwiftUI

struct RewardedAdPromptView: View {
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Subtle dimming backdrop
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            // Compact card centered
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                        .scaleEffect(heartScale)
                }
                .padding(.top, 4)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        heartScale = 1.2
                    }
                }

                Text("Support StrikeScore")
                    .font(.system(size: 17, weight: .bold, design: .rounded))

                Text("Watch a short video to support our development team and keep the app free.")
                    .font(.system(size: 13, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
                    .padding(.horizontal, 4)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: {
                    AdMobManager.shared.showRewarded(onRewardEarned: { amount in
                        alertMessage = "Thank you! You earned \(amount) points."
                        showingAlert = true
                    }, onClose: {
                        dismissPrompt()
                    })
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 16))
                        Text("Watch Video")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    dismissPrompt()
                }) {
                    Text("Not Now")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(width: 270)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
            )
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Reward Earned"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    dismissPrompt()
                }
            )
        }
    }

    private func dismissPrompt() {
        AdMobManager.shared.setRewardedPromptVisible(false)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        var current = rootVC
        while let presented = current.presentedViewController {
            current = presented
        }
        current.dismiss(animated: true)
    }
}

struct RewardedAdPromptView_Previews: PreviewProvider {
    static var previews: some View {
        RewardedAdPromptView()
    }
}
