import Foundation
import Observation

/// Der gemeinsame Datenbestand für Hauptfenster und Quick-Switcher:
/// Katalog, Befunde und die aktuelle Auswahl.
@MainActor @Observable
final class KatalogStore {
    var katalog = Katalog()
    var befunde: [Befund] = []
    var auswahl: String?

    private var geladen = false

    func ladenFallsNoetig() async {
        guard !geladen else { return }
        geladen = true
        katalog = KatalogBuilder().build()
        let fertigerKatalog = katalog
        befunde = await Task.detached(priority: .utility) {
            GesundheitsPruefer().pruefe(katalog: fertigerKatalog)
        }.value
    }
}
