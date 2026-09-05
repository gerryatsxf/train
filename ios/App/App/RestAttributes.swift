import Foundation
import ActivityKit

/// Compartido entre la app y la extensión de widget: ambos targets deben incluir este archivo.
struct RestAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Instante en que termina el descanso; la vista usa `Text(timerInterval:)`
        /// para contar sola, sin necesidad de enviar actualizaciones cada segundo.
        var endAt: Date
        var startedAt: Date
        var exercise: String
        var setLabel: String
    }

    var title: String
}
