import AVFoundation
import AudioToolbox
import UIKit

// MARK: - Sound player

enum SoundPlayer {
    // Single shared instance — engine + sampler are expensive to create.
    private static let piano = PianoNote()

    /// Piano note click: light haptic + Acoustic Grand Piano MIDI note.
    /// Respects the device silent switch (AVAudioSession.ambient category).
    static func click() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        piano.play()
    }
}

// MARK: - Piano note engine

private final class PianoNote {
    private let engine  = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private var ready   = false

    init() {
        // .ambient: plays alongside other audio and respects the silent switch
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        do {
            try engine.start()
            // iOS built-in General MIDI soundfont (stable since iOS 7)
            let dls = URL(fileURLWithPath:
                "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
            // program 0 = Acoustic Grand Piano, bankMSB 0x79 = melodic bank
            try sampler.loadSoundBankInstrument(at: dls, program: 0, bankMSB: 0x79, bankLSB: 0)
            ready = true
        } catch {
            // Silently degrade — no crash if soundfont is unavailable
        }
    }

    /// Play MIDI note 72 (C5) — bright, clear piano "ding".
    func play(note: UInt8 = 72, velocity: UInt8 = 85) {
        guard ready else { return }
        if !engine.isRunning { try? engine.start() }
        sampler.startNote(note, withVelocity: velocity, onChannel: 0)
        // Release after 0.5 s — short enough for a tap, long enough to hear the tone
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.sampler.stopNote(note, onChannel: 0)
        }
    }
}
