import Foundation
import Capacitor
import ActivityKit

/// Live Activity del descanso: aparece en la pantalla bloqueada y en la Isla Dinámica.
/// Necesita una extensión de widget en el proyecto; sin ella `Activity.request` lanza y
/// el plugin simplemente no hace nada.
@objc(LiveActivityPlugin)
public class LiveActivityPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LiveActivityPlugin"
    public let jsName = "LiveActivity"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "start", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stop", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pending", returnType: CAPPluginReturnPromise)
    ]

    private var current: Any?

    @objc func start(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else { return call.resolve(["ok": false, "reason": "iOS < 16.2"]) }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return call.resolve(["ok": false, "reason": "desactivadas en Ajustes"])
        }

        let seconds = call.getDouble("seconds") ?? 60
        let exercise = call.getString("exercise") ?? "Descanso"
        let setLabel = call.getString("set") ?? ""
        let now = Date()
        let state = RestAttributes.ContentState(
            endAt: now.addingTimeInterval(seconds),
            startedAt: now,
            exercise: exercise,
            setLabel: setLabel,
            exId: call.getString("exId") ?? "",
            setIndex: call.getInt("setIndex") ?? 0,
            week: call.getInt("week") ?? 0
        )

        endCurrent()
        do {
            let activity = try Activity.request(
                attributes: RestAttributes(title: "Descanso"),
                // al vencer, la tarjeta se marca obsoleta y cambia al estado "terminado"
                content: .init(state: state, staleDate: state.endAt),
                pushType: nil
            )
            current = activity
            call.resolve(["ok": true])
        } catch {
            call.resolve(["ok": false, "reason": error.localizedDescription])
        }
    }

    @objc func stop(_ call: CAPPluginCall) {
        endCurrent()
        call.resolve()
    }

    /// Descansos que se registraron desde la tarjeta mientras la app no estaba delante.
    @objc func pending(_ call: CAPPluginCall) {
        call.resolve(["items": PendingRest.drain()])
    }

    private func endCurrent() {
        guard #available(iOS 16.2, *) else { return }
        current = nil
        // puede haber quedado una tarjeta viva de un arranque anterior de la app
        let all = Activity<RestAttributes>.activities
        Task { for activity in all { await activity.end(nil, dismissalPolicy: .immediate) } }
    }
}
