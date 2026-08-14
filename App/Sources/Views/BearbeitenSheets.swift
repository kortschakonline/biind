import SwiftUI

// MARK: - Projekt bearbeiten

struct ProjektBearbeitenSheet: View {
    @Environment(KatalogStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let projekt: ProjektAkte

    @State private var klarname = ""
    @State private var aliasseText = ""
    @State private var gruppe = ""
    @State private var neueGruppe = ""
    @State private var liveURL = ""
    @State private var details = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Projekt bearbeiten")
                .font(.title2.bold())
            Form {
                TextField("Klarname", text: $klarname)
                TextField("Aliasse (mit Komma getrennt)", text: $aliasseText)
                Picker("Gruppe", selection: $gruppe) {
                    ForEach(store.gruppenNamen, id: \.self) { Text($0).tag($0) }
                }
                TextField("… oder neue Gruppe", text: $neueGruppe)
                TextField("Live-URL (ohne https://)", text: $liveURL)
                TextField("Notizen", text: $details, axis: .vertical)
                    .lineLimit(3...8)
            }
            .formStyle(.columns)
            HStack {
                Spacer()
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Sichern") { sichern() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(klarname.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 500)
        .onAppear { befuellen() }
    }

    private func befuellen() {
        klarname = projekt.klarname
        aliasseText = projekt.aliasse.joined(separator: ", ")
        gruppe = projekt.gruppe
        liveURL = projekt.liveURL ?? ""
        details = projekt.details ?? ""
    }

    private func sichern() {
        guard let atlasID = projekt.atlasID else { return }
        let aliasse = aliasseText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let zielGruppe = neueGruppe.trimmingCharacters(in: .whitespaces).isEmpty
            ? gruppe
            : neueGruppe.trimmingCharacters(in: .whitespaces)
        store.speichereProjekt(
            atlasID: atlasID,
            klarname: klarname.trimmingCharacters(in: .whitespaces),
            aliasse: aliasse,
            gruppe: zielGruppe,
            liveURL: liveURL.isEmpty ? nil : liveURL,
            details: details.isEmpty ? nil : details
        )
        dismiss()
    }
}

// MARK: - Ordner als neues Projekt aufnehmen

struct NeuesProjektSheet: View {
    @Environment(KatalogStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let ordnerPfad: String
    let vorschlag: String

    @State private var klarname = ""
    @State private var gruppe = ""
    @State private var neueGruppe = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Als neues Projekt aufnehmen")
                .font(.title2.bold())
            Text(ordnerPfad)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            Form {
                TextField("Klarname", text: $klarname)
                Picker("Gruppe", selection: $gruppe) {
                    ForEach(store.gruppenNamen, id: \.self) { Text($0).tag($0) }
                }
                TextField("… oder neue Gruppe", text: $neueGruppe)
            }
            .formStyle(.columns)
            HStack {
                Spacer()
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Aufnehmen") { aufnehmen() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(klarname.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear {
            klarname = vorschlag
            gruppe = store.gruppenNamen.first ?? ""
        }
    }

    private func aufnehmen() {
        let zielGruppe = neueGruppe.trimmingCharacters(in: .whitespaces).isEmpty
            ? gruppe
            : neueGruppe.trimmingCharacters(in: .whitespaces)
        store.neuesProjekt(
            ausOrdnerPfad: ordnerPfad,
            klarname: klarname.trimmingCharacters(in: .whitespaces),
            gruppe: zielGruppe
        )
        dismiss()
    }
}

// MARK: - Ordner einem bestehenden Projekt zuordnen

struct OrdnerZuordnenSheet: View {
    @Environment(KatalogStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let ordnerPfad: String

    @State private var auswahl: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Einem Projekt zuordnen")
                .font(.title2.bold())
            Text(ordnerPfad)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            List(selection: $auswahl) {
                ForEach(store.gruppenNamen, id: \.self) { gruppe in
                    let projekte = store.atlas.projekte.filter { $0.gruppe == gruppe }
                    if !projekte.isEmpty {
                        Section(gruppe) {
                            ForEach(projekte) { projekt in
                                Text(projekt.klarname).tag(projekt.id)
                            }
                        }
                    }
                }
            }
            .frame(height: 280)
            HStack {
                Spacer()
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Zuordnen") { zuordnen() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(auswahl == nil)
            }
        }
        .padding(20)
        .frame(width: 460)
    }

    private func zuordnen() {
        guard let auswahl else { return }
        store.ordneOrdnerZu(pfad: ordnerPfad, projektID: auswahl)
        dismiss()
    }
}
