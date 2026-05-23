import SwiftUI

struct HistoryView: View {
    // TODO: Replace with real ViewModel + persistence
    private let mockHistory = Restaurant.mockList

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                Group {
                    if mockHistory.isEmpty {
                        emptyState
                    } else {
                        List(mockHistory) { restaurant in
                            RestaurantRow(restaurant: restaurant)
                                .listRowBackground(AppColors.surface)
                                .listRowSeparatorTint(AppColors.textTertiary)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.surface.opacity(0.95), for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.textTertiary)
            Text("No shakes yet")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            Text("Your shake history will appear here.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

#Preview { HistoryView() }
