import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity = 0.0

    var body: some View {
        if isActive {
            ContentView()
        } else {
            VStack {
                Spacer()

                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("StrikeScore")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(.primary)

                Text("Live Football Scores & Fixtures")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                Spacer()

                Text(AppConstants.copyright)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 32)
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 1.0)) {
                    opacity = 1.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}
