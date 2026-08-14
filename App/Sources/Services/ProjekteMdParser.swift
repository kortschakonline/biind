import Foundation

/// Liest die handgepflegte Landkarte `~/Projekte/PROJEKTE.md` und macht daraus
/// Projekt-Identitäten. Toleranter Zeilen-Parser: `##`-Überschriften werden zu
/// Gruppen, Tabellenzeilen zu Projekten. Sektionen ohne Tabellen (Aufräumliste,
/// Konventionen …) fallen automatisch durch.
///
/// Später (V2) dreht sich die Richtung um: Die App hält die Daten in atlas.json
/// und *generiert* PROJEKTE.md. Dieser Parser ist der Import-Weg dorthin.
struct ProjekteMdParser {

    func parse(datei url: URL) -> [ProjektIdentitaet] {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return parse(markdown: text)
    }

    func parse(markdown: String) -> [ProjektIdentitaet] {
        var ergebnis: [ProjektIdentitaet] = []
        var gruppe = ""
        var spalten: [String] = []
        let zeilen = markdown.components(separatedBy: "\n")

        for (index, rohzeile) in zeilen.enumerated() {
            let zeile = rohzeile.trimmingCharacters(in: .whitespaces)

            if zeile.hasPrefix("## ") {
                gruppe = String(zeile.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                spalten = []
                continue
            }
            guard zeile.hasPrefix("|"), !zeile.contains("---") else { continue }

            let zellen = teileZellen(zeile)

            // Kopfzeile? Dann folgt in der nächsten Zeile der |---|-Trenner.
            if index + 1 < zeilen.count, zeilen[index + 1].contains("---") {
                spalten = zellen.map { $0.lowercased() }
                continue
            }
            guard !spalten.isEmpty, zellen.count == spalten.count,
                  let identitaet = identitaet(aus: zellen, spalten: spalten, gruppe: gruppe)
            else { continue }
            ergebnis.append(identitaet)
        }
        return ergebnis
    }

    // MARK: - Zeile → Identität

    private func identitaet(aus zellen: [String], spalten: [String], gruppe: String) -> ProjektIdentitaet? {
        guard !gruppe.isEmpty, let nameZelle = zellen.first else { return nil }
        let klarname = nameZelle
            .replacingOccurrences(of: "**", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard !klarname.isEmpty, klarname != "—" else { return nil }

        let aliasZelle = zelle(zu: "alias", zellen: zellen, spalten: spalten) ?? ""
        let ordnerZelle = zelle(zu: "ordner", zellen: zellen, spalten: spalten) ?? ""
        let detailsZelle = zelle(zu: "details", zellen: zellen, spalten: spalten)

        let pfade = codeSpans(in: ordnerZelle)
            .filter { $0.hasPrefix("~/") }
            .map(expandiere)

        // Anmerkungen aus der Ordner-Zelle retten (2-spaltige Tabellen haben
        // keine Details-Spalte; auch 4-spaltige tragen dort oft ⚠️-Notizen).
        var details = detailsZelle?
            .replacingOccurrences(of: "**", with: "")
            .trimmingCharacters(in: .whitespaces) ?? ""
        let anmerkungen = ordnerAnmerkungen(aus: ordnerZelle)
        if !anmerkungen.isEmpty {
            details = details.isEmpty ? anmerkungen : details + " · " + anmerkungen
        }

        return ProjektIdentitaet(
            klarname: klarname,
            aliasse: aliasse(in: aliasZelle),
            gruppe: gruppe,
            ordnerPfade: pfade,
            liveURL: liveURL(in: details),
            gitRemote: gitRemote(in: details),
            details: details.isEmpty ? nil : details
        )
    }

    /// Alles aus der Ordner-Zelle außer den `~/…`-Pfaden selbst: Notizen,
    /// Warnungen, Nicht-Pfad-Codespans (z. B. Git-Remotes) bleiben erhalten.
    private func ordnerAnmerkungen(aus zelle: String) -> String {
        let teile = zelle.components(separatedBy: "`")
        var ergebnis = ""
        for (index, teil) in teile.enumerated() {
            if index.isMultiple(of: 2) {
                ergebnis += teil
            } else if !teil.hasPrefix("~/") {
                ergebnis += "`\(teil)`"
            }
        }
        let bereinigt = ergebnis
            .replacingOccurrences(of: " + ", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " ·+"))
        return bereinigt == "—" ? "" : bereinigt
    }

    private func zelle(zu spaltenname: String, zellen: [String], spalten: [String]) -> String? {
        spalten.firstIndex { $0.contains(spaltenname) }.map { zellen[$0] }
    }

    // MARK: - Kleinteile

    private func teileZellen(_ zeile: String) -> [String] {
        var teile = zeile.components(separatedBy: "|")
        if teile.first?.trimmingCharacters(in: .whitespaces).isEmpty == true { teile.removeFirst() }
        if teile.last?.trimmingCharacters(in: .whitespaces).isEmpty == true { teile.removeLast() }
        return teile.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// Inhalte zwischen Backticks: bei Split an "`" sind das die ungeraden Stücke.
    private func codeSpans(in text: String) -> [String] {
        text.components(separatedBy: "`").enumerated().compactMap { index, teil in
            index.isMultiple(of: 2) ? nil : teil
        }
    }

    /// Aliasse stehen in deutschen Anführungszeichen: „das Portal", „view" …
    private func aliasse(in text: String) -> [String] {
        var ergebnis: [String] = []
        var rest = Substring(text)
        while let start = rest.firstIndex(of: "„") {
            rest = rest[rest.index(after: start)...]
            guard let ende = rest.firstIndex(where: { "\u{201C}\u{201D}\"".contains($0) }) else { break }
            let alias = String(rest[..<ende]).trimmingCharacters(in: .whitespaces)
            if !alias.isEmpty { ergebnis.append(alias) }
            rest = rest[rest.index(after: ende)...]
        }
        return ergebnis
    }

    /// „**live: proof.kortschak.online**" → "proof.kortschak.online"
    private func liveURL(in text: String) -> String? {
        guard let bereich = text.range(of: "live: ", options: .caseInsensitive) else { return nil }
        let url = text[bereich.upperBound...].prefix { !" ·|*".contains($0) }
        return url.isEmpty ? nil : String(url)
    }

    /// „Git: `kortschakonline/xy`" → "kortschakonline/xy"
    private func gitRemote(in text: String) -> String? {
        guard let bereich = text.range(of: "Git: ") else { return nil }
        return codeSpans(in: String(text[bereich.upperBound...])).first
    }

    private func expandiere(_ pfad: String) -> String {
        pfad.hasPrefix("~")
            ? NSHomeDirectory() + String(pfad.dropFirst())
            : pfad
    }
}
