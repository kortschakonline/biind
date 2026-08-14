import AppKit

/// Zentrale Schnellaktionen — von Projektakte, Quick-Switcher und Menüleiste geteilt.
@MainActor
enum AktionsHelfer {

    static func imFinderZeigen(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    static func terminalOeffnen(bei url: URL) {
        let prozess = Process()
        prozess.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        prozess.arguments = ["-a", "Terminal", url.path]
        try? prozess.run()
    }

    /// Öffnet ein Terminal im Ordner und startet `claude`.
    /// Beim ersten Mal fragt macOS nach der Automation-Berechtigung für Terminal.
    static func claudeStarten(bei url: URL) {
        let prozess = Process()
        prozess.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        prozess.arguments = [
            "-e", "on run argv",
            "-e", "tell application \"Terminal\"",
            "-e", "activate",
            "-e", "do script \"cd \" & quoted form of item 1 of argv & \" && claude\"",
            "-e", "end tell",
            "-e", "end run",
            url.path,
        ]
        try? prozess.run()
    }

    static func hauptfensterZeigen() {
        NSApp.activate(ignoringOtherApps: true)
        if let fenster = NSApp.windows.first(where: { !($0 is SchwebePanel) && $0.canBecomeMain }) {
            fenster.makeKeyAndOrderFront(nil)
        }
    }
}
