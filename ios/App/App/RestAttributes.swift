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
        /// Identifican la serie para que el botón de la tarjeta registre el descanso
        /// sin que la app esté abierta.
        var exId: String = ""
        var setIndex: Int = 0
        var week: Int = 0
        /// Lo marca el propio botón: la tarjeta sigue visible confirmando el registro.
        var registered: Bool = false
        var registeredSeconds: Int = 0
    }

    var title: String
}
