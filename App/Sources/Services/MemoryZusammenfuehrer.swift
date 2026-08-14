import Foundation

/// Führt einen verwaisten Claude-Speicher mit dem aktiven Speicher eines
/// Zielordners zusammen — DIE Heilung für das pfadgebundene Gedächtnis
/// (und die einzige schreibende Operation der App in `~/.claude`, immer
/// vom Benutzer bestätigt).
///
/// Prinzip: verschieben, nie löschen. Sessions mit Namenskollision bleiben in
/// der Quelle liegen, Memory-Kollisionen werden mit Suffix umbenannt, der
/// MEMORY.md-Index wird vereinigt. Die Quelle wird nur entfernt, wenn sie
/// danach leer ist.
struct MemoryZusammenfuehrer {

    struct Bericht: Hashable {
        var sessions = 0
        var memories = 0
        var sonstiges = 0
        var umbenannt: [String] = []
        var zurueckgeblieben = 0
        var zielPfad = ""
        var quelleEntfernt = false
    }

    func fuehreZusammen(quelle: URL, zielOrdner: URL) throws -> Bericht {
        let fm = FileManager.default
        let ziel = fm.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")
            .appendingPathComponent(OrdnerScanner().claudeOrdnerName(fuer: zielOrdner))
        var bericht = Bericht(zielPfad: ziel.path)
        guard quelle.path != ziel.path else { return bericht }
        try fm.createDirectory(at: ziel, withIntermediateDirectories: true)

        // 1) Sessions & Zubehör: alles auf oberster Ebene außer memory/
        for eintrag in try fm.contentsOfDirectory(at: quelle, includingPropertiesForKeys: nil) {
            let name = eintrag.lastPathComponent
            if name == "memory" || name == ".DS_Store" { continue }
            let zielURL = ziel.appendingPathComponent(name)
            if fm.fileExists(atPath: zielURL.path) {
                bericht.zurueckgeblieben += 1
                continue
            }
            try fm.moveItem(at: eintrag, to: zielURL)
            if name.hasSuffix(".jsonl") { bericht.sessions += 1 } else { bericht.sonstiges += 1 }
        }

        // 2) Memories
        let quellMemory = quelle.appendingPathComponent("memory")
        if fm.fileExists(atPath: quellMemory.path) {
            let zielMemory = ziel.appendingPathComponent("memory")
            try fm.createDirectory(at: zielMemory, withIntermediateDirectories: true)

            for eintrag in try fm.contentsOfDirectory(at: quellMemory, includingPropertiesForKeys: nil) {
                let name = eintrag.lastPathComponent
                if name == "MEMORY.md" || name == ".DS_Store" { continue }
                var zielName = name
                if fm.fileExists(atPath: zielMemory.appendingPathComponent(name).path) {
                    zielName = eintrag.deletingPathExtension().lastPathComponent
                        + "-zusammengefuehrt." + eintrag.pathExtension
                    if fm.fileExists(atPath: zielMemory.appendingPathComponent(zielName).path) {
                        bericht.zurueckgeblieben += 1
                        continue
                    }
                    bericht.umbenannt.append(zielName)
                }
                try fm.moveItem(at: eintrag, to: zielMemory.appendingPathComponent(zielName))
                bericht.memories += 1
            }

            // MEMORY.md-Index vereinigen: fehlende Zeilen anhängen
            let quellIndex = quellMemory.appendingPathComponent("MEMORY.md")
            if let quellText = try? String(contentsOf: quellIndex, encoding: .utf8) {
                let zielIndexURL = zielMemory.appendingPathComponent("MEMORY.md")
                var zielText = (try? String(contentsOf: zielIndexURL, encoding: .utf8)) ?? "# Memory-Index\n"
                for zeile in quellText.components(separatedBy: "\n")
                where zeile.hasPrefix("- ") && !zielText.contains(zeile) {
                    if !zielText.hasSuffix("\n") { zielText += "\n" }
                    zielText += zeile + "\n"
                }
                try? zielText.write(to: zielIndexURL, atomically: true, encoding: .utf8)
                try? fm.removeItem(at: quellIndex)
            }
            entferneWennLeer(quellMemory)
        }

        // 3) Quelle entfernen, wenn leer
        bericht.quelleEntfernt = entferneWennLeer(quelle)
        return bericht
    }

    @discardableResult
    private func entferneWennLeer(_ url: URL) -> Bool {
        let fm = FileManager.default
        guard let inhalt = try? fm.contentsOfDirectory(atPath: url.path) else { return false }
        if inhalt == [".DS_Store"] {
            try? fm.removeItem(at: url.appendingPathComponent(".DS_Store"))
        }
        guard ((try? fm.contentsOfDirectory(atPath: url.path)) ?? []).isEmpty else { return false }
        try? fm.removeItem(at: url)
        return true
    }
}
