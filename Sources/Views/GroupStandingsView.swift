import SwiftUI

struct GroupStandingsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "tablecells")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("Standings")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Group standings will be available soon")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 100)
            .navigationTitle("Standings")
        }
    }
}
