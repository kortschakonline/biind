# 01 · Projekt-Setup & Werkzeuge

**Datum:** 14.08.2026

## Ausgangslage

Konzept ist freigegeben (Kapitel 00). Bevor Code entsteht, braucht es: eine
Projektstruktur, die Doku-Infrastruktur (dieses Making-Of), Werkzeuge und die
Einbettung in die bestehende Projektlandschaft.

## Was passiert ist

**Werkzeug-Inventur** auf dem MacBook:

| Werkzeug | Stand | Zweck |
|---|---|---|
| Xcode 26.6 | vorhanden | Build-System, SDK |
| Swift 6.3.3 | vorhanden | Sprache |
| git 2.50.1 | vorhanden | Versionierung |
| XcodeGen | **neu installiert** (`brew install xcodegen`) | generiert `.xcodeproj` aus lesbarer `project.yml` |

**Projektstruktur** angelegt:

```
Projekte Mac-App/
├── CLAUDE.md              ← Arbeitsregeln für Claude (inkl. Making-Of-Pflicht!)
├── .gitignore
├── App/
│   ├── project.yml        ← Quelle des Xcode-Projekts (XcodeGen)
│   └── Sources/           ← Swift-Code
└── docs/
    ├── making-of/         ← diese Doku
    └── assets/            ← Screenshots & Grafiken
```

**Einbettung:** Zeile in `~/Projekte/PROJEKTE.md` ergänzt (Namens-Konvention:
neues Projekt → sofort eintragen), Claude-Projekt-Memory angelegt, Git-Repo
initialisiert (Branch `main`).

## Entscheidungen

1. **XcodeGen statt handgeklicktem Xcode-Projekt.** Die `.xcodeproj`-Datei ist
   ein unlesbares Binärformat-Monster — als generiertes Artefakt fliegt sie aus
   Git raus, und die gesamte Projektkonfiguration steht in ~25 Zeilen YAML.
   Auch fürs Making-Of besser: Man *sieht*, was konfiguriert wurde.
2. **Making-Of-Pflicht in CLAUDE.md verankert.** Damit gilt sie für jede künftige
   Claude-Session in diesem Ordner automatisch — nicht nur, solange jemand daran denkt.
3. **Kein App Sandbox.** Die App muss `~/Projekte` und `~/.claude` frei lesen;
   sie ist ein persönliches Werkzeug, kein App-Store-Kandidat. Hardened Runtime
   bleibt an (für spätere Weitergabe/Notarisierung).
4. **Arbeitstitel bleibt „Projekt-Atlas"**, bis der Name fixiert ist (Kapitel 02).
   Anzeigename und Bundle-ID hängen an je einer Zeile in `project.yml`.

## Ergebnis

Lauffähige Werkzeugkette: `xcodegen generate && xcodebuild … build` produziert
eine startbare App. Erster Commit steht noch aus.
