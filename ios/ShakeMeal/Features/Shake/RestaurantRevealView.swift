import SwiftUI
import MapKit

struct RestaurantRevealView: View {
    let restaurant: Restaurant
    let onShakeAgain: () -> Void

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Photo / Header
                photoHeader

                // Details card
                VStack(alignment: .leading, spacing: 20) {
                    nameSection
                    metaRow
                    Divider()
                    actionButtons
                }
                .padding(24)
                .background(AppColors.card, in: .rect(cornerRadius: 24))
                .padding(.horizontal, 16)
                .offset(y: -24)

                // Shake Again
                Button(action: onShakeAgain) {
                    Label("Shake Again", systemImage: "arrow.clockwise")
                        .font(AppFonts.button)
                        .foregroundStyle(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.primary.opacity(0.12), in: .capsule)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .ignoresSafeArea(edges: .top)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.94)
        .animation(.spring(duration: 0.4), value: appeared)
        .onAppear { appeared = true }
    }

    // MARK: - Sub-views
    private var photoHeader: some View {
        ZStack(alignment: .bottom) {
            if let url = restaurant.photoURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholderGradient
                }
            } else {
                placeholderGradient
            }
        }
        .frame(height: 280)
        .clipped()
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [AppColors.primary.opacity(0.7), AppColors.primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Text("🍽️")
                .font(.system(size: 72))
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(restaurant.name)
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            Text(restaurant.address)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var metaRow: some View {
        HStack(spacing: 16) {
            Label(String(format: "%.1f", restaurant.rating), systemImage: "star.fill")
                .foregroundStyle(AppColors.star)

            Text("·").foregroundStyle(AppColors.textSecondary)

            Text(restaurant.priceDisplay)
                .foregroundStyle(AppColors.textSecondary)

            Text("·").foregroundStyle(AppColors.textSecondary)

            Text(restaurant.cuisine)
                .foregroundStyle(AppColors.textSecondary)

            if !restaurant.distanceDisplay.isEmpty {
                Text("·").foregroundStyle(AppColors.textSecondary)
                Text(restaurant.distanceDisplay).foregroundStyle(AppColors.textSecondary)
            }
        }
        .font(AppFonts.meta)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                openInMaps()
            } label: {
                Label("Directions", systemImage: "map.fill")
                    .font(AppFonts.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.primary, in: .capsule)
            }

            Button {
                // TODO: add to favorites
            } label: {
                Image(systemName: "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 48, height: 48)
                    .background(AppColors.primary.opacity(0.12), in: .circle)
            }

            Button {
                shareRestaurant()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 48, height: 48)
                    .background(AppColors.primary.opacity(0.12), in: .circle)
            }
        }
    }

    // MARK: - Actions
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: restaurant.latitude,
                                                longitude: restaurant.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = restaurant.name
        mapItem.openInMaps()
    }

    private func shareRestaurant() {
        let text = "Check out \(restaurant.name) — \(restaurant.address) 🍽️ Found with ShakeMeal!"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let root = window.rootViewController else { return }
        root.present(av, animated: true)
    }
}

#Preview {
    RestaurantRevealView(restaurant: .mock) {}
}
