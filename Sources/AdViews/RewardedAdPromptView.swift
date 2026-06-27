import SwiftUI

struct RewardedAdPromptView: View {
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    // Backward-compatible animation state
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 28) {
            // Animated support icon (iOS 16 compatible)
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                    .scaleEffect(heartScale)
                    .onAppear {
                        // Backward-compatible pulse animation
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            heartScale = 1.15
                        }
                    }
            }
            .padding(.top, 8)

            // Headline
            Text("Support StrikeScore")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)

            // Body text
            Text("Help us keep StrikeScore free for everyone. Watch a short video to support our development team!")
                .font(.system(size: 15, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(.horizontal, 8)

            // Captivating Watch Video Button
            Button(action: {
                AdMobManager.shared.showRewarded(onRewardEarned: { amount in
                    alertMessage = "Thank you for your support! You earned \(amount) points."
                    showingAlert = true
                }, onClose: {
                    dismiss()
                })
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 20))
                    Text("Watch Video")
                        .font(.system(size: 17, weight: .black))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color.green.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 4)

            // Grayed-out Cancel / Ignore button
            Button(action: {
                dismiss()
            }) {
                Text("No thanks, maybe later")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Reward Earned"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    dismiss()
                }
            )
        }
    }
}

struct RewardedAdPromptView_Previews: PreviewProvider {
    static var previews: some View {
        RewardedAdPromptView()
    }
}
