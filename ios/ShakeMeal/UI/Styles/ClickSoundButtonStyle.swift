import AVFoundation
import UIKit

// MARK: - Sound player

enum SoundPlayer {
    private static let chime = ChimePlayer()

    /// Nintendo Switch–style two-note "di-ding": light haptic + two ascending
    /// sine tones 22 ms apart — punchy note 1, resonant tail on note 2.
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
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        let sampleRate: Double = 44100
        let duration:   Double = 0.30        // 300 ms — sound done by ~220 ms
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buf.frameLength = frameCount
        let samples = buf.floatChannelData![0]

        // ── Sound design ────────────────────────────────────────────────────
        //
        //  Two ascending notes 22 ms apart — the "di-ding" signature of
        //  Nintendo Switch UI sounds.
        //
        //  Note 1  C6  1047 Hz  — sharp punch, fast decay   (τ = 22)
        //  Note 2  E6  1319 Hz  — softer, resonant tail      (τ = 12)
        //
        //  Both use a 3 ms linear attack ramp to prevent onset click.
        //  Phase is accumulated continuously so frequency sits cleanly
        //  on the waveform with no discontinuities.

        let f1: Double = 1047;  let decay1: Double = 22;  let gain1: Float = 0.30
        let f2: Double = 1319;  let decay2: Double = 12;  let gain2: Float = 0.24
        let noteOffset: Double = 0.022   // 22 ms between the two notes

        var phase1 = 0.0
        var phase2 = 0.0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Note 1 — present from t = 0
            let ramp1: Float = t < 0.003 ? Float(t / 0.003) : 1.0
            let n1 = Float(sin(2 * .pi * phase1)) * ramp1 * Float(exp(-decay1 * t)) * gain1
            phase1 += f1 / sampleRate
            if phase1 >= 1.0 { phase1 -= 1.0 }

            // Note 2 — enters at noteOffset
            var n2: Float = 0
            if t >= noteOffset {
                let t2 = t - noteOffset
                let ramp2: Float = t2 < 0.003 ? Float(t2 / 0.003) : 1.0
                n2 = Float(sin(2 * .pi * phase2)) * ramp2 * Float(exp(-decay2 * t2)) * gain2
                phase2 += f2 / sampleRate
                if phase2 >= 1.0 { phase2 -= 1.0 }
            }

            samples[i] = n1 + n2
        }

        buffer = buf
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        do { try engine.start(); playerNode.play() } catch {}
    }

    func play() {
        guard let buf = buffer else { return }
        if !engine.isRunning { try? engine.start() }
        playerNode.scheduleBuffer(buf)
    }
}
