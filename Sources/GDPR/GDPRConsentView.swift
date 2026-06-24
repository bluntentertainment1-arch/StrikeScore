import SwiftUI

struct GDPRConsentView: View {
    // A clean binding back to control your StrikeScoreApp flow phases smoothly
    var isPresented: Binding<Bool>

    var body: some View {
        ZStack {
            // Darkened blur overlay to isolate the compact alert view block elegantly
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
            
            // Compact Native-Alert-Style Container
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "shield.user.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                        .padding(.bottom, 4)

                    Text("Privacy & Data Preferences")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    
                    Text("StrikeScore uses cookies and anonymous analytics to deliver match updates, secure stability metrics, and optimize tailored ad profiles.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 4)

                // Quick Structural Interaction Stack
                VStack(spacing: 8) {
                    // Accept Choice
                    Button(action: {
                        GDPRConsentManager.shared.giveConsent()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented.wrappedValue = false
                        }
                    }) {
                        Text("Accept & Continue")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    
                    // Decline Choice (App Store Compliant: Continues without blocking)
                    Button(action: {
                        GDPRConsentManager.shared.revokeConsent()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented.wrappedValue = false
                        }
                    }) {
                        Text("Use Limited Version")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                    }
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40) // Keeps it small, compact, and centered on mobile devices
        }
    }
}
