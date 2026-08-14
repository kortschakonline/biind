import Foundation

/// Eine Memory-Datei aus Claudes Projektgedächtnis (`memory/*.md`).
struct MemoryEintrag: Identifiable, Hashable {
    let name: String
    let beschreibung: String
    let inhalt: String
    let ordnerName: String
    var id: String { ordnerName + "/" + name }
}

/// Ein Session-Transcript (`*.jsonl`) mit best-effort ermitteltem Titel.
struct SessionEintrag: Identifiable, Hashable {
    let datum: Date?
    let titel: String
    let url: URL
    var id: String { url.path }
}

/// Liest Claudes Projektgedächtnis und Session-Verläufe. Ausschließlich lesend —
/// die App fasst `~/.claude/` nie schreibend an.
struct ClaudeLeser {

    // MARK: - Memories

    func memories(fuer ordnerListe: [ProjektOrdner]) -> [MemoryEintrag] {
        ordnerListe.flatMap { ordner -> [MemoryEintrag] in
            guard let claude = ordner.claude else { return [] }
            let dir = claude.verzeichnis.appendingPathComponent("memory")
            let dateien = (try? FileManager.default.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil
            )) ?? []
            return dateien
                .filter { $0.pathExtension == "md" && $0.lastPathComponent != "MEMORY.md" }
                .compactMap { eintrag(aus: $0, ordnerName: ordner.name) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    /// Frontmatter-Format der Memories:
    /// `---` / `name: …` / `description: …` / `---` / Inhalt
    private func eintrag(aus url: URL, ordnerName: String) -> MemoryEintrag? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        var name = url.deletingPathExtension().lastPathComponent
        var beschreibung = ""
        var inhalt = text

        if text.hasPrefix("---") {
            let teile = text.components(separatedBy: "\n---")
            if teile.count >= 2 {
                for zeile in teile[0].components(separatedBy: "\n") {
                    if zeile.hasPrefix("name:") { name = wert(aus: zeile) }
                    if zeile.hasPrefix("description:") { beschreibung = wert(aus: zeile) }
                }
                inhalt = teile.dropFirst().joined(separator: "\n---")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return MemoryEintrag(name: name, beschreibung: beschreibung, inhalt: inhalt, ordnerName: ordnerName)
    }

    private func wert(aus zeile: String) -> String {
        String(zeile.drop(while: { $0 != ":" }).dropFirst())
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Sessions

    func sessions(fuer ordnerListe: [ProjektOrdner]) -> [SessionEintrag] {
        ordnerListe.flatMap { ordner -> [SessionEintrag] in
            guard let claude = ordner.claude else { return [] }
            let dateien = (try? FileManager.default.contentsOfDirectory(
                at: claude.verzeichnis,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )) ?? []
            return dateien
                .filter { $0.pathExtension == "jsonl" }
                .map(session(aus:))
        }
        .sorted { ($0.datum ?? .distantPast) > ($1.datum ?? .distantPast) }
    }

    private func session(aus url: URL) -> SessionEintrag {
        let datum = try? url.resourceValues(forKeys: [.contentModificationDateKey])
            .contentModificationDate
        return SessionEintrag(datum: datum, titel: titel(aus: url) ?? "Session", url: url)
    }

    /// Best effort: bevorzugt die Zusammenfassungs-Zeile, sonst die erste echte
    /// Nutzer-Nachricht. Liest bewusst nur den Datei-Anfang (256 KB) —
    /// Transcripts können viele Megabyte groß sein.
    private func titel(aus url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url),
              let daten = try? handle.read(upToCount: 262_144),
              let text = String(data: daten, encoding: .utf8)
        else { return nil }
        try? handle.close()

        var fallback: String?
        for zeile in text.components(separatedBy: "\n") {
            guard let json = try? JSONSerialization.jsonObject(with: Data(zeile.utf8)) as? [String: Any]
            else { continue }

            if json["type"] as? String == "summary", let zusammenfassung = json["summary"] as? String {
                return gekuerzt(zusammenfassung)
            }
            if fallback == nil,
               json["type"] as? String == "user",
               json["isMeta"] as? Bool != true,
               let nachricht = json["message"] as? [String: Any] {
                let inhaltText: String? =
                    (nachricht["content"] as? String)
                    ?? (nachricht["content"] as? [[String: Any]])?
                        .compactMap { $0["text"] as? String }.first
                if let t = inhaltText?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !t.isEmpty, !t.hasPrefix("<") {
                    fallback = gekuerzt(t)
                }
            }
        }
        return fallback
    }

    private func gekuerzt(_ text: String) -> String {
        let einzeilig = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
        return einzeilig.count > 90 ? String(einzeilig.prefix(90)) + "…" : einzeilig
    }
}
