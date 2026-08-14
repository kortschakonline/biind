import SwiftUI

struct ContentView: View {
    @State private var katalog = Katalog()
    @State private var auswahl: ProjektAkte.ID?
    @State private var suche = ""

    var body: some View {
        NavigationSplitView {
            List(selection: $auswahl) {
                ForEach(gefilterteGruppen) { gruppe in
                    Section(gruppe.name) {
                        ForEach(gruppe.projekte) { projekt in
                            zeile(fuer: projekt)
                                .tag(projekt.id)
                        }
                    }
                }
            }
            .searchable(text: $suche, prompt: "Name oder Alias …")
            .navigationTitle("Projekte")
            .navigationSplitViewColumnWidth(min: 230, ideal: 280)
        } detail: {
            if let projekt = katalog.alleProjekte.first(where: { $0.id == auswahl }) {
                ProjektAkteView(projekt: projekt)
            } else {
                ContentUnavailableView(
                    "Kein Projekt ausgewählt",
                    systemImage: "square.grid.2x2",
                    description: Text("\(katalog.alleProjekte.count) Projekte in \(katalog.gruppen.count) Gruppen.")
                )
            }
        }
        .task { katalog = KatalogBuilder().build() }
    }

    /// Sucht in Klarnamen, Aliassen und Ordnernamen — „portal" findet das
    /// Kortschak Studio. Der Vorgeschmack auf den späteren Quick-Switcher.
    private var gefilterteGruppen: [Katalog.Gruppe] {
        guard !suche.isEmpty else { return katalog.gruppen }
        return katalog.gruppen.compactMap { gruppe in
            let treffer = gruppe.projekte.filter { $0.passt(zu: suche) }
            return treffer.isEmpty ? nil : Katalog.Gruppe(name: gruppe.name, projekte: treffer)
        }
    }

    private func zeile(fuer projekt: ProjektAkte) -> some View {
        HStack {
            Text(projekt.klarname)
                .lineLimit(1)
            Spacer()
            if projekt.hatClaude {
                Image(systemName: "brain")
                    .foregroundStyle(.teal)
                    .help("Claude-Daten vorhanden")
            }
            if projekt.gitOhneRemote {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(Color.orange)
                    .help("Git ohne Remote")
            }
        }
    }
}
