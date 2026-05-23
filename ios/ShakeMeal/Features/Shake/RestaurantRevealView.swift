import SwiftUI
import MapKit

struct RestaurantRevealView: View {
    let restaurant: Restaurant
    let onShakeAgain: () -> Void

    @EnvironmentObject var authManager: AuthManager
    @State private var isFavorited = false
    @State private var favoriteLoading = false
    @State private var iconRotation: Double = 0
    @State private var pressAngle: Double = 0
    @State private var isPressing: Bool = false
    @State private var pressTask: Task<Void, Never>? = nil

    @State private var slideOffset: CGFloat = 600
    @State private var slideOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── 1. Full-screen photo background ───────────────────────
                photoBackground
                    .frame(width: geo.size.width, height: geo.size.height)

                // ── 2. Dark gradient overlay ──────────────────────────────
                LinearGradient(
                    colors: [.clear, .black.opacity(0.88)],
                    startPoint: .init(x: 0.5, y: 0.3),
                    endPoint: .bottom
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .allowsHitTesting(false)

                // ── 3. Content: info (bottom-left) + actions (bottom-right)
                VStack(spacing: 0) {
                    Spacer()

                    HStack(alignment: .bottom, spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            nameSection
                            metaRow
                        }
                        Spacer(minLength: 0)
                        actionColumn
                    }
                    .frame(width: geo.size.width - 40)  // explicit: screen - 20pt each side
                    .padding(.bottom, 24)

                    // Shake-again ring centred
                    shakeAgainButton
                        .padding(.bottom, 56)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
            }
        }
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

    // MARK: - Photo background

    private var photoBackground: some View {
        Group {
            if let url = restaurant.photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholderGradient
                    }
                }
                // ⚠️ Frame MUST be on AsyncImage itself — without it the view
                // reports the image's native pixel size (e.g. 800 px wide) and
                // inflates the ZStack, pushing all overlay content off-screen.
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            } else {
                placeholderGradient
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [AppColors.primary.opacity(0.7), AppColors.primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay { Text("🍽️").font(.system(size: 72)) }
    }

    // MARK: - Info (bottom-left)

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(restaurant.name)
                .font(AppFonts.heading)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.55), radius: 6, x: 0, y: 2)
                .overlay(alignment: .topTrailing) {
                    if restaurant.isOpen == true {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 3, height: 3)
                            .shadow(color: .black.opacity(0.35), radius: 2)
                            .offset(x: 10, y: 5)
                    }
                }
            Text(restaurant.address)
                .font(AppFonts.caption)
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
        }
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            Label(String(format: "%.1f", restaurant.rating), systemImage: "star.fill")
                .foregroundStyle(.white)
            Text("·").foregroundStyle(.white.opacity(0.6))
            Text(restaurant.priceDisplay).foregroundStyle(.white.opacity(0.9))
            Text("·").foregroundStyle(.white.opacity(0.6))
            Text(restaurant.cuisine).foregroundStyle(.white.opacity(0.9))
            if !restaurant.distanceDisplay.isEmpty {
                Text("·").foregroundStyle(.white.opacity(0.6))
                Text(restaurant.distanceDisplay).foregroundStyle(.white.opacity(0.9))
            }
        }
        .font(AppFonts.meta)
        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
    }

    // MARK: - Action column (bottom-right, TikTok style)

    private var actionColumn: some View {
        VStack(spacing: 28) {
            // Favorite
            Button { toggleFavorite() } label: {
                if favoriteLoading {
                    ProgressView().tint(.white).frame(width: 30, height: 30)
                } else {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(isFavorited ? Color.red : .white)
                        .shadow(color: .black.opacity(0.45), radius: 5)
                }
            }
            .disabled(favoriteLoading || !authManager.isSignedIn)

            // Share
            Button { shareRestaurant() } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 5)
            }

            // Directions
            Button { openInMaps() } label: {
                Image(systemName: "map.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 5)
            }
        }
    }

    // MARK: - Shake-again ring

    private var shakeAgainButton: some View {
        Button {
            SoundPlayer.click()
            onShakeAgain()
        } label: {
            Circle()
                .trim(from: 0.0, to: 0.9382)
                .stroke(.white,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .shadow(color: .black.opacity(0.45), radius: 6)
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(iconRotation + pressAngle))
                .animation(
                    .spring(response: 0.8, dampingFraction: 0.42),
                    value: iconRotation
                )
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressing else { return }
                    isPressing = true
                    pressTask?.cancel()
                    pressTask = Task { @MainActor in
                        while !Task.isCancelled {
                            try? await Task.sleep(nanoseconds: 16_666_666)
                            guard !Task.isCancelled else { break }
                            pressAngle += 1.0
                        }
                    }
                }
                .onEnded { _ in
                    isPressing = false
                    pressTask?.cancel()
                    pressTask = nil
                    var tx = Transaction()
                    tx.disablesAnimations = true
                    withTransaction(tx) {
                        iconRotation += pressAngle
                        pressAngle = 0
                    }
                }
        )
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 6.0...12.0)))
                guard !Task.isCancelled && !isPressing else { continue }
                iconRotation += 360
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
    RestaurantRevealView(restaurant: .mock) {}
        .environmentObject(AuthManager())
}
