import Foundation

/// Liest den Ist-Zustand des Dateisystems: Projektordner, Git-Status,
/// zugehörige Claude-Daten. Reiner Lesezugriff.
struct OrdnerScanner {
    private let fm = FileManager.default

    let projekteRoot: URL

    init(root: URL? = nil) {
        projekteRoot = root
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Projekte")
    }

    private var claudeProjectsRoot: URL {
        fm.homeDirectoryForCurrentUser.appendingPathComponent(".claude/projects")
    }

    func scan() -> [ProjektOrdner] {
        guard let eintraege = try? fm.contentsOfDirectory(
            at: projekteRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return eintraege
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .map(einzelOrdner(bei:))
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Erfasst einen einzelnen Ordner — auch außerhalb von `~/Projekte`
    /// (der KatalogBuilder nutzt das für Ordner aus `~/Kunden …`).
    func einzelOrdner(bei url: URL) -> ProjektOrdner {
        let hatGit = fm.fileExists(atPath: url.appendingPathComponent(".git").path)
        let gitConfig = url.appendingPathComponent(".git/config")
        let hatRemote = (try? String(contentsOf: gitConfig, encoding: .utf8))?
            .contains("[remote") ?? false
        return ProjektOrdner(
            url: url,
            hatGit: hatGit,
            hatGitRemote: hatRemote,
            claude: claudeDaten(fuer: url)
        )
    }

    /// Claude Code kodiert den absoluten Projektpfad zu einem Ordnernamen, indem
    /// jedes Zeichen außer ASCII-Buchstaben und -Ziffern durch `-` ersetzt wird:
    /// `/Users/x/Projekte/Netzwerk.local` → `-Users-x-Projekte-Netzwerk-local`.
    /// Genau diese Pfadbindung ist der Grund für das Zwei-Mac-Problem.
    func claudeOrdnerName(fuer url: URL) -> String {
        String(url.path.map { zeichen in
            zeichen.isASCII && (zeichen.isLetter || zeichen.isNumber) ? zeichen : "-"
        })
    }

    private func claudeDaten(fuer url: URL) -> ClaudeDaten? {
        let dir = claudeProjectsRoot.appendingPathComponent(claudeOrdnerName(fuer: url))
        guard fm.fileExists(atPath: dir.path) else { return nil }

        let inhalte = (try? fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey]
        )) ?? []
        let sessions = inhalte.filter { $0.pathExtension == "jsonl" }
        let letzte = sessions
            .compactMap { try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate }
            .max()

        let memoryDir = dir.appendingPathComponent("memory")
        let memories = ((try? fm.contentsOfDirectory(at: memoryDir, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == "md" && $0.lastPathComponent != "MEMORY.md" }

        return ClaudeDaten(
            verzeichnis: dir,
            memoryCount: memories.count,
            sessionCount: sessions.count,
            letzteSession: letzte
        )
    }
}
