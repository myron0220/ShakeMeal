import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ShakeView()
                .tabItem {
                    Label("Shake", systemImage: "fork.knife.circle.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }

            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
        }
        .tint(AppColors.primary)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
}
