import SwiftUI

/// Bestätigungs-Dialog für die Memory-Zusammenführung: zeigt, was in der
/// verwaisten Quelle liegt, lässt das Ziel wählen und berichtet das Ergebnis.
struct ZusammenfuehrenSheet: View {
    @Environment(KatalogStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let quellPfad: String

    @State private var auswahl: String?
    @State private var bericht: MemoryZusammenfuehrer.Bericht?
    @State private var quellSessions = 0
    @State private var quellMemories = 0

    private var quellName: String { URL(fileURLWithPath: quellPfad).lastPathComponent }

    private var kandidaten: [(projekt: String, ordner: ProjektOrdner)] {
        store.katalog.alleProjekte.flatMap { projekt in
            projekt.ordner.map { (projekt.klarname, $0) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let bericht {
                ergebnis(bericht)
            } else {
                formular
            }
        }
        .padding(20)
        .frame(width: 520)
        .onAppear { zaehleQuelle() }
    }

    // MARK: - Formular

    private var formular: some View {
        Group {
            Text("Claude-Speicher zusammenführen")
                .font(.title2.bold())
            VStack(alignment: .leading, spacing: 3) {
                Text(quellName)
                    .font(.caption.monospaced())
                Text("\(quellSessions) Sessions · \(quellMemories) Memories werden in den aktiven Speicher des gewählten Ordners verschoben.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            List(selection: $auswahl) {
                ForEach(kandidaten, id: \.ordner.id) { eintrag in
                    HStack {
                        Text(eintrag.projekt)
                        Spacer()
                        Text(eintrag.ordner.name)
                            .foregroundStyle(.secondary)
                    }
                    .tag(eintrag.ordner.url.path)
                }
            }
            .frame(height: 260)

            Text("Es wird nur verschoben, nie gelöscht. Sessions mit gleichem Namen bleiben in der Quelle, Memory-Doppel werden umbenannt.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Zusammenführen") { ausfuehren() }
                    .buttonStyle(.borderedProminent)
                    .disabled(auswahl == nil)
            }
        }
    }

    // MARK: - Ergebnis

    private func ergebnis(_ bericht: MemoryZusammenfuehrer.Bericht) -> some View {
        Group {
            Label("Zusammengeführt", systemImage: "checkmark.seal")
                .font(.title2.bold())
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(bericht.sessions) Sessions, \(bericht.memories) Memories und \(bericht.sonstiges) weitere Einträge verschoben.")
                if !bericht.umbenannt.isEmpty {
                    Text("Wegen Namensgleichheit umbenannt: \(bericht.umbenannt.joined(separator: ", "))")
                        .foregroundStyle(.secondary)
                }
                if bericht.zurueckgeblieben > 0 {
                    Text("\(bericht.zurueckgeblieben) Einträge blieben in der Quelle (Namenskollision) — Quelle wurde nicht entfernt.")
                        .foregroundStyle(.orange)
                }
                if bericht.quelleEntfernt {
                    Text("Der verwaiste Speicher war danach leer und wurde entfernt.")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.callout)
            HStack {
                Spacer()
                Button("Fertig") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    // MARK: - Aktionen

    private func zaehleQuelle() {
        let fm = FileManager.default
        let oben = (try? fm.contentsOfDirectory(atPath: quellPfad)) ?? []
        quellSessions = oben.filter { $0.hasSuffix(".jsonl") }.count
        let memory = (try? fm.contentsOfDirectory(atPath: quellPfad + "/memory")) ?? []
        quellMemories = memory.filter { $0.hasSuffix(".md") && $0 != "MEMORY.md" }.count
    }

    private func ausfuehren() {
        guard let zielPfad = auswahl else { return }
        bericht = store.fuehreSpeicherZusammen(quellPfad: quellPfad, zielOrdnerPfad: zielPfad)
    }
}
