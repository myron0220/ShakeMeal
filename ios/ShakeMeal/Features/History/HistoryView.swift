import SwiftUI

struct HistoryView: View {
    // TODO: Replace with real ViewModel + persistence
    private let mockHistory = Restaurant.mockList

    var body: some View {
        NavigationStack {
            Group {
                if mockHistory.isEmpty {
                    emptyState
                } else {
                    List(mockHistory) { restaurant in
                        RestaurantRow(restaurant: restaurant)
                            .listRowBackground(AppColors.card)
                            .listRowSeparatorTint(AppColors.textSecondary.opacity(0.2))
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary)
            Text("No shakes yet!")
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textPrimary)
            Text("Your shake history will appear here.")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

#Preview { HistoryView() }
