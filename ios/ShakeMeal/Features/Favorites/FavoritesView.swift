import SwiftUI

struct FavoritesView: View {
    // TODO: Replace with real ViewModel + persistence
    private let mockFavorites: [Restaurant] = []

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                Group {
                    if mockFavorites.isEmpty {
                        emptyState
                    } else {
                        List(mockFavorites) { restaurant in
                            RestaurantRow(restaurant: restaurant)
                                .listRowBackground(AppColors.surface)
                                .listRowSeparatorTint(AppColors.textTertiary)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.surface.opacity(0.95), for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.textTertiary)
            Text("No favorites yet")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            Text("Heart a restaurant after shaking\nto save it here.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

#Preview { FavoritesView() }
