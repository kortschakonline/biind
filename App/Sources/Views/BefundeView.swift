import SwiftUI
import AppKit

/// Die Gesundheits-Checks als Befundliste: Schweregrad-Chip, Titel, Erklärung,
/// betroffener Pfad mit „Zeigen"-Button.
struct BefundeView: View {
    let befunde: [Befund]

    @Environment(KatalogStore.self) private var store

    private struct QuellRef: Identifiable {
        let pfad: String
        var id: String { pfad }
    }

    private struct PaarRef: Identifiable {
        let pfadA: String
        let pfadB: String
        var id: String { pfadA + "|" + pfadB }
    }

    @State private var zusammenfuehrenQuelle: QuellRef?
    @State private var duplikatPaar: PaarRef?
    @State private var sshConfig: QuellRef?
    @State private var aufnehmenPfad: QuellRef?
    @State private var zuordnenPfad: QuellRef?
    @State private var papierkorbPfad: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gesundheits-Checks")
                        .font(.largeTitle.bold())
                    Text(zusammenfassung)
                        .foregroundStyle(.secondary)
                }

                if befunde.isEmpty {
                    ContentUnavailableView(
                        "Alles in Ordnung",
                        systemImage: "checkmark.seal",
                        description: Text("Keine Befunde in der Projektlandschaft.")
                    )
                }

                ForEach(befunde) { befund in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        chip(befund.schweregrad)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(befund.titel)
                                .fontWeight(.medium)
                            Text(befund.erklaerung)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            if let pfad = befund.pfad {
                                Text(kurz(pfad))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.tertiary)
                                    .textSelection(.enabled)
                            }
                        }
                        Spacer()
                        aktionen(fuer: befund)
                        if let pfad = befund.pfad {
                            Button("Zeigen") {
                                NSWorkspace.shared.activateFileViewerSelecting(
                                    [URL(fileURLWithPath: pfad)]
                                )
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(item: $zusammenfuehrenQuelle) { quelle in
            ZusammenfuehrenSheet(quellPfad: quelle.pfad)
        }
        .sheet(item: $duplikatPaar) { paar in
            DuplikatSheet(pfadA: paar.pfadA, pfadB: paar.pfadB)
        }
        .sheet(item: $sshConfig) { ref in
            SshUmstellenSheet(configPfad: ref.pfad)
        }
        .sheet(item: $aufnehmenPfad) { ref in
            NeuesProjektSheet(
                ordnerPfad: ref.pfad,
                vorschlag: URL(fileURLWithPath: ref.pfad).lastPathComponent
            )
        }
        .sheet(item: $zuordnenPfad) { ref in
            OrdnerZuordnenSheet(ordnerPfad: ref.pfad)
        }
        .alert(
            "In den Papierkorb legen?",
            isPresented: Binding(
                get: { papierkorbPfad != nil },
                set: { if !$0 { papierkorbPfad = nil } }
            )
        ) {
            Button("Abbrechen", role: .cancel) { papierkorbPfad = nil }
            Button("In den Papierkorb") {
                if let pfad = papierkorbPfad {
                    _ = store.legeOrdnerInPapierkorb(pfad: pfad)
                }
                papierkorbPfad = nil
            }
        } message: {
            Text("„\(papierkorbPfad.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "")\u{201C} wandert in den Finder-Papierkorb und lässt sich von dort wiederherstellen.")
        }
    }

    @ViewBuilder
    private func aktionen(fuer befund: Befund) -> some View {
        switch befund.art {
        case .verwaisterClaudeSpeicher:
            if let pfad = befund.pfad {
                Button("Zusammenführen …") { zusammenfuehrenQuelle = QuellRef(pfad: pfad) }
                    .buttonStyle(.borderedProminent)
            }
        case .duplikatVerdacht:
            if let pfadA = befund.pfad, let pfadB = befund.pfad2 {
                Button("Aufräumen …") { duplikatPaar = PaarRef(pfadA: pfadA, pfadB: pfadB) }
                    .buttonStyle(.borderedProminent)
            }
        case .tokenImGitConfig:
            if let pfad = befund.pfad {
                Button("Auf SSH umstellen …") { sshConfig = QuellRef(pfad: pfad) }
                    .buttonStyle(.borderedProminent)
            }
        case .leererOrdner:
            if let pfad = befund.pfad {
                Button("In den Papierkorb …") { papierkorbPfad = pfad }
            }
        case .ohneEintrag:
            if let pfad = befund.pfad {
                Button("Aufnehmen …") { aufnehmenPfad = QuellRef(pfad: pfad) }
                Button("Zuordnen …") { zuordnenPfad = QuellRef(pfad: pfad) }
            }
        case .allgemein:
            EmptyView()
        }
    }

    private var zusammenfassung: String {
        let kritisch = befunde.filter { $0.schweregrad == .kritisch }.count
        let warnungen = befunde.filter { $0.schweregrad == .warnung }.count
        let hinweise = befunde.filter { $0.schweregrad == .hinweis }.count
        return "\(kritisch) kritisch · \(warnungen) Warnungen · \(hinweise) Hinweise — automatisch geprüft, nichts verändert."
    }

    private func chip(_ schweregrad: Schweregrad) -> some View {
        Text(label(schweregrad))
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(farbe(schweregrad).opacity(0.15), in: Capsule())
            .foregroundStyle(farbe(schweregrad))
    }

    private func label(_ schweregrad: Schweregrad) -> String {
        switch schweregrad {
        case .kritisch: "KRITISCH"
        case .warnung: "WARNUNG"
        case .hinweis: "HINWEIS"
        }
    }

    private func farbe(_ schweregrad: Schweregrad) -> Color {
        switch schweregrad {
        case .kritisch: .red
        case .warnung: .orange
        case .hinweis: .teal
        }
    }

    private func kurz(_ pfad: String) -> String {
        pfad.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path,
            with: "~"
        )
    }
}
