import AudioToolbox
import UIKit
import SwiftUI

// MARK: - Sound player

enum SoundPlayer {
    /// Nintendo Switch–style menu click: light haptic + crisp system tick.
    static func click() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        AudioServicesPlaySystemSound(1057)
    }
}

// MARK: - Press button style

/// "Console button feel" — buttons spring down on press and snap back on release.
///
/// Every tap target should have a tactile scale response; this is the
/// primary reason Switch / PS5 / Apple TV buttons feel physical.
///
/// Usage:
///   Button { ... } label: { ... }
///       .buttonStyle(PressButtonStyle())
struct PressButtonStyle: ButtonStyle {
    /// How far the button shrinks on press (default 0.94)
    var scaleAmount: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(
                // Fast compress (responsive), spring release (physical)
                .spring(response: 0.22, dampingFraction: 0.62),
                value: configuration.isPressed
            )
    }
}
