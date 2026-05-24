import SwiftUI
import Combine

// MARK: - Ring State ViewModel (shared between RestaurantRevealView and ShakeLoadingView)

@MainActor
final class RingViewModel: ObservableObject {
    @Published var baseRotation: Double = 0
    @Published var pressAngle: Double = 0      // negative = CCW while held
    @Published var isPressing: Bool = false

    /// Absolute CCW degrees accumulated during last press — handed to loading view
    private(set) var releaseEnergy: Double = 0

    private var pressTask: Task<Void, Never>?

    var displayAngle: Double { baseRotation + pressAngle }

    // Called when the user begins pressing the ring
    func startPress() {
        guard !isPressing else { return }
        isPressing = true
        // Cancel any in-flight bounce spring.
        // +360 is visually identical to +0 (same rendered angle) but is a real
        // value change, so SwiftUI replaces the running spring with this
        // disabled transaction — the ring snaps to the same visual position
        // with no jump, and the spring stops fighting the CCW press.
        var tx = Transaction()
        tx.disablesAnimations = true
        withTransaction(tx) { baseRotation += 360 }
        pressTask?.cancel()
        pressTask = Task { [weak self] in
            // ~60°/s CCW → -1° per 16 ms
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 16_666_666)
                guard let self, !Task.isCancelled else { break }
                self.pressAngle -= 1.0
            }
        }
    }

    // Called when the user lifts their finger
    func endPress() {
        isPressing = false
        pressTask?.cancel()
        pressTask = nil
        // Capture energy before folding
        releaseEnergy = abs(pressAngle)
        // Fold pressAngle into baseRotation without animation
        var tx = Transaction()
        tx.disablesAnimations = true
        withTransaction(tx) {
            baseRotation += pressAngle
            pressAngle = 0
        }
    }

    // Called by the auto-bounce timer
    func autoBounce() {
        guard !isPressing else { return }
        baseRotation += 360
    }

    // Reset for a fresh result view
    func resetForResult() {
        var tx = Transaction()
        tx.disablesAnimations = true
        withTransaction(tx) {
            pressAngle = 0
        }
        // don't reset baseRotation — visual continuity
    }
}

// MARK: - ShakeView

struct ShakeView: View {
    @EnvironmentObject var viewModel: ShakeViewModel
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var ringVM = RingViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background layer — intentionally escapes safe areas so the
                // screen edges are filled even on notched / Dynamic Island devices.
                AppColors.background.ignoresSafeArea()

                // Content layer — clipped so the spring bounce on RestaurantRevealView
                // cannot visually overflow into the navigation bar above.
                ZStack {
                    switch viewModel.state {
                    case .idle:
                        IdleShakeView { viewModel.shake() }
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal: .opacity.combined(with: .scale(scale: 0.95))
                            ))

                    case .loading:
                        ShakeLoadingView(ringVM: ringVM)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.85)),
                                removal: .opacity.combined(with: .scale(scale: 1.1))
                            ))

                    case .result(let restaurant):
                        RestaurantRevealView(
                            restaurant: restaurant,
                            onShakeAgain: { viewModel.shakeAgain() },
                            ringVM: ringVM
                        )
                        // No .transition here — RestaurantRevealView drives its own
                        // entry animation via onAppear so the slide-up is guaranteed
                        // to fire even when ZStack's animation context is unreliable.
                        .transition(.opacity.animation(.easeOut(duration: 0.1)))
                        .onAppear { ringVM.resetForResult() }

                    case .error(let message):
                        ErrorView(message: message) { viewModel.shake() }
                            .transition(.opacity)
                    }
                }
                .clipped()
            }
            // Declarative animation: fires on every state change regardless of where
            // the mutation originates (async Task, gesture, timer). This is more
            // reliable than withAnimation() calls inside the ViewModel.
            .animation(.spring(response: 0.45, dampingFraction: 0.78), value: viewModel.state)
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.3), value: locationManager.placeName)
            .toolbar {
                // ── Location header (leading) ───────────────────────────────
                ToolbarItem(placement: .topBarLeading) {
                    locationTitle
                        .padding(.bottom, 20)
                }
                // ── Filter (trailing) ───────────────────────────────────────
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isFilterPresented = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(viewModel.filter.isDefault
                                             ? AppColors.textSecondary
                                             : AppColors.primary)
                    }
                    .padding(.bottom, 20)
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
            // Has address — show "Near you" + street, both left-aligned
            VStack(alignment: .leading, spacing: 1) {
                Text("Near you")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)

                HStack(spacing: 3) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppColors.primary)
                    Text(name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            // Cap at ~1/3 of screen width so long addresses truncate cleanly
            .frame(maxWidth: UIScreen.main.bounds.width / 3, alignment: .leading)
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        } else if locationManager.hasPermission {
            // Permission granted but geocode not yet ready
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
            // No permission — plain app name
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

            Text("🍜")
                .font(.system(size: 80))
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                           value: isAnimating)
                .onAppear { isAnimating = true }

            VStack(spacing: 8) {
                Text("Shake for a meal")
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Can't decide? Let us pick for you.")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                SoundPlayer.click()
                onShake()
            } label: {
                Label("Shake Now", systemImage: "hand.tap.fill")
                    .font(AppFonts.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primary, in: .capsule)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 80)
        }
    }
}

// MARK: - Loading State
struct ShakeLoadingView: View {
    @ObservedObject var ringVM: RingViewModel
    @State private var steadyRotation: Double = 0
    @State private var burstRotation: Double = 0
    @State private var burstDone: Bool = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Arc ring — continues from where the press left off, then spins CW
            Circle()
                .trim(from: 0.0, to: 0.9382)
                .stroke(AppColors.primary,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 80, height: 80)
                .frame(maxWidth: .infinity)
                .rotationEffect(.degrees(ringVM.baseRotation + burstRotation + steadyRotation))
                .onAppear {
                    let energy = ringVM.releaseEnergy   // degrees accumulated during press
                    let burstDeg = max(energy * 3.0, 360.0)  // at least one full spin CW
                    let burstDuration = burstDeg / 720.0      // 720°/s initial burst speed
                    let burstDurationClamped = max(burstDuration, 0.3)

                    // Phase 1: fast burst proportional to press energy
                    withAnimation(.easeOut(duration: burstDurationClamped)) {
                        burstRotation = burstDeg
                    }
                    // Phase 2: steady continuous spin after burst settles
                    DispatchQueue.main.asyncAfter(deadline: .now() + burstDurationClamped * 0.7) {
                        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                            steadyRotation = 360
                        }
                    }
                }

            VStack(spacing: 8) {
                Text("Exploring...")
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Finding something delicious nearby")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Invisible placeholder keeps layout height identical to IdleShakeView
            Color.clear
                .frame(height: 56 + 40)
                .padding(.horizontal, 32)
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
                    .foregroundStyle(AppColors.warning)

                Text(message)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button(action: onRetry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(AppFonts.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primary, in: .capsule)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    let lm = LocationManager()
    return ShakeView()
        .environmentObject(ShakeViewModel(locationManager: lm))
        .environmentObject(lm)
}
