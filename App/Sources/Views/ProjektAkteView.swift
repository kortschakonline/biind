import SwiftUI
import AppKit

/// Die „Akte" eines Projekts: Identität oben, Kennzahlen, dann alle Ordner
/// mit Schnellaktionen. Ordner, die auf diesem Mac fehlen, werden als solche
/// gezeigt — das Zwei-Mac-Setup soll sichtbar sein, nicht verwirren.
struct ProjektAkteView: View {
    let projekt: ProjektAkte

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                kopf
                kennzahlen
                ordnerListe
                if let details = projekt.details, !details.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notizen aus PROJEKTE.md")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(details)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Kopf

    private var kopf: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(projekt.gruppe)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            HStack(spacing: 12) {
                Text(projekt.klarname)
                    .font(.largeTitle.bold())
                if let live = projekt.liveURL {
                    Button {
                        if let url = URL(string: "https://" + live) {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Label(live, systemImage: "globe")
                    }
                    .buttonStyle(.link)
                    .help("Live-Seite öffnen")
                }
            }
            if !projekt.aliasse.isEmpty {
                Text(projekt.aliasse.map { "„\($0)\u{201C}" }.joined(separator: "  ·  "))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Kennzahlen

    private var kennzahlen: some View {
        HStack(spacing: 12) {
            kachel(
                titel: "Claude-Sessions",
                wert: projekt.hatClaude ? "\(projekt.sessionCount)" : "—",
                symbol: "bubble.left.and.bubble.right"
            )
            kachel(
                titel: "Memories",
                wert: projekt.hatClaude ? "\(projekt.memoryCount)" : "—",
                symbol: "brain"
            )
            kachel(
                titel: "Zuletzt",
                wert: projekt.letzteSession.map {
                    $0.formatted(.relative(presentation: .named))
                } ?? "—",
                symbol: "clock"
            )
            if let remote = projekt.gitRemote {
                kachel(titel: "Git-Remote", wert: remote, symbol: "arrow.triangle.branch")
            } else if projekt.gitOhneRemote {
                kachel(titel: "Git", wert: "ohne Remote ⚠️", symbol: "arrow.triangle.branch")
            }
        }
    }

    private func kachel(titel: String, wert: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(titel, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(wert)
                .font(.title3.weight(.medium))
                .monospacedDigit()
                .lineLimit(1)
        }
        .padding(12)
        .frame(minWidth: 120, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Ordner

    private var ordnerListe: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(projekt.ordner.count == 1 ? "Ordner" : "\(projekt.ordner.count) Ordner")
                .font(.headline)

            ForEach(projekt.ordner) { ordner in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ordner.name)
                            .fontWeight(.medium)
                        Text(ordner.url.path)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    if let claude = ordner.claude {
                        Text("\(claude.sessionCount) Sessions · \(claude.memoryCount) Memories")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if ordner.hatGit && !ordner.hatGitRemote {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Color.orange)
                            .help("Git ohne Remote")
                    }
                    Button("Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([ordner.url])
                    }
                    Button("Terminal") {
                        openTerminal(bei: ordner.url)
                    }
                }
                .padding(10)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }

            ForEach(projekt.fehlendeOrdner, id: \.self) { pfad in
                HStack(spacing: 10) {
                    Image(systemName: "externaldrive.badge.questionmark")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pfad)
                            .font(.caption.monospaced())
                        Text("Auf diesem Mac nicht gefunden — liegt vermutlich auf dem anderen Rechner.")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func openTerminal(bei url: URL) {
        let prozess = Process()
        prozess.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        prozess.arguments = ["-a", "Terminal", url.path]
        try? prozess.run()
    }
}
