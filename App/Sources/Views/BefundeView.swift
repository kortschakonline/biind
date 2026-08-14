import SwiftUI
import AppKit

/// Die Gesundheits-Checks als Befundliste: Schweregrad-Chip, Titel, Erklärung,
/// betroffener Pfad mit „Zeigen"-Button.
struct BefundeView: View {
    let befunde: [Befund]

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
