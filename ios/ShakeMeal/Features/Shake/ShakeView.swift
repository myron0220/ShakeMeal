import SwiftUI

struct ShakeView: View {
    @EnvironmentObject var viewModel: ShakeViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                switch viewModel.state {
                case .idle:
                    IdleShakeView { viewModel.shake() }
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))

                case .loading:
                    ShakeLoadingView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.85)),
                            removal: .opacity.combined(with: .scale(scale: 1.1))
                        ))

                case .result(let restaurant):
                    RestaurantRevealView(restaurant: restaurant) {
                        viewModel.shakeAgain()
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))

                case .error(let message):
                    ErrorView(message: message) { viewModel.shake() }
                        .transition(.opacity)
                }
            }
            .navigationTitle("ShakeMeal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                }
            }
            .sheet(isPresented: $viewModel.isFilterPresented) {
                FilterView(filter: $viewModel.filter)
            }
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

            Button(action: onShake) {
                Label("Shake Now", systemImage: "hand.tap.fill")
                    .font(AppFonts.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primary, in: .capsule)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Loading State  (dice rolling animation)
private struct ShakeLoadingView: View {
    private let faces = ["⚀", "⚁", "⚂", "⚃", "⚄", "⚅"]
    private let phaseDuration = 0.15  // seconds per face

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // TimelineView is purely time-driven: always renders, no
            // initialization gap, no opacity fade between faces.
            TimelineView(.animation(minimumInterval: phaseDuration)) { context in
                let t      = context.date.timeIntervalSinceReferenceDate
                let total  = phaseDuration * Double(faces.count)   // 0.9 s / cycle
                let pos    = (t / phaseDuration).truncatingRemainder(dividingBy: Double(faces.count))
                let idx    = Int(pos) % faces.count
                let frac   = pos - Double(Int(pos))                // 0…1 within this phase
                let deg    = Double(idx) * 60 + frac * 60          // smooth rotation
                // scale bounces 1.0 → 1.18 → 1.0 once per phase (sine curve)
                let scale  = 1.0 + 0.18 * sin(frac * .pi)
                let _      = total   // suppress unused-variable warning

                Text(faces[idx])
                    .font(.system(size: 80))
                    .rotationEffect(.degrees(deg))
                    .scaleEffect(scale)
            }

            VStack(spacing: 8) {
                Text("Rolling the dice...")
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
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    ShakeView()
        .environmentObject(ShakeViewModel(locationManager: LocationManager()))
}
