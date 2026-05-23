import AVFoundation
import UIKit

// MARK: - Sound player

enum SoundPlayer {
    private static let chime = ChimePlayer()

    /// Nintendo Switch–style UI chirp: light haptic + fast upward frequency
    /// sweep that makes the app feel instant and responsive.
    static func click() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        chime.play()
    }
}

// MARK: - Chime synthesiser

private final class ChimePlayer {
    private let engine     = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var buffer: AVAudioPCMBuffer?

    init() {
        // .ambient: plays alongside music, silenced by the hardware mute switch
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        let sampleRate: Double = 44100
        let duration:   Double = 0.35       // 350 ms buffer (sound mostly done by 220 ms)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buf.frameLength = frameCount
        let samples = buf.floatChannelData![0]

        // ── Sound design ────────────────────────────────────────────────────
        // Frequency chirp: 800 Hz → 1100 Hz over the first 40 ms, then holds.
        // Upward glide gives the "quick & decisive" feeling of NS UI sounds.
        let freqStart:  Double = 800
        let freqEnd:    Double = 1100
        let chirpTime:  Double = 0.040  // 40 ms sweep
        let decay:      Double = 11.0   // fast decay; ~30 % at 100 ms, tail gone ~280 ms
        let gain:       Float  = 0.30   // moderate — not harsh

        var phase = 0.0  // continuous phase accumulator (prevents clicks at freq change)

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Smooth linear frequency ramp during chirp window
            let freq = t < chirpTime
                ? freqStart + (freqEnd - freqStart) * (t / chirpTime)
                : freqEnd

            // 3 ms soft attack to avoid onset click, then pure exponential decay
            let attackRamp = t < 0.003 ? Float(t / 0.003) : 1.0
            let envelope   = attackRamp * Float(exp(-decay * t))

            samples[i] = Float(sin(2 * .pi * phase)) * envelope * gain
            phase += freq / sampleRate
            if phase >= 1.0 { phase -= 1.0 }
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
        playerNode.scheduleBuffer(buf)
    }
}
