import SwiftUI
import Combine

struct ShakeView: View {
    @EnvironmentObject var viewModel: ShakeViewModel
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        NavigationStack {
            ZStack {
                // Background layer — escapes safe areas so screen edges are filled.
                AppColors.background.ignoresSafeArea()

                // Content layer — clipped so spring-bounce on RestaurantRevealView
                // cannot overflow into the navigation bar above.
                ZStack {
                    switch viewModel.state {
                    case .idle:
                        IdleShakeView { viewModel.shake() }
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal:   .opacity.combined(with: .scale(scale: 0.95))
                            ))

                    case .loading:
                        ShakeLoadingView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.85)),
                                removal:   .opacity.combined(with: .scale(scale: 1.1))
                            ))

                    case .result(let restaurant):
                        RestaurantRevealView(restaurant: restaurant) {
                            viewModel.shakeAgain()
                        }
                        .transition(.opacity.animation(.easeOut(duration: 0.1)))

                    case .error(let message):
                        ErrorView(message: message) { viewModel.shake() }
                            .transition(.opacity)
                    }
                }
                .clipped()
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.78), value: viewModel.state)
            .navigationBarTitleDisplayMode(.inline)
            // Transparent nav bar so the dark background bleeds through seamlessly
            .toolbarBackground(.hidden, for: .navigationBar)
            .animation(.easeInOut(duration: 0.3), value: locationManager.placeName)
            .toolbar {
                // ── Location header (leading) ────────────────────────
                ToolbarItem(placement: .topBarLeading) {
                    locationTitle
                }
                // ── Filter (trailing) ────────────────────────────────
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isFilterPresented = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(viewModel.filter.isDefault
                                             ? AppColors.textSecondary
                                             : AppColors.accent)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isFilterPresented) {
                FilterView(filter: $viewModel.filter)
            }
        }
    }

    // MARK: - Location title

    @ViewBuilder
    private var locationTitle: some View {
        if let name = locationManager.placeName {
            VStack(alignment: .leading, spacing: 1) {
                Text("Near you")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                HStack(spacing: 3) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppColors.accent)
                    Text(name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width / 3, alignment: .leading)
            .transition(.opacity.combined(with: .scale(scale: 0.9)))

        } else if locationManager.hasPermission {
            VStack(alignment: .leading, spacing: 1) {
                Text("Near you")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                Text("Locating…")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .transition(.opacity)

        } else {
            Text("ShakeMeal")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .transition(.opacity)
        }
    }
}

// MARK: - Idle State

private struct IdleShakeView: View {
    let onShake: () -> Void
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Emoji with gentle breath + subtle white glow
            Text("🍜")
                .font(.system(size: 96))
                .shadow(color: .white.opacity(0.12), radius: 24)
                .scaleEffect(isAnimating ? 1.08 : 1.0)
                .animation(
                    .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear { isAnimating = true }

            VStack(spacing: 10) {
                Text("Shake for a meal")
                    .font(.system(size: 28, weight: .semibold, design: .default))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Can't decide? Let us pick.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Primary CTA — white capsule, dark text (inverted: high-contrast on dark bg)
            Button {
                SoundPlayer.click()
                onShake()
            } label: {
                Label("Shake Now", systemImage: "hand.tap.fill")
                    .font(AppFonts.button)
                    .foregroundStyle(AppColors.background)   // dark text on white pill
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(AppColors.accent, in: .capsule)
            }
            .buttonStyle(PressButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 80)
        }
    }
}

// MARK: - Dice animation model

@MainActor
private final class DiceRollModel: ObservableObject {
    let faces = ["die.face.1", "die.face.2", "die.face.3",
                 "die.face.4", "die.face.5", "die.face.6"]
    @Published private(set) var faceIndex: Int   = 0
    @Published private(set) var rotation: Double = 0
    @Published private(set) var scale: CGFloat   = 1.0

    private var cancellable: AnyCancellable?

    func start() {
        cancellable = Timer.publish(every: 0.15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.faceIndex = (self.faceIndex + 1) % self.faces.count
                self.rotation += 60
                self.scale = self.scale == 1.0 ? 1.18 : 1.0
            }
    }

    func stop() {
        cancellable?.cancel()
        cancellable = nil
    }
}

// MARK: - Loading State

private struct ShakeLoadingView: View {
    @StateObject private var model = DiceRollModel()

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: model.faces[model.faceIndex])
                .font(.system(size: 80))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppColors.textPrimary)     // white dice on dark bg
                .rotationEffect(.degrees(model.rotation))
                .animation(.interpolatingSpring(stiffness: 280, damping: 14), value: model.rotation)
                .scaleEffect(model.scale)
                .animation(.interpolatingSpring(stiffness: 280, damping: 14), value: model.scale)
                .contentTransition(.identity)
                .onAppear   { model.start() }
                .onDisappear { model.stop() }

            VStack(spacing: 8) {
                Text("Rolling the dice…")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Finding something delicious nearby")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Invisible placeholder mirrors IdleShakeView button height so the
            // layout doesn't shift during the idle → loading transition.
            Color.clear
                .frame(height: 54 + 40)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Error State

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColors.textSecondary)

                Text(message)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Same inverted capsule style as the Shake Now button
            Button(action: onRetry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(AppFonts.button)
                    .foregroundStyle(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(AppColors.accent, in: .capsule)
            }
            .buttonStyle(PressButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    let lm = LocationManager()
    return ShakeView()
        .environmentObject(ShakeViewModel(locationManager: lm))
        .environmentObject(lm)
}
