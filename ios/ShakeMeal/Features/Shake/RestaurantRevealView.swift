import SwiftUI
import MapKit

// How long the ring must be held before release triggers refresh.
// This exactly matches the dim animation duration so visual feedback
// and trigger threshold are always in sync.
private let kRingHoldThreshold: TimeInterval = 1.0

struct RestaurantRevealView: View {
    let restaurant: Restaurant
    let onShakeAgain: () -> Void
    @ObservedObject var ringVM: RingViewModel

    @EnvironmentObject var authManager: AuthManager
    @State private var isFavorited = false
    @State private var favoriteLoading = false
    @State private var pressStartTime: Date? = nil

    // Self-contained entry animation.
    @State private var slideOffset: CGFloat = 600
    @State private var slideOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    photoHeader

                    VStack(alignment: .leading, spacing: 20) {
                        nameSection
                        metaRow
                        Divider()
                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }

            // Ring button lives OUTSIDE the ScrollView so iOS doesn't
            // delay the touch — we control the dim timing ourselves.
            ringButton
                .padding(.top, 4)
                .padding(.bottom, 36)
                .task {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(Double.random(in: 6.0...12.0)))
                        guard !Task.isCancelled else { break }
                        ringVM.autoBounce()
                    }
                }
        }
        .background(.white)
        .offset(y: slideOffset)
        .opacity(slideOpacity)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                slideOffset  = 0
                slideOpacity = 1
            }
        }
        .task {
            await checkFavoriteStatus()
            recordHistory()
        }
    }

    // MARK: - Ring button (outside ScrollView)

    private var ringButton: some View {
        Button { } label: {
            Circle()
                .trim(from: 0.0, to: 0.9382)
                .stroke(AppColors.primary,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(ringVM.displayAngle))
                .animation(
                    .spring(response: 0.8, dampingFraction: 0.42),
                    value: ringVM.baseRotation
                )
                // Our own dim: easeIn over exactly kRingHoldThreshold seconds.
                // When the dim completes the user knows they can release.
                .opacity(ringVM.isPressing ? 0.35 : 1.0)
                .animation(.easeIn(duration: kRingHoldThreshold), value: ringVM.isPressing)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if pressStartTime == nil {
                        pressStartTime = Date()
                    }
                    ringVM.startPress()
                }
                .onEnded { _ in
                    let elapsed = pressStartTime.map { Date().timeIntervalSince($0) } ?? 0
                    pressStartTime = nil
                    ringVM.endPress()
                    guard elapsed >= kRingHoldThreshold else { return }
                    SoundPlayer.click()
                    onShakeAgain()
                }
        )
    }

    // MARK: - Sub-views

    private var photoHeader: some View {
        ZStack(alignment: .bottom) {
            if let url = restaurant.photoURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, minHeight: 340, maxHeight: 340)
                        .clipped()
                } placeholder: {
                    placeholderGradient
                }
            } else {
                placeholderGradient
            }
        }
        .frame(maxWidth: .infinity, minHeight: 340, maxHeight: 340)
        .clipped()
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [AppColors.primary.opacity(0.7), AppColors.primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay { Text("🍽️").font(.system(size: 72)) }
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
            Text(restaurant.priceDisplay).foregroundStyle(AppColors.textSecondary)
            Text("·").foregroundStyle(AppColors.textSecondary)
            Text(restaurant.cuisine).foregroundStyle(AppColors.textSecondary)
            if !restaurant.distanceDisplay.isEmpty {
                Text("·").foregroundStyle(AppColors.textSecondary)
                Text(restaurant.distanceDisplay).foregroundStyle(AppColors.textSecondary)
            }
        }
        .font(AppFonts.meta)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Directions
            Button {
                openInMaps()
            } label: {
                Image(systemName: "map.fill")
                    .font(AppFonts.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.primary, in: .capsule)
            }

            // Favorite toggle
            Button {
                toggleFavorite()
            } label: {
                if favoriteLoading {
                    ProgressView()
                        .frame(width: 48, height: 48)
                } else {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isFavorited ? AppColors.primary : AppColors.primary)
                        .frame(width: 48, height: 48)
                        .background(AppColors.primary.opacity(isFavorited ? 0.2 : 0.12), in: .circle)
                }
            }
            .disabled(favoriteLoading || !authManager.isSignedIn)

            // Share
            Button { shareRestaurant() } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 48, height: 48)
                    .background(AppColors.primary.opacity(0.12), in: .circle)
            }
        }
    }

    // MARK: - Actions

    private func checkFavoriteStatus() async {
        guard authManager.isSignedIn else { return }
        do {
            let favs = try await APIClient.shared.getFavorites()
            isFavorited = favs.contains { $0.placeID == restaurant.id }
        } catch { }
    }

    private func toggleFavorite() {
        guard authManager.isSignedIn else { return }
        favoriteLoading = true
        Task {
            defer { favoriteLoading = false }
            do {
                if isFavorited {
                    try await APIClient.shared.deleteFavorite(placeID: restaurant.id)
                    isFavorited = false
                } else {
                    try await APIClient.shared.addFavorite(restaurant)
                    isFavorited = true
                }
            } catch {
                print("[RestaurantRevealView] favorite error:", error)
            }
        }
    }

    private func recordHistory() {
        guard authManager.isSignedIn else { return }
        Task {
            do { try await APIClient.shared.recordHistory(restaurant) }
            catch { print("[RestaurantRevealView] history error:", error) }
        }
    }

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
    RestaurantRevealView(restaurant: .mock, onShakeAgain: {}, ringVM: RingViewModel())
        .environmentObject(AuthManager())
}
