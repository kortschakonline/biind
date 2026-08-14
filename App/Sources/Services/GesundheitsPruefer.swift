import Foundation

/// Die automatisierte Aufräumliste: prüft die Projektlandschaft auf bekannte
/// Problemmuster. Alles nur lesend, alles best effort — ein Befund ist ein
/// Hinweis zum Nachschauen, kein Urteil.
struct GesundheitsPruefer {

    func pruefe(katalog: Katalog, projekteRoot: URL? = nil) -> [Befund] {
        let projekte = katalog.alleProjekte
        let alleOrdner = projekte.flatMap(\.ordner)
        var projektVon: [String: String] = [:]
        for projekt in projekte {
            for ordner in projekt.ordner { projektVon[ordner.url.path] = projekt.id }
        }

        var befunde: [Befund] = []
        befunde += zugangsdatenInGitConfig(alleOrdner)
        befunde += passwortDateien(alleOrdner)
        befunde += liveOhneVersionierung(projekte)
        befunde += gitOhneRemote(projekte)
        befunde += duplikatVerdacht(alleOrdner, projektVon: projektVon)
        befunde += leerzeichenInNamen(alleOrdner)
        befunde += praktischLeereOrdner(alleOrdner)
        befunde += nodeModulesFunde(alleOrdner)
        befunde += ohneEintragInProjekteMd(katalog)
        befunde += fehlendeOrdner(projekte)
        befunde += verwaisterClaudeSpeicher(alleOrdner, projekteRoot: projekteRoot)

        return befunde.sorted {
            $0.schweregrad == $1.schweregrad
                ? $0.titel.localizedCaseInsensitiveCompare($1.titel) == .orderedAscending
                : $0.schweregrad > $1.schweregrad
        }
    }

    // MARK: - Kritisch

    /// Token oder eingebettete Zugangsdaten in `.git/config`.
    private func zugangsdatenInGitConfig(_ alleOrdner: [ProjektOrdner]) -> [Befund] {
        alleOrdner.compactMap { ordner in
            guard ordner.hatGit,
                  let config = try? String(
                    contentsOf: ordner.url.appendingPathComponent(".git/config"),
                    encoding: .utf8
                  ) else { return nil }
            let tokenMuster = ["ghp_", "github_pat_", "glpat-", "x-access-token"]
            let hatToken = tokenMuster.contains { config.contains($0) }
                || config.range(of: #"https://[^/\s@]+@"#, options: .regularExpression) != nil
            guard hatToken else { return nil }
            return Befund(
                schweregrad: .kritisch,
                titel: "Zugangsdaten in .git/config: \(ordner.name)",
                erklaerung: "Die Git-Konfiguration enthält offenbar ein Token oder Passwort im Klartext. Token widerrufen und das Remote auf SSH umstellen.",
                pfad: ordner.url.appendingPathComponent(".git/config").path
            )
        }
    }

    /// Datei- oder Ordnernamen, die nach gespeicherten Passwörtern klingen.
    private func passwortDateien(_ alleOrdner: [ProjektOrdner]) -> [Befund] {
        alleOrdner.flatMap { ordner in
            suchePasswortNamen(in: ordner.url, tiefe: 3).map { fund in
                Befund(
                    schweregrad: .kritisch,
                    titel: "Mögliche Klartext-Passwörter: \(URL(fileURLWithPath: fund).lastPathComponent)",
                    erklaerung: "Der Name deutet auf gespeicherte Passwörter im gesyncten Ordner hin. Prüfen und in einen Passwort-Manager überführen.",
                    pfad: fund
                )
            }
        }
    }

    private func suchePasswortNamen(in url: URL, tiefe: Int) -> [String] {
        guard tiefe > 0 else { return [] }
        let kinder = (try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        )) ?? []
        var funde: [String] = []
        for kind in kinder.prefix(2000) {
            let name = kind.lastPathComponent.lowercased()
            if name == "node_modules" { continue }
            if name.contains("passwör") || name.contains("passwort") || name.contains("password") {
                funde.append(kind.path)
                continue // Fund reicht — nicht weiter absteigen
            }
            if (try? kind.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                funde += suchePasswortNamen(in: kind, tiefe: tiefe - 1)
            }
        }
        return funde
    }

    // MARK: - Warnungen

    /// Ein Projekt ist live, aber nirgends mit Git-Remote gesichert.
    private func liveOhneVersionierung(_ projekte: [ProjektAkte]) -> [Befund] {
        projekte.compactMap { projekt in
            guard let live = projekt.liveURL,
                  !projekt.ordner.isEmpty,
                  !projekt.ordner.contains(where: { $0.hatGit && $0.hatGitRemote })
            else { return nil }
            return Befund(
                schweregrad: .warnung,
                titel: "Live, aber ohne Git-Remote: \(projekt.klarname)",
                erklaerung: "Das Projekt läuft produktiv (\(live)), ist aber nirgends extern versioniert. Ein Platten- oder Sync-Schaden wäre nicht wiederherstellbar.",
                pfad: projekt.ordner.first?.url.path
            )
        }
    }

    private func duplikatVerdacht(_ alleOrdner: [ProjektOrdner], projektVon: [String: String]) -> [Befund] {
        let sortiert = alleOrdner.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        var befunde: [Befund] = []
        for i in sortiert.indices {
            for j in sortiert.indices.dropFirst(i + 1) {
                let a = sortiert[i], b = sortiert[j]
                guard projektVon[a.url.path] != projektVon[b.url.path] else { continue }
                let na = normalisiert(a.name), nb = normalisiert(b.name)
                guard !na.isEmpty, !nb.isEmpty else { continue }

                let verdacht: Bool
                if min(na.count, nb.count) < 4 {
                    verdacht = na == nb
                } else {
                    verdacht = na == nb
                        || ((na.hasPrefix(nb) || nb.hasPrefix(na)) && abs(na.count - nb.count) <= 3)
                        || levenshtein(na, nb) <= 2
                }
                guard verdacht else { continue }
                befunde.append(Befund(
                    schweregrad: .warnung,
                    titel: "Mögliches Duplikat: \(a.name) ↔ \(b.name)",
                    erklaerung: "Zwei Ordner mit fast gleichem Namen in verschiedenen Projekten — Arbeitskopie, Tippfehler-Doppel oder Überbleibsel? Eines behalten, das andere archivieren.",
                    pfad: a.url.path
                ))
            }
        }
        return befunde
    }

    private func leerzeichenInNamen(_ alleOrdner: [ProjektOrdner]) -> [Befund] {
        alleOrdner.compactMap { ordner in
            guard ordner.name != ordner.name.trimmingCharacters(in: .whitespaces) else { return nil }
            return Befund(
                schweregrad: .warnung,
                titel: "Leerzeichen am Rand des Ordnernamens: „\(ordner.name)\u{201C}",
                erklaerung: "Führende/abschließende Leerzeichen machen Ärger in Skripten, Terminals und beim Sync.",
                pfad: ordner.url.path
            )
        }
    }

    /// Claude-Speicher, dem kein existierender Ordner mehr zuzuordnen ist —
    /// die sichtbar gemachte Folge des pfadgebundenen Gedächtnisses.
    private func verwaisterClaudeSpeicher(_ alleOrdner: [ProjektOrdner], projekteRoot: URL?) -> [Befund] {
        let scanner = OrdnerScanner(root: projekteRoot)
        let fm = FileManager.default
        let heim = fm.homeDirectoryForCurrentUser
        let claudeRoot = heim.appendingPathComponent(".claude/projects")
        guard let eintraege = try? fm.contentsOfDirectory(at: claudeRoot, includingPropertiesForKeys: [.isDirectoryKey])
        else { return [] }

        var bekannt: Set<String> = [
            scanner.claudeOrdnerName(fuer: heim),
            scanner.claudeOrdnerName(fuer: scanner.projekteRoot),
        ]
        for ordner in alleOrdner {
            bekannt.insert(scanner.claudeOrdnerName(fuer: ordner.url))
            let kinder = (try? fm.contentsOfDirectory(
                at: ordner.url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
            )) ?? []
            for kind in kinder { bekannt.insert(scanner.claudeOrdnerName(fuer: kind)) }
        }

        let heimPraefix = scanner.claudeOrdnerName(fuer: heim) + "-"
        var befunde: [Befund] = []
        for eintrag in eintraege {
            let name = eintrag.lastPathComponent
            guard name.hasPrefix("-"), istOrdner(eintrag.path), !bekannt.contains(name) else { continue }
            if name.hasPrefix(heimPraefix) {
                let rest = String(name.dropFirst(heimPraefix.count))
                let kandidaten = [
                    heim.appendingPathComponent(rest).path,
                    scanner.projekteRoot.appendingPathComponent(rest).path,
                ]
                if kandidaten.contains(where: istOrdner) { continue }
            }
            befunde.append(Befund(
                schweregrad: .warnung,
                titel: "Verwaister Claude-Speicher: \(name)",
                erklaerung: "Kein passender Projektordner gefunden — vermutlich umbenannt, verschoben oder gelöscht. Die Sessions und Memories darin sind vom Projekt getrennt.",
                pfad: eintrag.path,
                art: .verwaisterClaudeSpeicher
            ))
        }
        return befunde
    }

    // MARK: - Hinweise

    /// Lokales Git ohne Remote (bei nicht-live Projekten nur ein Hinweis).
    private func gitOhneRemote(_ projekte: [ProjektAkte]) -> [Befund] {
        projekte.filter { $0.liveURL == nil }.flatMap { projekt in
            projekt.ordner
                .filter { $0.hatGit && !$0.hatGitRemote }
                .map { ordner in
                    Befund(
                        schweregrad: .hinweis,
                        titel: "Git ohne Remote: \(ordner.name)",
                        erklaerung: "Nur lokal versioniert — kein Backup der Historie außerhalb dieses Rechners.",
                        pfad: ordner.url.path
                    )
                }
        }
    }

    private func praktischLeereOrdner(_ alleOrdner: [ProjektOrdner]) -> [Befund] {
        alleOrdner.compactMap { ordner in
            let inhalt = ((try? FileManager.default.contentsOfDirectory(atPath: ordner.url.path)) ?? [])
                .filter { $0 != ".DS_Store" }
            guard inhalt.count <= 1 else { return nil }
            return Befund(
                schweregrad: .hinweis,
                titel: "Praktisch leerer Ordner: \(ordner.name)",
                erklaerung: inhalt.isEmpty
                    ? "Der Ordner ist leer — Kandidat zum Aufräumen."
                    : "Enthält nur „\(inhalt[0])\u{201C} — Kandidat zum Aufräumen oder Zusammenlegen.",
                pfad: ordner.url.path
            )
        }
    }

    private func nodeModulesFunde(_ alleOrdner: [ProjektOrdner]) -> [Befund] {
        let fm = FileManager.default
        var funde: [String] = []
        for ordner in alleOrdner {
            var kandidaten = [ordner.url.appendingPathComponent("node_modules")]
            let kinder = (try? fm.contentsOfDirectory(
                at: ordner.url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
            )) ?? []
            kandidaten += kinder.map { $0.appendingPathComponent("node_modules") }
            funde += kandidaten.map(\.path).filter(istOrdner)
        }
        guard !funde.isEmpty else { return [] }
        return [Befund(
            schweregrad: .hinweis,
            titel: "node_modules im Sync-Ordner (\(funde.count)×)",
            erklaerung: "Abhängigkeits-Ordner kosten Platz und Sync-Zeit (MEGA) — bei Bedarf vom Sync ausschließen. Gefunden: "
                + funde.map(kurzPfad).joined(separator: "  ·  "),
            pfad: nil
        )]
    }

    private func ohneEintragInProjekteMd(_ katalog: Katalog) -> [Befund] {
        katalog.gruppen
            .first { $0.name == "Nicht zugeordnet" }?
            .projekte.compactMap { projekt in
                guard let ordner = projekt.ordner.first else { return nil }
                return Befund(
                    schweregrad: .hinweis,
                    titel: "Ohne Eintrag in PROJEKTE.md: \(projekt.klarname)",
                    erklaerung: "Der Ordner steht nicht in der Landkarte — eintragen, einem Projekt zuordnen oder aufräumen.",
                    pfad: ordner.url.path
                )
            } ?? []
    }

    private func fehlendeOrdner(_ projekte: [ProjektAkte]) -> [Befund] {
        projekte.flatMap { projekt in
            projekt.fehlendeOrdner.map { pfad in
                Befund(
                    schweregrad: .hinweis,
                    titel: "Auf diesem Mac nicht vorhanden: \(URL(fileURLWithPath: pfad).lastPathComponent)",
                    erklaerung: "In PROJEKTE.md für „\(projekt.klarname)\u{201C} referenziert, hier aber nicht gefunden — liegt vermutlich auf dem anderen Rechner (\(kurzPfad(pfad))).",
                    pfad: nil
                )
            }
        }
    }

    // MARK: - Kleinteile

    private func istOrdner(_ pfad: String) -> Bool {
        var istVerzeichnis: ObjCBool = false
        return FileManager.default.fileExists(atPath: pfad, isDirectory: &istVerzeichnis)
            && istVerzeichnis.boolValue
    }

    private func kurzPfad(_ pfad: String) -> String {
        pfad.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~")
    }

    private func normalisiert(_ name: String) -> String {
        String(name.lowercased().filter { $0.isLetter || $0.isNumber })
    }

    private func levenshtein(_ a: String, _ b: String) -> Int {
        let aa = Array(a), bb = Array(b)
        if aa.isEmpty || bb.isEmpty { return max(aa.count, bb.count) }
        var vorher = Array(0...bb.count)
        var aktuell = [Int](repeating: 0, count: bb.count + 1)
        for i in 1...aa.count {
            aktuell[0] = i
            for j in 1...bb.count {
                let kosten = aa[i - 1] == bb[j - 1] ? 0 : 1
                aktuell[j] = min(vorher[j] + 1, aktuell[j - 1] + 1, vorher[j - 1] + kosten)
            }
            swap(&vorher, &aktuell)
        }
        return vorher[bb.count]
    }
}
