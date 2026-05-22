import UIKit
import Combine

/// Publishes a signal every time a shake gesture is detected.
final class ShakeDetector {
    static let shared = ShakeDetector()

    private let subject = PassthroughSubject<Void, Never>()
    var publisher: AnyPublisher<Void, Never> { subject.eraseToAnyPublisher() }

    private init() {
        // Swizzle UIWindow to intercept shake events app-wide
        UIWindow.swizzleMotionEnded()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShake),
            name: .deviceDidShake,
            object: nil
        )
    }

    @objc private func handleShake() {
        subject.send()
    }
}

// MARK: - UIWindow Swizzle
extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

extension UIWindow {
    /// Intercepts motionEnded to broadcast a shake notification.
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }

    static func swizzleMotionEnded() {
        // UIWindow.motionEnded is already overridden above — no runtime swizzle needed.
    }
}
