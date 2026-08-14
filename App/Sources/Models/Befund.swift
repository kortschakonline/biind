import Foundation

enum Schweregrad: Int, Comparable, Hashable {
    case hinweis = 0
    case warnung = 1
    case kritisch = 2

    static func < (links: Schweregrad, rechts: Schweregrad) -> Bool {
        links.rawValue < rechts.rawValue
    }
}

/// Kennzeichnet Befunde, für die die App eine Heil-Aktion anbietet.
enum BefundArt: Hashable {
    case allgemein
    case verwaisterClaudeSpeicher
}

/// Ein Befund der Gesundheits-Checks — die automatisierte Version der
/// Aufräumliste aus PROJEKTE.md.
struct Befund: Identifiable, Hashable {
    let schweregrad: Schweregrad
    let titel: String
    let erklaerung: String
    /// Betroffener Pfad, falls es einen konkreten Ort gibt („Zeigen"-Button).
    let pfad: String?
    var art: BefundArt = .allgemein

    var id: String { titel + "|" + (pfad ?? "") }
}
