import SwiftUI

struct RewardedAdPromptView: View {
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Semi-transparent backdrop (handled by parent VC, but keep for safety)
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { /* Prevent tap-through */ }

            // Card
            VStack(spacing: 24) {
                // Pulsing heart
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                        .scaleEffect(heartScale)
                }
                .padding(.top, 8)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        heartScale = 1.2
                    }
                }

                Text("Support StrikeScore")
                    .font(.system(size: 20, weight: .black, design: .rounded))

                Text("Help us keep StrikeScore free for everyone. Watch a short video to support our development team!")
                    .font(.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                    .padding(.horizontal, 4)

                // Watch Video Button
                Button(action: {
                    AdMobManager.shared.showRewarded(onRewardEarned: { amount in
                        alertMessage = "Thank you! You earned \(amount) points."
                        showingAlert = true
                    }, onClose: {
                        dismissPrompt()
                    })
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                        Text("Watch Video")
                            .font(.system(size: 16, weight: .black))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.green.opacity(0.35), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())

                // Grayed-out cancel
                Button(action: {
                    dismissPrompt()
                }) {
                    Text("No thanks, maybe later")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
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
        // Dismiss the modal
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            rootVC.dismiss(animated: true)
        }
    }
}

struct RewardedAdPromptView_Previews: PreviewProvider {
    static var previews: some View {
        RewardedAdPromptView()
            .background(Color.black.opacity(0.6))
    }
}
