import SwiftUI

struct RestaurantRow: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: restaurant.photoURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                AppColors.primary.opacity(0.15)
                    .overlay { Text("🍽️") }
            }
            .frame(width: 56, height: 56)
            .clipShape(.rect(cornerRadius: 10))

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(restaurant.name)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)

                Text(restaurant.cuisine)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)

                HStack(spacing: 6) {
                    Label(String(format: "%.1f", restaurant.rating), systemImage: "star.fill")
                        .foregroundStyle(AppColors.star)
                        .font(AppFonts.meta)

                    Text("·").foregroundStyle(AppColors.textSecondary)

                    Text(restaurant.priceDisplay)
                        .font(AppFonts.meta)
                        .foregroundStyle(AppColors.textSecondary)

                    if !restaurant.distanceDisplay.isEmpty {
                        Text("·").foregroundStyle(AppColors.textSecondary)
                        Text(restaurant.distanceDisplay)
                            .font(AppFonts.meta)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RestaurantRow(restaurant: .mock)
        .padding()
}
