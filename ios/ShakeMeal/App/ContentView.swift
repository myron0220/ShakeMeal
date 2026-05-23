import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ShakeView()
                .tag(0)
                .toolbar(.hidden, for: .tabBar)

            ProfileView()
                .tag(1)
                .toolbar(.hidden, for: .tabBar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

// MARK: - Custom Tab Bar

private struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "fork.knife.circle.fill",
                label: "Shake",
                isSelected: selectedTab == 0
            ) { selectedTab = 0 }

            TabBarButton(
                icon: "person.circle.fill",
                label: "Profile",
                isSelected: selectedTab == 1
            ) { selectedTab = 1 }
        }
        .padding(.vertical, 5)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) { Divider() }
    }
}

private struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @State private var scale: CGFloat = 1.0

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                scale = 1.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
            action()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 8, weight: .medium))
            }
            .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
            .scaleEffect(scale)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(ShakeViewModel(locationManager: LocationManager()))
        .environmentObject(AuthManager())
}
