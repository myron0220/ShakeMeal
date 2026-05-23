import SwiftUI

struct FilterView: View {
    @Binding var filter: ShakeFilter
    @Environment(\.dismiss) private var dismiss

    private let radii       = [500, 1000, 2000, 5000]
    private let radiusLabels = ["500 m", "1 km", "2 km", "5 km"]

    var body: some View {
        NavigationStack {
            // Scrollable dark-background form
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    radiusSection
                    cuisineSection
                    priceSection
                    resetSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.surface.opacity(0.95), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
    }

    // MARK: - Radius

    private var radiusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Search Radius")

            HStack(spacing: 8) {
                ForEach(Array(zip(radii, radiusLabels)), id: \.0) { value, label in
                    let selected = filter.radiusMeters == value
                    Button {
                        filter.radiusMeters = value
                    } label: {
                        Text(label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(selected ? AppColors.background : AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                selected ? AppColors.accent : AppColors.surfaceHigh,
                                in: .capsule
                            )
                    }
                    .buttonStyle(PressButtonStyle())
                }
            }
        }
    }

    // MARK: - Cuisine

    private var cuisineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Cuisine")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 95))], spacing: 8) {
                ForEach(CuisineType.allCases) { cuisine in
                    let selected = filter.cuisines.contains(cuisine.rawValue)
                    Button {
                        if selected {
                            filter.cuisines.removeAll { $0 == cuisine.rawValue }
                        } else {
                            filter.cuisines.append(cuisine.rawValue)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(cuisine.emoji)
                                .font(.system(size: 14))
                            Text(cuisine.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(selected ? AppColors.background : AppColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background(
                            selected ? AppColors.accent : AppColors.surfaceHigh,
                            in: .capsule
                        )
                    }
                    .buttonStyle(PressButtonStyle())
                }
            }
        }
    }

    // MARK: - Price

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Price Range")

            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { level in
                    let selected = filter.priceLevels.contains(level)
                    Button {
                        if selected {
                            filter.priceLevels.removeAll { $0 == level }
                        } else {
                            filter.priceLevels.append(level)
                        }
                    } label: {
                        Text(String(repeating: "$", count: level))
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(selected ? AppColors.background : AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                selected ? AppColors.accent : AppColors.surfaceHigh,
                                in: .capsule
                            )
                    }
                    .buttonStyle(PressButtonStyle())
                }
            }
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                filter = .default
            }
        } label: {
            Text("Reset Filters")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.surfaceHigh, in: .capsule)
        }
        .buttonStyle(PressButtonStyle())
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppColors.textTertiary)
            .tracking(1.2)
    }
}

#Preview {
    FilterView(filter: .constant(.default))
}
