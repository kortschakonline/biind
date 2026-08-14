import AppKit
import SwiftUI
import Carbon.HIToolbox

// MARK: - Globaler Hotkey (Carbon)

/// Registriert einen systemweiten Hotkey (⌥ Leertaste) über die klassische
/// Carbon-API — funktioniert ohne Zusatz-Framework und ohne Bedienungshilfen-
/// Berechtigung. Carbon liefert das Event auf dem Main-Thread.
final class HotkeyRegistrar {
    var onHotkey: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    func registriere() {
        var typ = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                Unmanaged<HotkeyRegistrar>.fromOpaque(userData)
                    .takeUnretainedValue().onHotkey?()
                return noErr
            },
            1, &typ,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
        let id = EventHotKeyID(signature: OSType(0x4A52_4E41), id: 1) // „JRNA"
        RegisterEventHotKey(
            UInt32(kVK_Space), UInt32(optionKey), id,
            GetApplicationEventTarget(), 0, &hotKeyRef
        )
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}

// MARK: - Panel

/// Randloses, schwebendes Panel im Spotlight-Stil. Schließt sich, sobald es
/// den Tastaturfokus verliert (Klick woanders hin).
final class SchwebePanel: NSPanel {
    var beimSchliessen: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        orderOut(nil)
        beimSchliessen?()
    }
}

// MARK: - Controller

@MainActor
final class SwitcherController {
    private let store: KatalogStore
    private var panel: SchwebePanel?
    private let hotkey = HotkeyRegistrar()

    init(store: KatalogStore) {
        self.store = store
        hotkey.onHotkey = { [weak self] in
            MainActor.assumeIsolated { self?.umschalten() }
        }
        hotkey.registriere()
    }

    func umschalten() {
        panel == nil ? zeigen() : verstecken()
    }

    func zeigen() {
        Task { await store.ladenFallsNoetig() }

        let inhalt = SwitcherView(store: store) { [weak self] in self?.verstecken() }
        let neu = SchwebePanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        neu.isOpaque = false
        neu.backgroundColor = .clear
        neu.hasShadow = true
        neu.level = .floating
        neu.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        neu.contentView = NSHostingView(rootView: inhalt)
        neu.beimSchliessen = { [weak self] in self?.panel = nil }
        if let schirm = NSScreen.main {
            let rahmen = schirm.visibleFrame
            neu.setFrameOrigin(NSPoint(x: rahmen.midX - 280, y: rahmen.midY - 80))
        }
        panel = neu
        NSApp.activate(ignoringOtherApps: true)
        neu.makeKeyAndOrderFront(nil)
    }

    func verstecken() {
        panel?.orderOut(nil)
        panel = nil
    }
}

// MARK: - View

struct SwitcherView: View {
    let store: KatalogStore
    let schliessen: () -> Void

    @State private var suche = ""
    @State private var markiert = 0
    @FocusState private var fokus: Bool

    private var treffer: [SucheService.Treffer] {
        SucheService.suche(suche, in: store.katalog)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                TextField("Projekt oder Alias …", text: $suche)
                    .textFieldStyle(.plain)
                    .font(.title2)
                    .focused($fokus)
                    .onSubmit { ausfuehren(.oeffnen) }
            }
            .padding(16)

            Divider()

            if treffer.isEmpty {
                Spacer()
                Text(suche.isEmpty
                     ? "Lade Projekte …"
                     : "Keine Treffer für „\(suche)\u{201C}")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Array(treffer.enumerated()), id: \.element.id) { index, eintrag in
                            zeile(eintrag, hervorgehoben: index == markiert)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    markiert = index
                                    ausfuehren(.oeffnen)
                                }
                        }
                    }
                    .padding(8)
                }
                Divider()
                Text("↩ öffnen      ⌘↩ Claude starten      ⌥↩ Finder      esc schließen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
        .frame(width: 560, height: 420)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .onAppear {
            markiert = 0
            DispatchQueue.main.async { fokus = true }
        }
        .onChange(of: suche) { markiert = 0 }
        .onKeyPress(.downArrow) {
            markiert = min(markiert + 1, max(treffer.count - 1, 0))
            return .handled
        }
        .onKeyPress(.upArrow) {
            markiert = max(markiert - 1, 0)
            return .handled
        }
        .onKeyPress(.escape) {
            schliessen()
            return .handled
        }
        .onKeyPress(keys: [.return]) { druck in
            if druck.modifiers.contains(.command) { ausfuehren(.claude); return .handled }
            if druck.modifiers.contains(.option) { ausfuehren(.finder); return .handled }
            return .ignored // einfaches ↩ läuft über onSubmit
        }
    }

    private func zeile(_ eintrag: SucheService.Treffer, hervorgehoben: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(eintrag.projekt.klarname)
                    .fontWeight(.medium)
                Text(untertitel(eintrag))
                    .font(.caption)
                    .foregroundStyle(hervorgehoben ? Color.white.opacity(0.8) : Color.secondary)
            }
            Spacer()
            if eintrag.projekt.hatClaude {
                Image(systemName: "brain")
                    .foregroundStyle(hervorgehoben ? Color.white : Color.teal)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            hervorgehoben ? Color.accentColor : Color.clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .foregroundStyle(hervorgehoben ? Color.white : Color.primary)
    }

    private func untertitel(_ eintrag: SucheService.Treffer) -> String {
        if let hinweis = eintrag.hinweis {
            return eintrag.projekt.gruppe + "  ·  „" + hinweis + "\u{201C}"
        }
        return eintrag.projekt.gruppe
    }

    private enum Modus { case oeffnen, claude, finder }

    private func ausfuehren(_ modus: Modus) {
        guard !treffer.isEmpty else { schliessen(); return }
        let projekt = treffer[min(markiert, treffer.count - 1)].projekt
        schliessen()
        switch modus {
        case .oeffnen:
            store.auswahl = projekt.id
            AktionsHelfer.hauptfensterZeigen()
        case .claude:
            if let url = projekt.ordner.first?.url { AktionsHelfer.claudeStarten(bei: url) }
        case .finder:
            if let url = projekt.ordner.first?.url { AktionsHelfer.imFinderZeigen(url) }
        }
    }
}
