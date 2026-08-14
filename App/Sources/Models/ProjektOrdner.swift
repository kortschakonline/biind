import Foundation

/// Claude-Daten zu einem Projektordner, gelesen aus `~/.claude/projects/<kodierter Pfad>/`.
struct ClaudeDaten: Hashable {
    var verzeichnis: URL
    var memoryCount: Int
    var sessionCount: Int
    var letzteSession: Date?
}

/// Ein Ordner in `~/Projekte` — im V1-Skelett noch 1:1 ein „Projekt".
/// Die Identitäts-Ebene (Klarname, Aliasse, Kunde, mehrere Ordner) kommt mit dem
/// PROJEKTE.md-Import in einem späteren Schritt obendrauf.
struct ProjektOrdner: Identifiable, Hashable {
    let url: URL
    let hatGit: Bool
    let hatGitRemote: Bool
    let claude: ClaudeDaten?

    var id: String { url.path }
    var name: String { url.lastPathComponent }
}
