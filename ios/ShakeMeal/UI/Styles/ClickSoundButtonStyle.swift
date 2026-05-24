import AudioToolbox
import UIKit

// MARK: - Sound player

enum SoundPlayer {
    // Pre-register the system Tink sound at launch time so the OS buffers it.
    // AudioServicesPlaySystemSound(1057) looks the file up on every call and
    // can be silently dropped when the main thread is busy. A pre-registered
    // SystemSoundID is cached by the OS and fires reliably.
    private static let clickID: SystemSoundID = {
        var sid: SystemSoundID = 0
        let path = "/System/Library/Audio/UISounds/Tink.caf"
        let url = URL(fileURLWithPath: path) as CFURL
        let err = AudioServicesCreateSystemSoundID(url, &sid)
        return err == kAudioServicesNoError ? sid : 1057
    }()

    /// Nintendo Switch–style menu click: light haptic + crisp system tick.
    static func click() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        AudioServicesPlaySystemSound(clickID)
    }
}
