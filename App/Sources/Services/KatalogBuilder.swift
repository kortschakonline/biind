import Foundation

/// Verheiratet die beiden Wahrheiten: die Projekt-Identitäten (aus atlas.json,
/// bei der Migration einmalig aus PROJEKTE.md) und die real gescannten Ordner.
/// Ordner ohne Eintrag landen in „Nicht zugeordnet".
struct KatalogBuilder {
    private let fm = FileManager.default

    func build(identitaeten: [ProjektIdentitaet], root: URL) -> Katalog {
        let scanner = OrdnerScanner(root: root)
        let gescannt = scanner.scan()
        var freieOrdner = Dictionary(uniqueKeysWithValues: gescannt.map { ($0.url.path, $0) })

        var gruppen: [Katalog.Gruppe] = []

        for identitaet in identitaeten {
            var gefunden: [ProjektOrdner] = []
            var fehlend: [String] = []

            for pfad in identitaet.ordnerPfade {
                if let ordner = freieOrdner.removeValue(forKey: pfad) {
                    gefunden.append(ordner)
                } else if istOrdner(pfad) {
                    // liegt außerhalb des Projekte-Roots (z. B. ~/Kunden 2026)
                    gefunden.append(scanner.einzelOrdner(bei: URL(fileURLWithPath: pfad)))
                } else {
                    fehlend.append(pfad)
                }
            }

            let akte = ProjektAkte(
                id: identitaet.atlasID?.uuidString ?? identitaet.id,
                atlasID: identitaet.atlasID,
                klarname: identitaet.klarname,
                aliasse: identitaet.aliasse,
                gruppe: identitaet.gruppe,
                liveURL: identitaet.liveURL,
                gitRemote: identitaet.gitRemote,
                details: identitaet.details,
                ordner: gefunden,
                fehlendeOrdner: fehlend
            )
            if let index = gruppen.firstIndex(where: { $0.name == identitaet.gruppe }) {
                gruppen[index].projekte.append(akte)
            } else {
                gruppen.append(.init(name: identitaet.gruppe, projekte: [akte]))
            }
        }

        let rest = freieOrdner.values
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        if !rest.isEmpty {
            gruppen.append(.init(name: "Nicht zugeordnet", projekte: rest.map { ordner in
                ProjektAkte(
                    id: "frei/" + ordner.name,
                    atlasID: nil,
                    klarname: ordner.name,
                    aliasse: [],
                    gruppe: "Nicht zugeordnet",
                    liveURL: nil,
                    gitRemote: nil,
                    details: nil,
                    ordner: [ordner],
                    fehlendeOrdner: []
                )
            }))
        }
        return Katalog(gruppen: gruppen)
    }

    private func istOrdner(_ pfad: String) -> Bool {
        var istVerzeichnis: ObjCBool = false
        return fm.fileExists(atPath: pfad, isDirectory: &istVerzeichnis) && istVerzeichnis.boolValue
    }
}
