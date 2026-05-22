import SwiftUI

enum AppColors {
    // Brand
    static let primary       = Color(red: 1.0,  green: 0.341, blue: 0.133) // #FF5722

    // Backgrounds — adapts to light/dark mode
    static let background    = Color(UIColor.systemGroupedBackground)
    static let card          = Color(UIColor.secondarySystemGroupedBackground)

    // Text
    static let textPrimary   = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)

    // Accents
    static let star          = Color.yellow
    static let warning       = Color.orange
}

/*
 When you're ready to support custom dark-mode colors, add these
 to Assets.xcassets and switch back to Color("Name") lookups:

 Primary       Light: #FF5722   Dark: #FF6D42
 Background    Light: #F9F6F2   Dark: #1C1C1E
 Card          Light: #FFFFFF   Dark: #2C2C2E
*/
