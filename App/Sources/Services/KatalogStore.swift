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
    /// Pfade neuer, noch unzugeordneter Ordner, die der Watcher entdeckt hat
    /// (Banner im Hauptfenster).
    var neueOrdnerHinweise: [String] = []
    private(set) var atlas = AtlasDatei()

    private let verwaltung = AtlasVerwaltung()
    private let watcher = OrdnerWatcher()
    private var geladen = false
    private var aktualisierungGeplant = false
    /// Bytes der zuletzt selbst geschriebenen atlas.json — unterscheidet
    /// eigene Schreibvorgänge von extern gesyncten Änderungen.
    private var zuletztGeschrieben: Data?

    var gruppenNamen: [String] { atlas.gruppen }

    // MARK: - Laden

    func ladenFallsNoetig() async {
        guard !geladen else { return }
        geladen = true
        atlas = verwaltung.ladeOderMigriere()
        zuletztGeschrieben = try? Data(contentsOf: verwaltung.atlasURL)
        neuAufbauen()
        starteWatcher()
        await checksAktualisieren()
    }

    // MARK: - Dateisystem-Watcher

    private func starteWatcher() {
        watcher.onAenderung = { [weak self] pfade in
            MainActor.assumeIsolated { self?.dateisystemGeaendert(pfade) }
        }
        watcher.start(pfad: verwaltung.projekteRoot.path)
    }

    private func dateisystemGeaendert(_ pfade: [String]) {
        let root = verwaltung.projekteRoot.path
        let atlasDir = verwaltung.atlasVerzeichnis.path
        let relevant = pfade.contains { pfad in
            let bereinigt = pfad.hasSuffix("/") ? String(pfad.dropLast()) : pfad
            return bereinigt == root || bereinigt == atlasDir
        }
        guard relevant else { return }
        planeAktualisierung()
    }

    private func planeAktualisierung() {
        guard !aktualisierungGeplant else { return }
        aktualisierungGeplant = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            aktualisierungGeplant = false
            await aussenAktualisieren()
        }
    }

    private func aussenAktualisieren() async {
        // atlas.json extern geändert (Sync vom anderen Mac)? Dann übernehmen.
        if let daten = try? Data(contentsOf: verwaltung.atlasURL),
           daten != zuletztGeschrieben,
           let extern = verwaltung.dekodiere(daten) {
            atlas = extern
            zuletztGeschrieben = daten
        }

        let vorher = unzugeordnetePfade()
        neuAufbauen()
        let neu = unzugeordnetePfade().subtracting(vorher)
        for pfad in neu.sorted() where !neueOrdnerHinweise.contains(pfad) {
            neueOrdnerHinweise.append(pfad)
        }
        // Hinweise aufräumen, deren Ordner verschwunden oder inzwischen zugeordnet ist
        let aktuell = unzugeordnetePfade()
        neueOrdnerHinweise.removeAll { !aktuell.contains($0) }

        await checksAktualisieren()
    }

    private func unzugeordnetePfade() -> Set<String> {
        Set(
            katalog.gruppen
                .first { $0.name == "Nicht zugeordnet" }?
                .projekte.compactMap { $0.ordner.first?.url.path } ?? []
        )
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

    /// Die einzige schreibende Operation in `~/.claude` — immer vom Benutzer
    /// im Sheet bestätigt.
    func fuehreSpeicherZusammen(quellPfad: String, zielOrdnerPfad: String) -> MemoryZusammenfuehrer.Bericht? {
        let bericht = try? MemoryZusammenfuehrer().fuehreZusammen(
            quelle: URL(fileURLWithPath: quellPfad),
            zielOrdner: URL(fileURLWithPath: zielOrdnerPfad)
        )
        neuAufbauen()
        Task { await checksAktualisieren() }
        return bericht
    }

    // MARK: - Geführtes Aufräumen

    func archiviereOrdner(pfad: String) -> String? {
        guard let neuerPfad = try? AufraeumHelfer().archiviere(
            pfad: pfad, projekteRoot: verwaltung.projekteRoot
        ) else { return nil }
        entferneOrdnerToken(pfad)
        persistiereUndBaueNeu(auswahlDanach: nil)
        return neuerPfad
    }

    func legeOrdnerInPapierkorb(pfad: String) -> Bool {
        guard (try? AufraeumHelfer().inPapierkorb(pfad: pfad)) != nil else { return false }
        entferneOrdnerToken(pfad)
        persistiereUndBaueNeu(auswahlDanach: nil)
        return true
    }

    func stelleGitRemoteUm(configPfad: String) -> (alt: String, neu: String)? {
        let ergebnis = try? AufraeumHelfer().stelleSshUm(configPfad: configPfad)
        Task { await checksAktualisieren() }
        return ergebnis
    }

    func istImAtlas(pfad: String) -> Bool {
        let token = verwaltung.tokenisieren(pfad)
        return atlas.projekte.contains { $0.ordner.contains(token) }
    }

    private func entferneOrdnerToken(_ pfad: String) {
        let token = verwaltung.tokenisieren(pfad)
        for index in atlas.projekte.indices where atlas.projekte[index].ordner.contains(token) {
            atlas.projekte[index].ordner.removeAll { $0 == token }
            atlas.projekte[index].geaendert = Date()
        }
    }

    // MARK: - Intern

    private func stelleGruppeSicher(_ name: String) {
        if !atlas.gruppen.contains(name) { atlas.gruppen.append(name) }
    }

    private func persistiereUndBaueNeu(auswahlDanach: String?) {
        verwaltung.speichern(atlas)
        zuletztGeschrieben = try? Data(contentsOf: verwaltung.atlasURL)
        neuAufbauen()
        if let auswahlDanach { auswahl = auswahlDanach }
        Task { await checksAktualisieren() }
    }
}
