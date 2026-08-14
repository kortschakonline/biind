import SwiftUI
import AppKit

/// Die „Akte" eines Projekts: Identität oben, Kennzahlen, Ordner mit
/// Schnellaktionen, dann der Claude-Layer — das Projektgedächtnis als
/// aufklappbare Karten und der Session-Verlauf. Ordner, die auf diesem Mac
/// fehlen, werden als solche gezeigt (Zwei-Mac-Setup sichtbar machen).
struct ProjektAkteView: View {
    let projekt: ProjektAkte

    @State private var memories: [MemoryEintrag] = []
    @State private var sessions: [SessionEintrag] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                kopf
                kennzahlen
                ordnerListe
                if !memories.isEmpty { gedaechtnis }
                if !sessions.isEmpty { sessionListe }
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
        .task(id: projekt.id) {
            let ordner = projekt.ordner
            let geladen = await Task.detached(priority: .userInitiated) {
                let leser = ClaudeLeser()
                return (leser.memories(fuer: ordner), leser.sessions(fuer: ordner))
            }.value
            memories = geladen.0
            sessions = geladen.1
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
            if !projekt.ordner.isEmpty {
                Button {
                    claudeWeiterarbeiten()
                } label: {
                    Label("Mit Claude weiterarbeiten", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .help("Öffnet ein Terminal im Projektordner und startet Claude Code")
                .padding(.top, 6)
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
                        AktionsHelfer.imFinderZeigen(ordner.url)
                    }
                    Button("Terminal") {
                        AktionsHelfer.terminalOeffnen(bei: ordner.url)
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

    // MARK: - Claude-Layer

    private var gedaechtnis: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Claude-Gedächtnis")
                .font(.headline)
            ForEach(memories) { memory in
                DisclosureGroup {
                    Text(memory.inhalt)
                        .font(.callout)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 6)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(memory.name)
                            .fontWeight(.medium)
                        if !memory.beschreibung.isEmpty {
                            Text(memory.beschreibung)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var sessionListe: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sessions")
                .font(.headline)
            ForEach(sessions.prefix(12)) { session in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(session.datum?.formatted(date: .abbreviated, time: .shortened) ?? "—")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 130, alignment: .leading)
                    Text(session.titel)
                        .font(.callout)
                        .lineLimit(1)
                }
            }
            if sessions.count > 12 {
                Text("… \(sessions.count - 12) weitere")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Aktionen

    private func claudeWeiterarbeiten() {
        guard let ordner = projekt.ordner.first else { return }
        AktionsHelfer.claudeStarten(bei: ordner.url)
    }
}
