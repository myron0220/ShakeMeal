import SwiftUI

struct FavoritesView: View {
    // TODO: Replace with real ViewModel + persistence
    private let mockFavorites: [Restaurant] = []

    var body: some View {
        NavigationStack {
            Group {
                if mockFavorites.isEmpty {
                    emptyState
                } else {
                    List(mockFavorites) { restaurant in
                        RestaurantRow(restaurant: restaurant)
                            .listRowBackground(AppColors.card)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Favorites")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary)
            Text("No favorites yet")
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textPrimary)
            Text("Heart a restaurant after shaking to save it here.")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview { FavoritesView() }
