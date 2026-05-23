import AVFoundation
import UIKit

// MARK: - Sound player

enum SoundPlayer {
    private static let chime = ChimePlayer()

    /// Crisp bell-like tap: light haptic + synthesised two-tone chime with a
    /// natural decay tail (~350 ms audible) — similar to Nintendo Switch UI sounds.
    /// Respects the device silent switch via AVAudioSession.ambient.
    static func click() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        chime.play()
    }
}

// MARK: - Chime synthesiser

/// Pre-renders a PCM buffer at init time, then plays it instantly on every tap.
/// Two sine waves + exponential decay → bright attack with a clean tail.
private final class ChimePlayer {
    private let engine     = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var buffer: AVAudioPCMBuffer?

    init() {
        // .ambient: plays alongside music, silenced by the hardware mute switch
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        let sampleRate: Double  = 44100
        let duration:   Double  = 0.7        // 700 ms — enough room for the tail
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buf.frameLength = frameCount
        let samples = buf.floatChannelData![0]

        // A5 (880 Hz) + E6 (1320 Hz) — fundamental + perfect-fifth overtone
        // Gives the warm-but-crisp character of Switch UI sounds
        let f1: Double = 880    // fundamental — brightness
        let f2: Double = 1320   // overtone — adds body
        let decay: Double = 7.0 // exp decay; ~50 % amplitude at 100 ms, tail audible ~350 ms
        let gain: Float = 0.38  // moderate — present without being sharp

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(exp(-decay * t))
            let wave     = Float(0.7 * sin(2 * .pi * f1 * t) +
                                 0.3 * sin(2 * .pi * f2 * t))
            samples[i] = wave * envelope * gain
        }

        buffer = buf
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
            playerNode.play()
        } catch { /* degrades silently */ }
    }

    func play() {
        guard let buf = buffer else { return }
        if !engine.isRunning { try? engine.start() }
        // Schedule without stopping so rapid taps blend naturally
        playerNode.scheduleBuffer(buf)
    }
}
