import Foundation

/// Verschmilzt zwei Stände der atlas.json — die Antwort auf gleichzeitiges
/// Editieren an beiden Macs. Prinzip: **Union statt Überschreiben.**
///
/// - Projekte: vereinigt per UUID; bei Konflikt gewinnt der jüngere
///   `geaendert`-Zeitstempel. Projekte, die nur auf einer Seite existieren,
///   überleben immer (es gibt keine Lösch-Funktion — fehlend heißt: auf der
///   anderen Maschine neu angelegt).
/// - Gruppen & Maschinen: Union, Reihenfolge der eigenen Seite zuerst.
/// - Freitexte (Kopf/Einleitungen/Fuss): von der Seite mit dem jüngsten
///   Projekt-Zeitstempel; fehlende Gruppen-Einleitungen werden von der
///   anderen Seite ergänzt.
struct AtlasMerger {

    func merge(mein: AtlasDatei, extern: AtlasDatei) -> AtlasDatei {
        let meinJuengster = mein.projekte.map(\.geaendert).max() ?? .distantPast
        let externJuengster = extern.projekte.map(\.geaendert).max() ?? .distantPast
        let basis = externJuengster > meinJuengster ? extern : mein
        let andere = externJuengster > meinJuengster ? mein : extern

        var ergebnis = AtlasDatei()
        ergebnis.version = max(mein.version, extern.version)
        ergebnis.kopftext = basis.kopftext
        ergebnis.fusstext = basis.fusstext
        ergebnis.gruppenEinleitungen = basis.gruppenEinleitungen
            .merging(andere.gruppenEinleitungen) { eigene, _ in eigene }

        // Projekte: Union per UUID, jüngerer Zeitstempel gewinnt
        var perID: [UUID: AtlasProjekt] = [:]
        for projekt in mein.projekte { perID[projekt.id] = projekt }
        for projekt in extern.projekte {
            if let vorhanden = perID[projekt.id] {
                if projekt.geaendert > vorhanden.geaendert { perID[projekt.id] = projekt }
            } else {
                perID[projekt.id] = projekt
            }
        }
        // Reihenfolgen kanonisch von der Basis-Seite — dadurch ist der Merge
        // symmetrisch und beide Maschinen landen beim identischen Stand
        // (sonst: endloses Ping-Pong-Zurückspeichern über den Sync).
        var reihenfolge = basis.projekte.map(\.id)
        for projekt in andere.projekte where !reihenfolge.contains(projekt.id) {
            reihenfolge.append(projekt.id)
        }
        ergebnis.projekte = reihenfolge.compactMap { perID[$0] }

        // Gruppen: Union, Basis-Reihenfolge zuerst
        var gruppen = basis.gruppen
        for gruppe in andere.gruppen where !gruppen.contains(gruppe) {
            gruppen.append(gruppe)
        }
        ergebnis.gruppen = gruppen

        // Maschinen: Union per ID (jede Maschine pflegt nur ihren Eintrag)
        var maschinen = basis.maschinen
        for maschine in andere.maschinen where !maschinen.contains(where: { $0.id == maschine.id }) {
            maschinen.append(maschine)
        }
        ergebnis.maschinen = maschinen

        return ergebnis
    }

    /// Grober Gleichheits-Check: Haben beide Stände dieselben Projekte
    /// mit denselben Zeitstempeln?
    func sindGleich(_ links: AtlasDatei, _ rechts: AtlasDatei) -> Bool {
        let linksStand = links.projekte.map { "\($0.id)|\($0.geaendert.timeIntervalSince1970)" }.sorted()
        let rechtsStand = rechts.projekte.map { "\($0.id)|\($0.geaendert.timeIntervalSince1970)" }.sorted()
        return linksStand == rechtsStand && links.gruppen == rechts.gruppen
    }
}
