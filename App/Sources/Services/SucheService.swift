import Foundation

/// Ranking-Suche für den Quick-Switcher: Klarname schlägt Alias schlägt
/// Ordnername, Präfix schlägt Enthalten. „portal" → Kortschak Studio.
enum SucheService {

    struct Treffer: Identifiable, Hashable {
        let projekt: ProjektAkte
        /// Was den Treffer erklärt, wenn nicht der Klarname passte (Alias/Ordner).
        let hinweis: String?
        var id: String { projekt.id }
    }

    static func suche(_ text: String, in katalog: Katalog) -> [Treffer] {
        let suchtext = text.trimmingCharacters(in: .whitespaces).lowercased()

        guard !suchtext.isEmpty else {
            // Ohne Eingabe: zuletzt bearbeitete Projekte
            return katalog.alleProjekte
                .sorted { ($0.letzteSession ?? .distantPast) > ($1.letzteSession ?? .distantPast) }
                .prefix(8)
                .map { Treffer(projekt: $0, hinweis: nil) }
        }

        var bewertet: [(Treffer, Int)] = []
        for projekt in katalog.alleProjekte {
            var punkte = 0
            var hinweis: String?

            let name = projekt.klarname.lowercased()
            if name == suchtext { punkte = 100 }
            else if name.hasPrefix(suchtext) { punkte = 90 }
            else if name.contains(suchtext) { punkte = 70 }

            for alias in projekt.aliasse {
                let a = alias.lowercased()
                if a == suchtext { if punkte < 95 { punkte = 95; hinweis = alias } }
                else if a.hasPrefix(suchtext) { if punkte < 85 { punkte = 85; hinweis = alias } }
                else if a.contains(suchtext) { if punkte < 65 { punkte = 65; hinweis = alias } }
            }

            if punkte < 60 {
                for ordner in projekt.ordner where ordner.name.lowercased().contains(suchtext) {
                    if punkte < 55 { punkte = 55; hinweis = ordner.name }
                }
            }

            if punkte > 0 { bewertet.append((Treffer(projekt: projekt, hinweis: hinweis), punkte)) }
        }

        return bewertet
            .sorted { $0.1 == $1.1 ? $0.0.projekt.klarname < $1.0.projekt.klarname : $0.1 > $1.1 }
            .prefix(8)
            .map(\.0)
    }
}
