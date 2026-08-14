import Foundation
import CoreServices

/// Beobachtet den Projekte-Root über FSEvents — verzeichnisweise (nicht pro
/// Datei), also mit minimalen Kosten. Änderungen kommen gebündelt auf dem
/// Main-Thread an; die Filterung, was relevant ist, macht der Aufrufer.
final class OrdnerWatcher {
    var onAenderung: (([String]) -> Void)?
    private var stream: FSEventStreamRef?

    func start(pfad: String) {
        stop()
        var kontext = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil, release: nil, copyDescription: nil
        )
        let callback: FSEventStreamCallback = { _, info, _, eventPfade, _, _ in
            guard let info else { return }
            let selbst = Unmanaged<OrdnerWatcher>.fromOpaque(info).takeUnretainedValue()
            let cfArray = unsafeBitCast(eventPfade, to: CFArray.self)
            let pfade = (cfArray as NSArray).compactMap { $0 as? String }
            selbst.onAenderung?(pfade)
        }
        stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &kontext,
            [pfad] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer))
        )
        guard let stream else { return }
        FSEventStreamSetDispatchQueue(stream, .main)
        FSEventStreamStart(stream)
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    deinit { stop() }
}
