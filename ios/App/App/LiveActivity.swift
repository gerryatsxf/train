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
        CAPPluginMethod(name: "stop", returnType: CAPPluginReturnPromise)
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
            setLabel: setLabel
        )

        endCurrent()
        do {
            let activity = try Activity.request(
                attributes: RestAttributes(title: "Descanso"),
                content: .init(state: state, staleDate: state.endAt.addingTimeInterval(120)),
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

    private func endCurrent() {
        guard #available(iOS 16.2, *), let activity = current as? Activity<RestAttributes> else { return }
        current = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
