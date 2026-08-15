# 16 · Release: biind 1.0.0

**Datum:** 15.08.2026

## Ausgangslage

App fertig, Repo öffentlich, Icon aus Glas — fehlte noch der letzte Schritt
einer echten Veröffentlichung: eine Installationsdatei, die man weitergeben
kann. Bei Jörns Mac-Apps heißt das traditionell: eine DMG (MultiMonitor,
WiFiGuard lassen grüßen).

## Was passiert ist

1. **Version 1.0.0** — der Sprung von 0.1.0 war verdient: Alles aus dem
   Konzept ist gebaut, das Backlog leer, die Kür gelaufen.
2. **Release-Build & DMG:** `xcodebuild -configuration Release`, dann das
   klassische Rezept — Staging-Ordner mit `biind.app` + Symlink auf
   `/Applications`, `hdiutil create` (UDZO, komprimiert), Checksummen-Verify.
   Ergebnis: 961 KB. Die DMG bleibt außerhalb von Git (`release/` ist
   ignoriert) — der Verteilkanal ist das GitHub Release.
3. **Signatur-Realität, ehrlich dokumentiert:** Auf dem MacBook existiert
   keine Developer-ID (`security find-identity`: „0 valid identities") —
   die App ist **ad-hoc signiert**. Für die eigenen Macs egal; wer die DMG
   aus dem Internet lädt, bekommt einmalig die Gatekeeper-Warnung
   (Rechtsklick → Öffnen). Der Weg zur sauberen öffentlichen Verteilung —
   Apple Developer Program, Developer-ID, Notarisierung — steht offen,
   ist aber eine bewusste 99-€/Jahr-Entscheidung für später.
4. **GitHub Release v1.0.0** mit der DMG als Asset, deutschen Release-Notes,
   Gatekeeper-Hinweis und Links auf README und Making-Of:
   <https://github.com/kortschakonline/biind/releases/tag/v1.0.0>

## Ergebnis

biind ist installierbar — ein Doppelklick auf die DMG, ein Zug nach
Applications. Damit ist der Bogen komplett: Vom Sync-Ärgernis zweier Macs
über Konzept, App, Name, Logo und Icon bis zur Veröffentlichung mit
Versionsnummer. **Ende der Entstehungsgeschichte — Anfang des Alltags.**
