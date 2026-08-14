import SwiftUI

// MARK: - Duplikat aufräumen

/// Zeigt beide Kandidaten mit Kennzahlen und lässt wählen, welcher ins
/// Archiv wandert. Vorauswahl: der Ordner, der NICHT in der Landkarte steht.
struct DuplikatSheet: View {
    @Environment(KatalogStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let pfadA: String
    let pfadB: String

    @State private var archivieren: String?
    @State private var ergebnis: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let ergebnis {
                Label("Archiviert", systemImage: "checkmark.seal")
                    .font(.title2.bold())
                    .foregroundStyle(.green)
                Text("Der Ordner liegt jetzt unter \(kurz(ergebnis)). Verschieben lässt sich jederzeit rückgängig machen.")
                    .font(.callout)
                HStack {
                    Spacer()
                    Button("Fertig") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
            } else {
                Text("Mögliches Duplikat aufräumen")
                    .font(.title2.bold())
                Text("Welcher der beiden Ordner soll ins Archiv (~/Projekte/_Archiv)?")
                    .foregroundStyle(.secondary)
                Picker("", selection: $archivieren) {
                    ForEach([pfadA, pfadB], id: \.self) { pfad in
                        kandidat(pfad).tag(Optional(pfad))
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                Text("Es wird nur verschoben, nichts gelöscht. Hat der Ordner einen Claude-Speicher, wird der danach als verwaist gemeldet — dann einfach zusammenführen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Button("Abbrechen") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                    Button("Ins Archiv verschieben") {
                        if let pfad = archivieren {
                            ergebnis = store.archiviereOrdner(pfad: pfad)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(archivieren == nil)
                }
            }
        }
        .padding(20)
        .frame(width: 540)
        .onAppear {
            let aImAtlas = store.istImAtlas(pfad: pfadA)
            let bImAtlas = store.istImAtlas(pfad: pfadB)
            if aImAtlas != bImAtlas {
                archivieren = aImAtlas ? pfadB : pfadA
            }
        }
    }

    private func kandidat(_ pfad: String) -> some View {
        let url = URL(fileURLWithPath: pfad)
        let anzahl = ((try? FileManager.default.contentsOfDirectory(atPath: pfad)) ?? [])
            .filter { $0 != ".DS_Store" }.count
        let datum = (try? FileManager.default.attributesOfItem(atPath: pfad)[.modificationDate] as? Date)
            .map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "—"
        let imAtlas = store.istImAtlas(pfad: pfad)
        return VStack(alignment: .leading, spacing: 2) {
            Text(url.lastPathComponent)
                .fontWeight(.medium)
            Text("\(anzahl) Einträge · geändert \(datum)\(imAtlas ? " · steht in der Landkarte" : "")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }

    private func kurz(_ pfad: String) -> String {
        pfad.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"
        )
    }
}

// MARK: - Git-Remote auf SSH umstellen

struct SshUmstellenSheet: View {
    @Environment(KatalogStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let configPfad: String

    @State private var alt = ""
    @State private var neu = ""
    @State private var umgestellt = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if umgestellt {
                Label("Remote umgestellt", systemImage: "checkmark.seal")
                    .font(.title2.bold())
                    .foregroundStyle(.green)
                Text("Die alte config liegt als Backup daneben (config.atlas-backup).")
                    .font(.callout)
                Text("⚠️ Wichtig: Das alte Token bei GitHub jetzt widerrufen (Settings → Developer settings → Tokens) — das kann die App nicht für dich tun.")
                    .font(.callout)
                    .foregroundStyle(.orange)
                HStack {
                    Spacer()
                    Button("Fertig") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
            } else if alt.isEmpty {
                Text("Remote auf SSH umstellen")
                    .font(.title2.bold())
                Text("Kein umstellbares github.com-HTTPS-Remote gefunden — bitte manuell prüfen.")
                    .foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Button("Schließen") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            } else {
                Text("Remote auf SSH umstellen")
                    .font(.title2.bold())
                VStack(alignment: .leading, spacing: 6) {
                    Label {
                        Text(alt)
                            .font(.caption.monospaced())
                            .strikethrough()
                    } icon: {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.red)
                    }
                    Label {
                        Text(neu)
                            .font(.caption.monospaced())
                    } icon: {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green)
                    }
                }
                Text("Die alte config wird vorher als Backup gesichert. Voraussetzung: Ein SSH-Key ist bei GitHub hinterlegt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Button("Abbrechen") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                    Button("Umstellen") {
                        umgestellt = store.stelleGitRemoteUm(configPfad: configPfad) != nil
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(20)
        .frame(width: 560)
        .onAppear {
            if let vorschau = AufraeumHelfer().sshVorschau(configPfad: configPfad) {
                alt = vorschau.alt
                neu = vorschau.neu
            }
        }
    }
}
