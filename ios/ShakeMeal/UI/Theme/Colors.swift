import SwiftUI

/// Console-style dark palette — intentionally fixed (not system-adaptive).
///
/// Philosophy: large pure background, white accent, no orange.
/// Every surface is a shade of near-black; the sole interactive colour
/// is pure white. Think Nintendo Switch / PS5 / Apple TV.
///
/// To add light-mode support later: replace these statics with
/// DynamicMemberLookup / Color("AssetName") asset-catalogue entries.
enum AppColors {

    // ── Backgrounds ───────────────────────────────────────────────────
    /// Page / screen canvas — near black  (#0E0E0E)
    static let background  = Color(red: 0.055, green: 0.055, blue: 0.055)
    /// Elevated surfaces — action strips, list rows  (#1C1C1C)
    static let surface     = Color(red: 0.11,  green: 0.11,  blue: 0.11)
    /// High-elevation surfaces — chips, separators  (#323232)
    static let surfaceHigh = Color(red: 0.20,  green: 0.20,  blue: 0.20)

    // ── Text ──────────────────────────────────────────────────────────
    static let textPrimary   = Color.white
    static let textSecondary = Color(white: 1.0, opacity: 0.45)
    static let textTertiary  = Color(white: 1.0, opacity: 0.20)

    // ── Interactive accent — white on dark ────────────────────────────
    /// Primary interactive colour: pure white
    static let accent    = Color.white
    /// Ghost / dim fill behind icons / unselected chips
    static let accentDim = Color(white: 1.0, opacity: 0.08)

    // ── Semantic aliases (old names kept so existing call-sites compile)
    static var primary:  Color { accent }
    static var card:     Color { surface }
    static var star:     Color { Color(white: 1.0, opacity: 0.80) }
    static var warning:  Color { Color(white: 1.0, opacity: 0.60) }
}
