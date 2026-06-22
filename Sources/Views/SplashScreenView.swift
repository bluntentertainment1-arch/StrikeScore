import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var scale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0.0
    @State private var loadingProgress: CGFloat = 0.0
    @State private var ambientGlowPulse = false

    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // Stadium Dark Ambient Background
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                // Subtle Backlight Ambient Glow Effect
                Circle()
                    .fill(Color.green.opacity(ambientGlowPulse ? 0.15 : 0.06))
                    .frame(width: 250, height: 250)
                    .blur(radius: 40)
                    .scaleEffect(ambientGlowPulse ? 1.2 : 0.9)
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Animated Branding Emblem Asset
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 90))
                        .foregroundColor(.green)
                        .shadow(color: .green.opacity(0.4), radius: 12, x: 0, y: 6)
                        .scaleEffect(scale)
                        .opacity(iconOpacity)
                    
                    VStack(spacing: 8) {
                        Text("StrikeScore")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                            .tracking(0.5)
                        
                        Text("Live Football Scores & Fixtures")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .offset(y: textOffset)
                    .opacity(textOpacity)
                    
                    Spacer()
                    
                    // Dynamic Loading Track Pillar Bar
                    VStack(spacing: 12) {
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(width: 160, height: 4)
                            
                            Capsule()
                                .fill(Color.green)
                                .frame(width: 160 * loadingProgress, height: 4)
                                .shadow(color: .green.opacity(0.4), radius: 4, x: 0, y: 0)
                        }
                        
                        Text("Loading data pipeline...")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.0)
                    }
                    .padding(.bottom, 40)
                }
            }
            .onAppear {
                // Step 1: Fire Ambient Background Breathing Loop
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    ambientGlowPulse = true
                }
                
                // Step 2: Pop and scale the center icon layout
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                    iconOpacity = 1.0
                    scale = 1.0
                }
                
                // Step 3: Transition text elements right behind the scale burst
                withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                    textOpacity = 1.0
                    textOffset = 0
                }
                
                // Step 4: Fluidly fill loading monitor bar
                withAnimation(.linear(duration: 1.8).delay(0.4)) {
                    loadingProgress = 1.0
                }
                
                // Step 5: Smoothly exit tracking routine and push into ContentView
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isActive = true
                    }
                }
            }
        }
    }
}
