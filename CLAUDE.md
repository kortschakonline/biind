# Projekt-Atlas (Arbeitstitel) — Mac-App zur Verwaltung der Claude-Projekte

Native SwiftUI-App (macOS), die Jörns Projektlandschaft verwaltet: Projekt-Identitäten
(Klarname, Aliasse, Kunde) getrennt von Ordnern, Claude-Memories/Sessions sichtbar,
Gesundheits-Checks, Quick-Switcher. Konzept:
<https://claude.ai/code/artifact/220bf16b-5beb-4d8f-a952-fbe390b9dee6>

## ⚠️ WICHTIGSTE REGEL: Making-Of-Pflicht

**Jeder wichtige Arbeitsschritt wird in `docs/making-of/` dokumentiert** — Entscheidungen,
Werkzeuge, Konzepte, Fehlschläge, Meilensteine. Regeln und Kapitelindex in
`docs/making-of/README.md`. Am Ende soll zeigbar sein, was alles nötig war, um diese
App zu bauen. Neue Kapitel: fortlaufend nummerieren, Index-Tabelle aktualisieren.
Diese Doku ist Teil des Produkts, nicht lästige Pflicht — entsprechend sorgfältig schreiben.

## Git-Workflow (von Jörn so gewünscht)

Claude kümmert sich **selbstständig** um Git: bei jedem abgeschlossenen Meilenstein
committen (aussagekräftige deutsche Message) und Jörn nur **kurz Bescheid geben** —
nicht fragen, ob committet werden soll. Perspektive: Wenn die App gut wird, soll sie
über GitHub veröffentlicht werden — Repo entsprechend sauber halten (keine Secrets,
keine privaten Pfad-Interna in Doku-Beispielen, die nicht ohnehin erzählt werden).

## Struktur

- `App/` — XcodeGen-Projekt (`project.yml` ist die Quelle, `.xcodeproj` wird generiert und ist gitignored)
- `App/Sources/` — Swift-Code
- `docs/making-of/` — die Entstehungsgeschichte (siehe oben)
- `docs/assets/` — Screenshots, Grafiken fürs Making-Of

## Build

```bash
cd App && xcodegen generate && xcodebuild -project Atlas.xcodeproj -scheme Atlas -configuration Debug build
```

## Konventionen & Stand

- **Name offen:** Arbeitstitel „Projekt-Atlas" / Target „Atlas". Shortlist in
  `docs/making-of/02-namensfindung.md` — Jörn entscheidet. Danach: Logo, dann
  App-Icon über die macOSicons-API (liegt in `~/Projekte/Icons`, `.env` + `test-api.sh`).
  **Wichtig:** Logo/Icon ist ein bewusster Design-Prozess („soll cool werden, nicht
  so nebenbei") — nicht einfach schnell generieren, sondern mit Jörn als eigenen
  Schritt gestalten (Richtungen, Varianten, Entscheidung) und im Making-Of dokumentieren.
- UI-Sprache Deutsch, Code/Bezeichner Englisch mit deutschen Domänenbegriffen wo sinnvoll.
- Kein App Sandbox (App liest `~/Projekte` + `~/.claude` direkt; kein App-Store-Ziel).
- Datenhaltung später: `atlas.json` im gesyncten Projekte-Ordner; `PROJEKTE.md` wird generiert.
- Roadmap: V1 read-only Kartei → V2 Verwalten/Heilen → V3 Quick-Switcher/MCP (Details im Konzept).
- **Stand 14.08.2026 (abends):** Kapitel 00–06 fertig: Skelett, PROJEKTE.md-Import,
  Claude-Layer (Memory-Karten, Session-Zeitleiste, „Mit Claude weiterarbeiten"),
  Gesundheits-Checks (11 Checks, Sidebar „Gesundheit", beim ersten Lauf 32 echte
  Befunde inkl. 2 neuer Sicherheitsfunde). Offen: Name/Logo/Icon (wartet auf Jörn),
  danach V2 (atlas.json, PROJEKTE.md-Export, Maschinen-Profile, geführtes Aufräumen).
