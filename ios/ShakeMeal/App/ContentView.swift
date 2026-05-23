import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ShakeView()
                .tabItem { Label("Shake",   systemImage: "fork.knife.circle.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle.fill") }
        }
        .tint(AppColors.primary)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(ShakeViewModel(locationManager: LocationManager()))
        .environmentObject(AuthManager())
}
