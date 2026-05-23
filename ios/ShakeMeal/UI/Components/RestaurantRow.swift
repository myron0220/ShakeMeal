import SwiftUI

struct RestaurantRow: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: restaurant.photoURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    AppColors.surfaceHigh
                        .overlay { Text("🍽️").font(.system(size: 20)).opacity(0.5) }
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(.rect(cornerRadius: 8))

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(restaurant.name)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)

                Text(restaurant.cuisine)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)

                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(AppColors.star)
                        Text(String(format: "%.1f", restaurant.rating))
                            .font(AppFonts.meta)
                            .foregroundStyle(AppColors.textPrimary)
                    }

                    Text("·").foregroundStyle(AppColors.textTertiary)

                    Text(restaurant.priceDisplay)
                        .font(AppFonts.meta)
                        .foregroundStyle(AppColors.textSecondary)

                    if !restaurant.distanceDisplay.isEmpty {
                        Text("·").foregroundStyle(AppColors.textTertiary)
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
        .background(AppColors.surface)
}
