import SwiftUI

struct ShakeView: View {
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var viewModel = ShakeViewModel(locationManager: LocationManager())

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                switch viewModel.state {
                case .idle:
                    IdleShakeView { viewModel.shake() }

                case .loading:
                    ShakeLoadingView()

                case .result(let restaurant):
                    RestaurantRevealView(restaurant: restaurant) {
                        viewModel.shakeAgain()
                    }

                case .error(let message):
                    ErrorView(message: message) { viewModel.shake() }
                }
            }
            .navigationTitle("ShakeMeal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isFilterPresented = true
                    } label: {
                        Image(systemName: viewModel.filter.isDefault
                              ? "slider.horizontal.3"
                              : "slider.horizontal.3")
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

// MARK: - Loading State
private struct ShakeLoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("🎲")
                .font(.system(size: 64))
                .rotationEffect(.degrees(rotation))
                .animation(.linear(duration: 0.4).repeatForever(autoreverses: false),
                           value: rotation)
                .onAppear { rotation = 360 }

            Text("Finding something delicious...")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

// MARK: - Error State
private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.warning)

            Text(message)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
        }
    }
}

#Preview {
    ShakeView()
        .environmentObject(LocationManager())
}
