import Foundation

/// Die Identitäts-Ebene aus PROJEKTE.md: das, was ein Projekt *ist* —
/// unabhängig davon, wie seine Ordner heißen. Kernidee der App.
struct ProjektIdentitaet: Hashable {
    let klarname: String
    let aliasse: [String]
    let gruppe: String
    let ordnerPfade: [String]   // absolute Pfade (bereits expandiert)
    let liveURL: String?
    let gitRemote: String?
    let details: String?

    var id: String { gruppe + "/" + klarname }
}

/// Identität + die real auf diesem Mac gefundenen Ordner = die „Projektakte",
/// die die UI anzeigt.
struct ProjektAkte: Identifiable, Hashable {
    let id: String
    let klarname: String
    let aliasse: [String]
    let gruppe: String
    let liveURL: String?
    let gitRemote: String?
    let details: String?
    let ordner: [ProjektOrdner]
    /// In PROJEKTE.md referenziert, aber auf diesem Mac nicht vorhanden —
    /// typisch: liegt nur auf dem anderen Rechner (Zwei-Mac-Setup).
    let fehlendeOrdner: [String]

    var sessionCount: Int { ordner.compactMap(\.claude?.sessionCount).reduce(0, +) }
    var memoryCount: Int { ordner.compactMap(\.claude?.memoryCount).reduce(0, +) }
    var letzteSession: Date? { ordner.compactMap(\.claude?.letzteSession).max() }
    var hatClaude: Bool { ordner.contains { $0.claude != nil } }
    var gitOhneRemote: Bool { ordner.contains { $0.hatGit && !$0.hatGitRemote } }

    func passt(zu suche: String) -> Bool {
        klarname.localizedCaseInsensitiveContains(suche)
            || aliasse.contains { $0.localizedCaseInsensitiveContains(suche) }
            || ordner.contains { $0.name.localizedCaseInsensitiveContains(suche) }
    }
}

/// Alles, was die App anzeigt: Gruppen (= Kunden/Bereiche aus PROJEKTE.md)
/// in Dokument-Reihenfolge, plus „Nicht zugeordnet" für Ordner ohne Eintrag.
struct Katalog {
    struct Gruppe: Identifiable {
        let name: String
        var projekte: [ProjektAkte]
        var id: String { name }
    }

    var gruppen: [Gruppe] = []
    var alleProjekte: [ProjektAkte] { gruppen.flatMap(\.projekte) }
}
