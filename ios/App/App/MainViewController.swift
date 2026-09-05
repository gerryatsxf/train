import UIKit
import Capacitor

/// Los plugins definidos dentro del proyecto de la app no se auto-descubren:
/// hay que registrarlos en el bridge cuando termina de cargar.
class MainViewController: CAPBridgeViewController {
    override func capacitorDidLoad() {
        bridge?.registerPluginInstance(NativeSoundPlugin())
        bridge?.registerPluginInstance(LiveActivityPlugin())
    }
}
