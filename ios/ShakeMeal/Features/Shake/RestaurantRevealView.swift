import SwiftUI
import MapKit

struct RestaurantRevealView: View {
    let restaurant: Restaurant
    let onShakeAgain: () -> Void

    @EnvironmentObject var authManager: AuthManager
    @State private var isFavorited     = false
    @State private var favoriteLoading = false
    @State private var spinRotation: Double = 0

    // Self-contained entry animation — driven by onAppear, not ZStack transition,
    // so it fires reliably regardless of parent animation context.
    @State private var slideOffset:  CGFloat = 600
    @State private var slideOpacity: Double  = 0

    // Hero photo occupies ~50 % of screen height
    private let photoHeight: CGFloat = UIScreen.main.bounds.height * 0.50

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                actionStrip
                shakeAgainRow
                // Bottom breathing room above the tab bar
                Color.clear.frame(height: 32)
            }
        }
        .scrollIndicators(.hidden)
        .background(AppColors.background)
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

    // MARK: - Hero: full-bleed photo + overlaid text

    private var heroSection: some View {
        ZStack(alignment: .bottom) {

            // ── Photo ─────────────────────────────────────────────────
            Group {
                if let url = restaurant.photoURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            photoPlaceholder
                        default:
                            // Skeleton shimmer while loading
                            AppColors.surface
                                .overlay(shimmer)
                        }
                    }
                } else {
                    photoPlaceholder
                }
            }
            .frame(maxWidth: .infinity, minHeight: photoHeight, maxHeight: photoHeight)
            .clipped()
            .allowsHitTesting(false)

            // ── Gradient ramp → text overlay ─────────────────────────
            LinearGradient(
                stops: [
                    .init(color: .clear,                            location: 0.30),
                    .init(color: AppColors.background.opacity(0.55), location: 0.65),
                    .init(color: AppColors.background,               location: 1.00),
                ],
                startPoint: .top,
                endPoint:   .bottom
            )
            .frame(height: photoHeight)
            .allowsHitTesting(false)

            // ── Restaurant name + meta ────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Text(restaurant.name)
                    .font(.system(size: 26, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
                    .lineLimit(2)

                Text(restaurant.address)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(white: 1, opacity: 0.55))
                    .lineLimit(1)
                    .truncationMode(.tail)

                metaRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
        .frame(height: photoHeight)
    }

    // ── Photo placeholder ─────────────────────────────────────────────

    private var photoPlaceholder: some View {
        AppColors.surface
            .overlay {
                Text("🍽️")
                    .font(.system(size: 72))
                    .opacity(0.5)
            }
    }

    // ── Subtle loading shimmer ────────────────────────────────────────

    private var shimmer: some View {
        LinearGradient(
            colors: [
                AppColors.surface,
                AppColors.surfaceHigh,
                AppColors.surface,
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .opacity(0.6)
    }

    // MARK: - Meta row (star · price · cuisine · distance)

    private var metaRow: some View {
        HStack(spacing: 9) {
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppColors.star)
                Text(String(format: "%.1f", restaurant.rating))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            dot

            Text(restaurant.priceDisplay)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textSecondary)

            dot

            Text(restaurant.cuisine)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textSecondary)

            if !restaurant.distanceDisplay.isEmpty {
                dot
                Text(restaurant.distanceDisplay)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    /// Separator dot between meta items
    private var dot: some View {
        Circle()
            .fill(Color(white: 1, opacity: 0.22))
            .frame(width: 3, height: 3)
    }

    // MARK: - Action strip  (Directions · Save · Share)
    //
    // Three equal-width icon+label cells, separated by hairline dividers.
    // No fill, no capsule, no orange — just clean white-on-dark icons.

    private var actionStrip: some View {
        HStack(spacing: 0) {
            actionCell(icon: "map.fill", label: "Directions") {
                openInMaps()
            }

            hairline

            ZStack {
                actionCell(
                    icon:        isFavorited ? "heart.fill" : "heart",
                    label:       isFavorited ? "Saved" : "Save",
                    highlighted: isFavorited
                ) {
                    toggleFavorite()
                }
                .disabled(favoriteLoading || !authManager.isSignedIn)

                if favoriteLoading {
                    ProgressView()
                        .tint(AppColors.textSecondary)
                        .scaleEffect(0.8)
                }
            }

            hairline

            actionCell(icon: "square.and.arrow.up", label: "Share") {
                shareRestaurant()
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
    }

    @ViewBuilder
    private func actionCell(
        icon:        String,
        label:       String,
        highlighted: Bool = false,
        action:      @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(
                        highlighted ? AppColors.accent : AppColors.textPrimary
                    )
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        highlighted ? AppColors.accent : AppColors.textSecondary
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .buttonStyle(PressButtonStyle())
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color(white: 1, opacity: 0.07))
            .frame(width: 1, height: 38)
    }

    // MARK: - Shake again row

    private var shakeAgainRow: some View {
        Button {
            SoundPlayer.click()
            onShakeAgain()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
                    .rotationEffect(.degrees(spinRotation))
                    .animation(
                        .spring(response: 1.4, dampingFraction: 0.55),
                        value: spinRotation
                    )
                Text("Shake again")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
        }
        .buttonStyle(PressButtonStyle(scaleAmount: 0.97))
        .task {
            // Idle spin hint — rotates every few seconds to hint the button is interactive
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 3.5...6.0)))
                guard !Task.isCancelled else { break }
                spinRotation += 360
            }
        }
    }

    // MARK: - Actions

    private func checkFavoriteStatus() async {
        guard authManager.isSignedIn else { return }
        do {
            let favs = try await APIClient.shared.getFavorites()
            isFavorited = favs.contains { $0.placeID == restaurant.id }
        } catch {}
    }

    private func toggleFavorite() {
        guard authManager.isSignedIn else { return }
        SoundPlayer.click()
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
        SoundPlayer.click()
        let coordinate = CLLocationCoordinate2D(
            latitude:  restaurant.latitude,
            longitude: restaurant.longitude
        )
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = restaurant.name
        mapItem.openInMaps()
    }

    private func shareRestaurant() {
        SoundPlayer.click()
        let text = "Check out \(restaurant.name) — \(restaurant.address) 🍽️ Found with ShakeMeal!"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let root   = window.rootViewController else { return }
        root.present(av, animated: true)
    }
}

#Preview {
    RestaurantRevealView(restaurant: .mock) {}
        .environmentObject(AuthManager())
}
