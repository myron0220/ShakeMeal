import SwiftUI

struct FilterView: View {
    @Binding var filter: ShakeFilter
    @Environment(\.dismiss) private var dismiss

    private let radii = [500, 1000, 2000, 5000]
    private let radiusLabels = ["500m", "1km", "2km", "5km"]

    var body: some View {
        NavigationStack {
            Form {
                // Radius
                Section("Search Radius") {
                    Picker("Radius", selection: $filter.radiusMeters) {
                        ForEach(Array(zip(radii, radiusLabels)), id: \.0) { value, label in
                            Text(label).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(.init(top: 12, leading: 16, bottom: 12, trailing: 16))
                }

                // Cuisine
                Section("Cuisine (optional)") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
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
                                    Text(cuisine.rawValue).font(.caption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selected ? AppColors.primary : AppColors.card,
                                            in: .capsule)
                                .foregroundStyle(selected ? .white : AppColors.textPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowInsets(.init(top: 12, leading: 16, bottom: 12, trailing: 16))
                }

                // Price Level
                Section("Price Range (optional)") {
                    HStack(spacing: 12) {
                        ForEach(1...4, id: \.self) { level in
                            let selected = filter.priceLevels.contains(level)
                            Button(String(repeating: "$", count: level)) {
                                if selected {
                                    filter.priceLevels.removeAll { $0 == level }
                                } else {
                                    filter.priceLevels.append(level)
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(selected ? AppColors.primary : .secondary)
                        }
                    }
                    .listRowInsets(.init(top: 12, leading: 16, bottom: 12, trailing: 16))
                }

                // Reset
                Section {
                    Button("Reset Filters", role: .destructive) {
                        filter = .default
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    FilterView(filter: .constant(.default))
}
