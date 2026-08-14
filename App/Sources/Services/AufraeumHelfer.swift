import Foundation

/// Die Heil-Aktionen des geführten Aufräumens. Grundsätze: alles ist
/// umkehrbar (Archiv statt Löschen, Papierkorb statt Entfernen, Backup vor
/// dem Umschreiben), und jede Aktion wird vom Benutzer einzeln bestätigt.
struct AufraeumHelfer {

    /// Verschiebt einen Ordner nach `~/Projekte/_Archiv/` (Laufnummer bei
    /// Namensgleichheit). Rückgabe: der neue Pfad.
    func archiviere(pfad: String, projekteRoot: URL) throws -> String {
        let fm = FileManager.default
        let archiv = projekteRoot.appendingPathComponent("_Archiv")
        try fm.createDirectory(at: archiv, withIntermediateDirectories: true)
        let quelle = URL(fileURLWithPath: pfad)
        var ziel = archiv.appendingPathComponent(quelle.lastPathComponent)
        var laufnummer = 2
        while fm.fileExists(atPath: ziel.path) {
            ziel = archiv.appendingPathComponent("\(quelle.lastPathComponent)-\(laufnummer)")
            laufnummer += 1
        }
        try fm.moveItem(at: quelle, to: ziel)
        return ziel.path
    }

    /// macOS-nativ und umkehrbar: der Finder-Papierkorb.
    /// Rückgabe: wohin der Eintrag gewandert ist.
    @discardableResult
    func inPapierkorb(pfad: String) throws -> URL? {
        var ergebnis: NSURL?
        try FileManager.default.trashItem(
            at: URL(fileURLWithPath: pfad),
            resultingItemURL: &ergebnis
        )
        return ergebnis as URL?
    }

    /// Zeigt, wie das HTTPS-Remote (mit eingebettetem Token) als
    /// SSH-Remote aussähe — ohne etwas zu verändern.
    func sshVorschau(configPfad: String) -> (alt: String, neu: String)? {
        guard let text = try? String(contentsOf: URL(fileURLWithPath: configPfad), encoding: .utf8)
        else { return nil }
        for zeile in text.components(separatedBy: "\n") {
            let getrimmt = zeile.trimmingCharacters(in: .whitespaces)
            guard getrimmt.hasPrefix("url = https://"),
                  let bereich = getrimmt.range(of: "github.com/")
            else { continue }
            var rest = String(getrimmt[bereich.upperBound...]).trimmingCharacters(in: .whitespaces)
            if rest.hasSuffix(".git") { rest = String(rest.dropLast(4)) }
            let alt = String(getrimmt.dropFirst("url = ".count))
            return (alt, "git@github.com:\(rest).git")
        }
        return nil
    }

    /// Stellt das Remote auf SSH um — mit Backup der alten config daneben
    /// (`config.atlas-backup`). Das alte Token muss der Mensch widerrufen.
    func stelleSshUm(configPfad: String) throws -> (alt: String, neu: String) {
        guard let vorschau = sshVorschau(configPfad: configPfad) else {
            throw NSError(domain: "AufraeumHelfer", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Kein umstellbares github.com-HTTPS-Remote gefunden."
            ])
        }
        let url = URL(fileURLWithPath: configPfad)
        let text = try String(contentsOf: url, encoding: .utf8)
        let backup = url.deletingLastPathComponent().appendingPathComponent("config.atlas-backup")
        try text.write(to: backup, atomically: true, encoding: .utf8)
        let neu = text.replacingOccurrences(of: vorschau.alt, with: vorschau.neu)
        try neu.write(to: url, atomically: true, encoding: .utf8)
        return vorschau
    }
}
