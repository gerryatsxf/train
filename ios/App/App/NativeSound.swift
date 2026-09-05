import Foundation
import AVFoundation
import CoreHaptics
import UIKit
import Capacitor

/// Reproduce los avisos fuera del WebView. Es la única forma de sonar a volumen multimedia,
/// ignorando el switch de silencio, y a la vez mezclarse con la música de otras apps:
/// cuando WebKit reproduce audio se apodera de la sesión y solo ofrece una de las dos cosas.
@objc(NativeSoundPlugin)
public class NativeSoundPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativeSoundPlugin"
    public let jsName = "NativeSound"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "play", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "haptic", returnType: CAPPluginReturnPromise)
    ]

    private let synth = ToneSynth()

    @objc func play(_ call: CAPPluginCall) {
        NativeSoundPlugin.ensureMixableSession()
        let parts = call.getArray("parts", JSObject.self) ?? []
        synth.play(parts.map { Part(from: $0) })
        call.resolve()
    }

    /// Se reafirma antes de cada sonido: si WebKit u otra app reescribió la categoría,
    /// sin `mixWithOthers` la app y la música de otras apps se expulsan mutuamente.
    static func ensureMixableSession() {
        let s = AVAudioSession.sharedInstance()
        if s.category != .playback || !s.categoryOptions.contains(.mixWithOthers) {
            try? s.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        }
        try? s.setActive(true)
    }

    @objc func haptic(_ call: CAPPluginCall) {
        let kind = call.getString("kind") ?? "light"
        DispatchQueue.main.async {
            switch kind {
            case "strong":
                // fin del descanso: patrón largo de Core Haptics, lo más fuerte disponible
                Rumble.shared.burst(pulses: 4, spacing: 0.32, duration: 0.24)
            case "warning":
                Rumble.shared.burst(pulses: 2, spacing: 0.22, duration: 0.14)
            case "success":
                let hit = UIImpactFeedbackGenerator(style: .heavy)
                hit.prepare()
                hit.impactOccurred(intensity: 1.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            case "medium":
                let hit = UIImpactFeedbackGenerator(style: .medium)
                hit.prepare()
                hit.impactOccurred(intensity: 1.0)
            default:
                // 'rigid' es más seco y se percibe más fuerte que 'light' a igual intensidad
                let hit = UIImpactFeedbackGenerator(style: .rigid)
                hit.prepare()
                hit.impactOccurred(intensity: 1.0)
            }
        }
        call.resolve()
    }
}

/// Vibración larga con Core Haptics: los generadores de impacto solo dan golpes puntuales,
/// esto permite pulsos sostenidos a intensidad máxima, que es lo que se siente como alarma.
final class Rumble {
    static let shared = Rumble()
    private var engine: CHHapticEngine?

    func burst(pulses: Int, spacing: Double, duration: Double) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return fallback(pulses: pulses, spacing: spacing)
        }
        do {
            if engine == nil {
                engine = try CHHapticEngine()
                engine?.isAutoShutdownEnabled = true
                engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
                engine?.stoppedHandler = { _ in }
            }
            try engine?.start()

            var events: [CHHapticEvent] = []
            for i in 0..<pulses {
                let t = Double(i) * spacing
                events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ], relativeTime: t))
                events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.55)
                ], relativeTime: t + 0.015, duration: duration))
            }
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallback(pulses: pulses, spacing: spacing)
        }
    }

    private func fallback(pulses: Int, spacing: Double) {
        let hit = UIImpactFeedbackGenerator(style: .heavy)
        hit.prepare()
        for i in 0..<pulses {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * spacing) {
                hit.impactOccurred(intensity: 1.0)
            }
        }
    }
}

/// Un parcial del sonido, con el mismo vocabulario que la tabla SFX del HTML.
struct Part {    let start: Double   // t
    let freq: Double    // f
    let dur: Double     // d
    let gain: Double    // g
    let wave: String    // w: sine | triangle | square
    let noise: Bool     // k === "n"

    init(from js: JSObject) {
        start = js["t"] as? Double ?? 0
        freq  = js["f"] as? Double ?? 440
        dur   = js["d"] as? Double ?? 0.1
        gain  = js["g"] as? Double ?? 0.3
        wave  = js["w"] as? String ?? "sine"
        noise = (js["k"] as? String) == "n"
    }
}

/// Sintetiza el sonido en un buffer PCM y lo suelta por AVAudioEngine.
/// La receta vive en el HTML: aquí solo se ejecuta, así no hay que duplicar el diseño sonoro.
final class ToneSynth {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    private let queue = DispatchQueue(label: "train.tonesynth")

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func play(_ parts: [Part]) {
        guard !parts.isEmpty else { return }
        queue.async { [weak self] in
            guard let self = self, let buffer = self.render(parts) else { return }
            do {
                if !self.engine.isRunning { try self.engine.start() }
                if !self.player.isPlaying { self.player.play() }
                self.player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            } catch {
                return
            }
        }
    }

    private func render(_ parts: [Part]) -> AVAudioPCMBuffer? {
        let sr = format.sampleRate
        let total = (parts.map { $0.start + $0.dur }.max() ?? 0) + 0.02
        let frames = AVAudioFrameCount(total * sr)
        guard frames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let data = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames
        for i in 0..<Int(frames) { data[i] = 0 }

        for part in parts {
            let offset = Int(part.start * sr)
            let count = Int(part.dur * sr)
            guard count > 0 else { continue }
            var filter = Biquad(bandpass: part.freq, sampleRate: sr, q: 1.2)
            var phase = 0.0
            let step = 2 * Double.pi * part.freq / sr

            for n in 0..<count {
                let index = offset + n
                if index >= Int(frames) { break }
                let progress = Double(n) / Double(count)
                // ataque muy corto y caída exponencial, igual que el envelope del WebAudio
                let attack = min(1, progress / 0.06)
                let envelope = attack * pow(1 - progress, 2.2)

                var sample: Double
                if part.noise {
                    sample = filter.process(Double.random(in: -1...1))
                } else {
                    switch part.wave {
                    case "square":   sample = sin(phase) >= 0 ? 0.7 : -0.7
                    case "triangle": sample = 2 / Double.pi * asin(sin(phase))
                    default:         sample = sin(phase)
                    }
                    phase += step
                }
                data[index] += Float(sample * envelope * part.gain)
            }
        }

        // limitador suave: evita recorte cuando varios parciales se solapan
        for i in 0..<Int(frames) { data[i] = tanh(data[i] * 1.4) * 0.9 }
        return buffer
    }
}

/// Biquad mínimo, solo para el componente de ruido de los clics.
struct Biquad {
    private var b0 = 0.0, b1 = 0.0, b2 = 0.0, a1 = 0.0, a2 = 0.0
    private var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0

    init(bandpass freq: Double, sampleRate: Double, q: Double) {
        let w0 = 2 * Double.pi * freq / sampleRate
        let alpha = sin(w0) / (2 * q)
        let a0 = 1 + alpha
        b0 = alpha / a0
        b1 = 0
        b2 = -alpha / a0
        a1 = (-2 * cos(w0)) / a0
        a2 = (1 - alpha) / a0
    }

    mutating func process(_ x: Double) -> Double {
        let y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1; x1 = x
        y2 = y1; y1 = y
        return y
    }
}
