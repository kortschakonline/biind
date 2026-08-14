import Foundation
import Observation

/// Der gemeinsame Datenbestand für Hauptfenster und Quick-Switcher.
/// Seit V2 ist die atlas.json die Quelle der Wahrheit: Laden migriert bei
/// Bedarf einmalig aus PROJEKTE.md, jede Änderung speichert die atlas.json
/// und generiert PROJEKTE.md neu.
@MainActor @Observable
final class KatalogStore {
    var katalog = Katalog()
    var befunde: [Befund] = []
    var auswahl: String?
    private(set) var atlas = AtlasDatei()

    private let verwaltung = AtlasVerwaltung()
    private var geladen = false

    var gruppenNamen: [String] { atlas.gruppen }

    // MARK: - Laden

    func ladenFallsNoetig() async {
        guard !geladen else { return }
        geladen = true
        atlas = verwaltung.ladeOderMigriere()
        neuAufbauen()
        await checksAktualisieren()
    }

    private func neuAufbauen() {
        katalog = KatalogBuilder().build(
            identitaeten: verwaltung.identitaeten(aus: atlas),
            root: verwaltung.projekteRoot
        )
    }

    private func checksAktualisieren() async {
        let fertigerKatalog = katalog
        let root = verwaltung.projekteRoot
        befunde = await Task.detached(priority: .utility) {
            GesundheitsPruefer().pruefe(katalog: fertigerKatalog, projekteRoot: root)
        }.value
    }

    // MARK: - Mutationen (V2: Verwalten)

    func speichereProjekt(
        atlasID: UUID, klarname: String, aliasse: [String],
        gruppe: String, liveURL: String?, details: String?
    ) {
        guard let index = atlas.projekte.firstIndex(where: { $0.id == atlasID }) else { return }
        atlas.projekte[index].klarname = klarname
        atlas.projekte[index].aliasse = aliasse
        atlas.projekte[index].gruppe = gruppe
        atlas.projekte[index].liveURL = liveURL
        atlas.projekte[index].details = details
        atlas.projekte[index].geaendert = Date()
        stelleGruppeSicher(gruppe)
        persistiereUndBaueNeu(auswahlDanach: atlasID.uuidString)
    }

    func neuesProjekt(ausOrdnerPfad pfad: String, klarname: String, gruppe: String) {
        let projekt = AtlasProjekt(
            id: UUID(),
            klarname: klarname,
            aliasse: [],
            gruppe: gruppe,
            ordner: [verwaltung.tokenisieren(pfad)],
            liveURL: nil,
            gitRemote: nil,
            details: nil,
            geaendert: Date()
        )
        atlas.projekte.append(projekt)
        stelleGruppeSicher(gruppe)
        persistiereUndBaueNeu(auswahlDanach: projekt.id.uuidString)
    }

    func ordneOrdnerZu(pfad: String, projektID: UUID) {
        guard let index = atlas.projekte.firstIndex(where: { $0.id == projektID }) else { return }
        let token = verwaltung.tokenisieren(pfad)
        if !atlas.projekte[index].ordner.contains(token) {
            atlas.projekte[index].ordner.append(token)
        }
        atlas.projekte[index].geaendert = Date()
        persistiereUndBaueNeu(auswahlDanach: projektID.uuidString)
    }

    // MARK: - Intern

    private func stelleGruppeSicher(_ name: String) {
        if !atlas.gruppen.contains(name) { atlas.gruppen.append(name) }
    }

    private func persistiereUndBaueNeu(auswahlDanach: String?) {
        verwaltung.speichern(atlas)
        neuAufbauen()
        if let auswahlDanach { auswahl = auswahlDanach }
        Task { await checksAktualisieren() }
    }
}
