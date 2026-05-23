import AudioToolbox
import UIKit

// MARK: - Sound player

enum SoundPlayer {
    /// Nintendo Switch–style menu click: light haptic + crisp system tick.
    static func click() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        AudioServicesPlaySystemSound(1057)
    }
}
