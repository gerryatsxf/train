import Foundation
import AppIntents
import ActivityKit
import UserNotifications

/// Cola de descansos registrados desde la pantalla bloqueada. El intent corre en el proceso
/// de la app, así que basta con `UserDefaults.standard`: no hace falta App Group.
enum PendingRest {
    private static let key = "pendingRest"

    static func push(exId: String, setIndex: Int, week: Int, seconds: Int) {
        var all = UserDefaults.standard.array(forKey: key) as? [[String: Any]] ?? []
        all.append(["exId": exId, "set": setIndex, "week": week, "seconds": seconds])
        UserDefaults.standard.set(all, forKey: key)
    }

    static func drain() -> [[String: Any]] {
        let all = UserDefaults.standard.array(forKey: key) as? [[String: Any]] ?? []
        UserDefaults.standard.removeObject(forKey: key)
        return all
    }
}

/// Botón de la Live Activity. `LiveActivityIntent` se ejecuta en el proceso de la app
/// (la despierta si hace falta), por eso puede escribir en sus preferencias.
@available(iOS 17.0, *)
struct RegisterRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Registrar descanso"
    static var isDiscoverable: Bool = false
    /// Stored, no computed: el extractor de metadatos de App Intents lee el valor en tiempo de
    /// compilación y sin esto iOS aplica la política por defecto y pide Face ID.
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    /// Explícito: si el sistema trae la app al frente, el desbloqueo es inevitable.
    static var openAppWhenRun: Bool = false

    @Parameter(title: "exId") var exId: String
    @Parameter(title: "set") var setIndex: Int
    @Parameter(title: "week") var week: Int
    @Parameter(title: "startedAt") var startedAt: Date

    init() {}

    init(exId: String, setIndex: Int, week: Int, startedAt: Date) {
        self.exId = exId
        self.setIndex = setIndex
        self.week = week
        self.startedAt = startedAt
    }

    func perform() async throws -> some IntentResult {
        let seconds = max(0, Int(Date().timeIntervalSince(startedAt).rounded()))
        PendingRest.push(exId: exId, setIndex: setIndex, week: week, seconds: seconds)
        await cancelRestNotifications()
        await confirmOnActivity(seconds: seconds)
        return .result()
    }

    /// Prefijo con el mismo formato que restKey() en index.html: solo se retiran los avisos
    /// de esta serie, nunca los de un descanso nuevo.
    private func cancelRestNotifications() async {
        let prefix = "rest.\(week).\(exId).\(setIndex)."
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier)
        let delivered = await center.deliveredNotifications().map(\.request.identifier)
        center.removePendingNotificationRequests(withIdentifiers: pending.filter { $0.hasPrefix(prefix) })
        center.removeDeliveredNotifications(withIdentifiers: delivered.filter { $0.hasPrefix(prefix) })
    }

    /// La tarjeta no se cierra: pasa a "registrado" para que se vea que quedó guardado.
    private func confirmOnActivity(seconds: Int) async {
        guard #available(iOS 16.2, *) else { return }
        for activity in Activity<RestAttributes>.activities {
            var state = activity.content.state
            guard state.exId == exId, state.setIndex == setIndex, state.week == week else { continue }
            state.registered = true
            state.registeredSeconds = seconds
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }
}
