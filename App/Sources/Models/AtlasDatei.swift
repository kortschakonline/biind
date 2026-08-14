import Foundation

/// Die Datenbank der App: liegt als `.atlas/atlas.json` im gesyncten
/// Projekte-Ordner — MEGA transportiert sie auf beide Macs. PROJEKTE.md wird
/// aus ihr generiert (Freitext-Abschnitte bleiben erhalten).
struct AtlasDatei: Codable {
    var version = 1
    var maschinen: [Maschine] = []
    /// Gruppen (= Kunden/Bereiche) in Anzeige- und Export-Reihenfolge.
    var gruppen: [String] = []
    /// Freitext aus PROJEKTE.md, der beim Export erhalten bleibt.
    var kopftext = ""
    var gruppenEinleitungen: [String: String] = [:]
    var fusstext = ""
    var projekte: [AtlasProjekt] = []
}

/// Ein bekannter Rechner mit seinen Wurzelpfaden — die Lösung des
/// Zwei-Mac-Problems: Pfade werden als Tokens gespeichert, jede Maschine
/// löst sie mit ihren eigenen Roots auf.
struct Maschine: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var projekteRoot: String
    var heimRoot: String
}

struct AtlasProjekt: Codable, Identifiable, Hashable {
    var id: UUID
    var klarname: String
    var aliasse: [String]
    var gruppe: String
    /// Pfad-Tokens: `$PROJEKTE/…` (im Projekte-Root), `$HEIM/…` (im
    /// Benutzerordner) oder absolut (Sonderfälle).
    var ordner: [String]
    var liveURL: String?
    var gitRemote: String?
    var details: String?
    /// Für Last-write-wins zwischen den Maschinen.
    var geaendert: Date
}
