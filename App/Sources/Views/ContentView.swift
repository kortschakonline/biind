import SwiftUI

struct ContentView: View {
    private static let gesundheitID = "__gesundheit__"

    @Environment(KatalogStore.self) private var store
    @State private var suche = ""

    var body: some View {
        @Bindable var store = store
        NavigationSplitView {
            List(selection: $store.auswahl) {
                Section {
                    Label("Gesundheit", systemImage: "stethoscope")
                        .badge(store.befunde.count)
                        .tag(Self.gesundheitID)
                }
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
            if store.auswahl == Self.gesundheitID {
                BefundeView(befunde: store.befunde)
            } else if let projekt = store.katalog.alleProjekte.first(where: { $0.id == store.auswahl }) {
                ProjektAkteView(projekt: projekt)
            } else {
                ContentUnavailableView(
                    "Kein Projekt ausgewählt",
                    systemImage: "square.grid.2x2",
                    description: Text("\(store.katalog.alleProjekte.count) Projekte in \(store.katalog.gruppen.count) Gruppen. ⌥ Leertaste öffnet den Quick-Switcher.")
                )
            }
        }
        .task { await store.ladenFallsNoetig() }
    }

    /// Sucht in Klarnamen, Aliassen und Ordnernamen — „portal" findet das
    /// Kortschak Studio.
    private var gefilterteGruppen: [Katalog.Gruppe] {
        guard !suche.isEmpty else { return store.katalog.gruppen }
        return store.katalog.gruppen.compactMap { gruppe in
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
