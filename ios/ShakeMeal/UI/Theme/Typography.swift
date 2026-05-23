import SwiftUI

/// SF Pro — clean, precise, console-appropriate.
///
/// Removed `.rounded` design from all weights.
/// `.rounded` reads as "friendly app"; `.default` (SF Pro) reads as
/// composed and premium — closer to PS5 / Apple TV / Notion.
enum AppFonts {
    static let title    = Font.system(.title2,      design: .default).weight(.semibold)
    static let heading  = Font.system(.title3,      design: .default).weight(.semibold)
    static let body     = Font.system(.body,        design: .default)
    static let bodyBold = Font.system(.body,        design: .default).weight(.semibold)
    static let button   = Font.system(.callout,     design: .default).weight(.medium)
    static let caption  = Font.system(.subheadline, design: .default)
    static let meta     = Font.system(.caption,     design: .default)
}
