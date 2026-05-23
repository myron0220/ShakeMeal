import SwiftUI
import Combine

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

// MARK: - Dice animation model
// Owned by @StateObject so it lives for exactly the lifetime of ShakeLoadingView —
// never recreated on re-renders, timer never drops.
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
                withAnimation(.interpolatingSpring(stiffness: 280, damping: 14)) {
                    self.faceIndex = (self.faceIndex + 1) % self.faces.count
                    self.rotation += 60
                    self.scale = self.scale == 1.0 ? 1.18 : 1.0
                }
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
                .foregroundStyle(AppColors.primary)
                .rotationEffect(.degrees(model.rotation))
                .scaleEffect(model.scale)
                .contentTransition(.identity)   // prevents SwiftUI cross-fade on symbol change
                .onAppear  { model.start() }
                .onDisappear { model.stop() }

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
