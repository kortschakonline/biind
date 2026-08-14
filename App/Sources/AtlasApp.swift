import SwiftUI
import AppKit

@main
struct AtlasApp: App {
    @State private var store: KatalogStore
    @State private var switcher: SwitcherController

    init() {
        let store = KatalogStore()
        _store = State(initialValue: store)
        _switcher = State(initialValue: SwitcherController(store: store))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .defaultSize(width: 960, height: 640)

        MenuBarExtra("biind", systemImage: "square.grid.3x3") {
            Button("Quick-Switcher  (⌥ Leertaste)") { switcher.umschalten() }
            Button("Hauptfenster zeigen") { AktionsHelfer.hauptfensterZeigen() }
            Divider()
            Button("Beenden") { NSApp.terminate(nil) }
        }
    }
}
