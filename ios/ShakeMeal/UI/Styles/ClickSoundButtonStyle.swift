import AVFoundation
import AudioToolbox
import UIKit

// MARK: - Sound player

enum SoundPlayer {
    private static let chime = ChimePlayer()

    /// Instant tap sound + light haptic.
    /// Target latency ≤ 5 ms — same session config Nintendo-style UIs rely on.
    static func click() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        chime.play()
    }
}

// MARK: - Low-latency chime engine

/// Design goals
/// ─────────────
/// • AVAudioEngine + AVAudioPlayerNode  (not AVPlayer — too heavy)
/// • setPreferredIOBufferDuration(0.005) → ~5 ms I/O buffer (default is ~23 ms)
/// • Use hardware sample rate at runtime — avoids OS sample-rate conversion latency
/// • PCM buffer pre-rendered at init — play() is a single scheduleBuffer() call
///
/// To swap in a real WAV later (48 kHz / 24-bit .wav → bundle as .caf for CoreAudio):
///   1. Add the file to the Xcode target
///   2. Replace the `buildBuffer()` block with:
///        guard let url = Bundle.main.url(forResource: "click", withExtension: "caf"),
///              let file = try? AVAudioFile(forReading: url),
///              let buf  = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
///                                          frameCapacity: AVAudioFrameCount(file.length))
///        else { return nil }
///        try? file.read(into: buf)
///        return buf
private final class ChimePlayer {
    private let engine     = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var buffer: AVAudioPCMBuffer?

    init() {
        configureAudioSession()
        buffer = buildBuffer()
        guard buffer != nil else { return }

        engine.attach(playerNode)
        // Use the hardware format for the main mixer — avoids sample-rate conversion
        let hwFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(playerNode, to: engine.mainMixerNode, format: hwFormat)
        do {
            try engine.start()
            playerNode.play()          // pre-warm: node starts running before first tap
        } catch { /* degrades silently */ }
    }

    // MARK: Audio session

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        // .ambient: mixes with music, silenced by hardware mute switch
        try? session.setCategory(.ambient, mode: .default, options: .mixWithOthers)
        // 5 ms I/O buffer — critical for Nintendo-style instant response
        // (default ~23 ms is audibly late for a UI tap sound)
        try? session.setPreferredIOBufferDuration(0.005)
        try? session.setActive(true)
    }

    // MARK: Buffer synthesis

    private func buildBuffer() -> AVAudioPCMBuffer? {
        // Use the actual hardware sample rate to avoid OS resampling latency
        let sampleRate = AVAudioSession.sharedInstance().sampleRate.isZero
            ? 48000.0
            : AVAudioSession.sharedInstance().sampleRate

        let duration: Double = 0.30   // 300 ms — sound perceptually done by ~220 ms
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buf = AVAudioPCMBuffer(pcmFormat: format,
                                         frameCapacity: AVAudioFrameCount(sampleRate * duration))
        else { return nil }

        buf.frameLength = buf.frameCapacity
        let samples = buf.floatChannelData![0]

        // Two-note ascending "di-ding" — NS confirm-tap character
        //   Note 1  C6  1047 Hz  sharp punch    decay τ = 22
        //   Note 2  E6  1319 Hz  resonant tail  decay τ = 12, enters 22 ms later
        let f1: Double = 1047;  let decay1: Double = 22;  let g1: Float = 0.30
        let f2: Double = 1319;  let decay2: Double = 12;  let g2: Float = 0.24
        let offset = 0.022   // seconds before note 2 enters

        var ph1 = 0.0, ph2 = 0.0

        for i in 0..<Int(buf.frameLength) {
            let t = Double(i) / sampleRate

            // Note 1 — 3 ms attack ramp, then exponential decay
            let r1: Float = t < 0.003 ? Float(t / 0.003) : 1.0
            let n1 = Float(sin(2 * .pi * ph1)) * r1 * Float(exp(-decay1 * t)) * g1
            ph1 += f1 / sampleRate; if ph1 >= 1 { ph1 -= 1 }

            // Note 2 — enters at `offset`
            var n2: Float = 0
            if t >= offset {
                let t2 = t - offset
                let r2: Float = t2 < 0.003 ? Float(t2 / 0.003) : 1.0
                n2 = Float(sin(2 * .pi * ph2)) * r2 * Float(exp(-decay2 * t2)) * g2
                ph2 += f2 / sampleRate; if ph2 >= 1 { ph2 -= 1 }
            }

            samples[i] = n1 + n2
        }
        return buf
    }

    // MARK: Playback

    func play() {
        guard let buf = buffer else { return }
        if !engine.isRunning { try? engine.start() }
        playerNode.scheduleBuffer(buf)
    }
}
