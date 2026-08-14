import Foundation

/// Lädt, migriert und speichert die atlas.json — und generiert daraus
/// PROJEKTE.md, damit Claude auf beiden Maschinen seine Landkarte behält.
///
/// Sicherungen beim Export: das Original wird einmalig nach
/// `.atlas/PROJEKTE-original-backup.md` kopiert, und geschrieben wird nur,
/// wenn der Export wieder sauber parsbar ist (Roundtrip-Guard).
struct AtlasVerwaltung {

    let projekteRoot: URL
    let heimRoot: URL

    init() {
        let fm = FileManager.default
        let heim = fm.homeDirectoryForCurrentUser
        let kandidaten = [
            heim.appendingPathComponent("Projekte"),
            URL(fileURLWithPath: "/Volumes/MacUser/Projekte"),
        ]
        projekteRoot = kandidaten.first {
            fm.fileExists(atPath: $0.appendingPathComponent("PROJEKTE.md").path)
        } ?? kandidaten[0]
        heimRoot = heim
    }

    var atlasVerzeichnis: URL { projekteRoot.appendingPathComponent(".atlas") }
    var atlasURL: URL { atlasVerzeichnis.appendingPathComponent("atlas.json") }
    var projekteMdURL: URL { projekteRoot.appendingPathComponent("PROJEKTE.md") }
    var backupURL: URL { atlasVerzeichnis.appendingPathComponent("PROJEKTE-original-backup.md") }

    // MARK: - Laden & Migration

    func ladeOderMigriere() -> AtlasDatei {
        var atlas = ladeOderErzeuge()
        registriereMaschine(&atlas)
        speichern(atlas)
        return atlas
    }

    /// Wie `ladeOderMigriere`, aber ohne Schreiben — für Tests/Vorschau.
    func migrationsVorschau() -> (atlas: AtlasDatei, markdown: String) {
        var atlas = ladeOderErzeuge()
        registriereMaschine(&atlas)
        return (atlas, markdownText(fuer: atlas))
    }

    private func ladeOderErzeuge() -> AtlasDatei {
        if let daten = try? Data(contentsOf: atlasURL),
           let geladen = try? decoder.decode(AtlasDatei.self, from: daten) {
            return geladen
        }
        return migriereAusProjekteMd()
    }

    private func migriereAusProjekteMd() -> AtlasDatei {
        let text = (try? String(contentsOf: projekteMdURL, encoding: .utf8)) ?? ""
        let identitaeten = ProjekteMdParser().parse(markdown: text)

        var atlas = AtlasDatei()
        var gesehen = Set<String>()
        for identitaet in identitaeten where !gesehen.contains(identitaet.gruppe) {
            gesehen.insert(identitaet.gruppe)
            atlas.gruppen.append(identitaet.gruppe)
        }
        let texte = freitexte(aus: text, gruppen: gesehen)
        atlas.kopftext = texte.kopf
        atlas.gruppenEinleitungen = texte.einleitungen
        atlas.fusstext = texte.fuss
        atlas.projekte = identitaeten.map { identitaet in
            AtlasProjekt(
                id: UUID(),
                klarname: identitaet.klarname,
                aliasse: identitaet.aliasse,
                gruppe: identitaet.gruppe,
                ordner: identitaet.ordnerPfade.map(tokenisieren),
                liveURL: identitaet.liveURL,
                gitRemote: identitaet.gitRemote,
                details: identitaet.details,
                geaendert: Date()
            )
        }
        return atlas
    }

    /// Sammelt die Nicht-Tabellen-Inhalte von PROJEKTE.md, damit der Export
    /// sie erhalten kann: Kopftext, Einleitungen je Gruppe (z. B. der
    /// Trofaiach-Warnhinweis) und alles nach den Projekt-Gruppen
    /// (Kunden-Ordner, Aufräumliste, Namens-Konvention).
    private func freitexte(aus text: String, gruppen: Set<String>) -> (kopf: String, einleitungen: [String: String], fuss: String) {
        enum Phase { case kopf, gruppe(String), fuss }
        var phase = Phase.kopf
        var kopf: [String] = [], fuss: [String] = []
        var einleitungen: [String: String] = [:]
        var puffer: [String] = []
        var tabelleGesehen = false
        var ersteGruppeGesehen = false

        func schliesseGruppe() {
            if case .gruppe(let name) = phase {
                let einleitung = puffer.joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !einleitung.isEmpty { einleitungen[name] = einleitung }
            }
            puffer = []
            tabelleGesehen = false
        }

        for zeile in text.components(separatedBy: "\n") {
            if zeile.hasPrefix("## ") {
                schliesseGruppe()
                let name = String(zeile.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                if gruppen.contains(name) {
                    phase = .gruppe(name)
                    ersteGruppeGesehen = true
                } else if ersteGruppeGesehen {
                    phase = .fuss
                    fuss.append(zeile)
                } else {
                    phase = .kopf
                    kopf.append(zeile)
                }
                continue
            }
            // Generator-Marker einer früheren Version nicht erneut einsammeln
            if zeile.hasPrefix("<!--"), zeile.contains("Projekt-Atlas") { continue }
            switch phase {
            case .kopf:
                kopf.append(zeile)
            case .gruppe:
                if zeile.hasPrefix("|") { tabelleGesehen = true }
                else if !tabelleGesehen { puffer.append(zeile) }
            case .fuss:
                fuss.append(zeile)
            }
        }
        schliesseGruppe()
        return (
            kopf.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines),
            einleitungen,
            fuss.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func registriereMaschine(_ atlas: inout AtlasDatei) {
        let schluessel = "atlas.maschinenID"
        let id: String
        if let vorhanden = UserDefaults.standard.string(forKey: schluessel) {
            id = vorhanden
        } else {
            id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: schluessel)
        }
        let name = Host.current().localizedName ?? "Mac"
        if let index = atlas.maschinen.firstIndex(where: { $0.id == id }) {
            atlas.maschinen[index].name = name
            atlas.maschinen[index].projekteRoot = projekteRoot.path
            atlas.maschinen[index].heimRoot = heimRoot.path
        } else {
            atlas.maschinen.append(Maschine(
                id: id, name: name,
                projekteRoot: projekteRoot.path, heimRoot: heimRoot.path
            ))
        }
    }

    // MARK: - Speichern & Export

    func speichern(_ atlas: AtlasDatei) {
        try? FileManager.default.createDirectory(at: atlasVerzeichnis, withIntermediateDirectories: true)
        if let daten = try? encoder.encode(atlas) {
            try? daten.write(to: atlasURL, options: .atomic)
        }
        exportiereProjekteMd(atlas)
    }

    func exportiereProjekteMd(_ atlas: AtlasDatei) {
        let neu = markdownText(fuer: atlas)

        // Roundtrip-Guard: Der Export muss dieselbe Projektzahl liefern,
        // sonst bleibt die bestehende Datei unangetastet.
        let reparse = ProjekteMdParser().parse(markdown: neu)
        guard reparse.count == atlas.projekte.count else { return }

        let alt = (try? String(contentsOf: projekteMdURL, encoding: .utf8)) ?? ""
        guard neu != alt else { return }
        if !FileManager.default.fileExists(atPath: backupURL.path), !alt.isEmpty {
            try? FileManager.default.createDirectory(at: atlasVerzeichnis, withIntermediateDirectories: true)
            try? alt.write(to: backupURL, atomically: true, encoding: .utf8)
        }
        try? neu.write(to: projekteMdURL, atomically: true, encoding: .utf8)
    }

    func markdownText(fuer atlas: AtlasDatei) -> String {
        var teile: [String] = []
        teile.append("<!-- Generiert von Projekt-Atlas — Projektdaten bitte in der App pflegen, Freitext-Abschnitte bleiben beim Export erhalten. -->")
        if !atlas.kopftext.isEmpty { teile.append(atlas.kopftext) }
        for gruppe in atlas.gruppen {
            let projekte = atlas.projekte.filter { $0.gruppe == gruppe }
            guard !projekte.isEmpty else { continue }
            var block = "## \(gruppe)\n"
            if let einleitung = atlas.gruppenEinleitungen[gruppe], !einleitung.isEmpty {
                block += "\n" + einleitung + "\n"
            }
            block += "\n| Projekt | Aliasse | Ordner | Details |\n|---|---|---|---|\n"
            block += projekte.map(tabellenzeile(fuer:)).joined(separator: "\n")
            teile.append(block)
        }
        if !atlas.fusstext.isEmpty { teile.append(atlas.fusstext) }
        return teile.joined(separator: "\n\n") + "\n"
    }

    private func tabellenzeile(fuer projekt: AtlasProjekt) -> String {
        let aliasse = projekt.aliasse.isEmpty
            ? "—"
            : projekt.aliasse.map { "„\($0)\u{201C}" }.joined(separator: ", ")
        let ordner = projekt.ordner.isEmpty
            ? "—"
            : projekt.ordner.map { "`\(lesbarerPfad($0))`" }.joined(separator: " + ")

        var details = saeubere(projekt.details ?? "")
        if let live = projekt.liveURL, !details.localizedCaseInsensitiveContains("live: " + live) {
            details += (details.isEmpty ? "" : " · ") + "live: " + live
        }
        if let remote = projekt.gitRemote, !details.contains(remote) {
            details += (details.isEmpty ? "" : " · ") + "Git: `\(remote)`"
        }
        if details.isEmpty { details = "—" }

        return "| **\(saeubere(projekt.klarname))** | \(saeubere(aliasse)) | \(ordner) | \(details) |"
    }

    /// Zellinhalte dürfen weder Pipes noch Zeilenumbrüche enthalten.
    private func saeubere(_ text: String) -> String {
        text.replacingOccurrences(of: "|", with: "·")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Pfad-Tokens

    func tokenisieren(_ absolut: String) -> String {
        if absolut.hasPrefix(projekteRoot.path + "/") {
            return "$PROJEKTE/" + String(absolut.dropFirst(projekteRoot.path.count + 1))
        }
        if absolut.hasPrefix(heimRoot.path + "/") {
            return "$HEIM/" + String(absolut.dropFirst(heimRoot.path.count + 1))
        }
        return absolut
    }

    func aufloesen(_ token: String) -> String {
        if token.hasPrefix("$PROJEKTE/") {
            return projekteRoot.path + "/" + String(token.dropFirst("$PROJEKTE/".count))
        }
        if token.hasPrefix("$HEIM/") {
            return heimRoot.path + "/" + String(token.dropFirst("$HEIM/".count))
        }
        return token
    }

    /// Für PROJEKTE.md und die Anzeige: maschinenneutrale ~-Notation
    /// (die Konvention der Original-Datei).
    func lesbarerPfad(_ token: String) -> String {
        if token.hasPrefix("$PROJEKTE/") {
            return "~/Projekte/" + String(token.dropFirst("$PROJEKTE/".count))
        }
        if token.hasPrefix("$HEIM/") {
            return "~/" + String(token.dropFirst("$HEIM/".count))
        }
        return token
    }

    // MARK: - Brücke zum Katalog

    func identitaeten(aus atlas: AtlasDatei) -> [ProjektIdentitaet] {
        atlas.projekte.map { projekt in
            ProjektIdentitaet(
                klarname: projekt.klarname,
                aliasse: projekt.aliasse,
                gruppe: projekt.gruppe,
                ordnerPfade: projekt.ordner.map(aufloesen),
                liveURL: projekt.liveURL,
                gitRemote: projekt.gitRemote,
                details: projekt.details,
                atlasID: projekt.id
            )
        }
    }

    /// Für den Watcher: extern geänderte atlas.json (Sync vom anderen Mac) einlesen.
    func dekodiere(_ daten: Data) -> AtlasDatei? {
        try? decoder.decode(AtlasDatei.self, from: daten)
    }

    // MARK: - Kleinteile

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
