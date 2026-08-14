# 00 · Idee & Konzept

**Datum:** 14.08.2026

## Ausgangslage

Auslöser war ein konkretes Ärgernis: Zwei Macs (MacBook + Mac mini) syncen den
`Projekte`-Ordner über MEGA, aber unter **verschiedenen lokalen Pfaden**
(`~/Projekte` vs. `/Volumes/MacUser/Projekte`). Gerade erst wurde ein Problem mit
gesyncten `.md`-Dateien behoben — und dabei wurde klar: Das ist ein Strukturproblem.

Dazu kam ein zweites, älteres Problem: **Ordnernamen veralten.** Der Ordner
`Online-Freigabe-Tool` enthält längst das komplette „Kortschak Studio" mit
Zeiterfassung, Dateiablage, QR-Verwaltung und Nachrichten. Die Zuordnung von
Spitznamen („das Portal") zu Ordnern lebte nur in einer handgepflegten
`PROJEKTE.md` und im Kopf.

Die Idee: **eine eigene Mac-App, die die Claude-Projekte übersichtlich verwaltet
und darstellt.**

## Was passiert ist

Claude hat zuerst die reale Lage vermessen statt ins Blaue zu konzipieren:

- `PROJEKTE.md` gelesen (die „Landkarte" mit Aliassen, Ordnern, URLs, Aufräumliste)
- `~/.claude/projects/` inventarisiert: **31 Projektordner, 353 MB** an
  Session-Transcripts und Memory-Dateien
- Festgestellt: Claudes Gedächtnis ist **pfadkodiert**
  (`-Users-jornmartin-Projekte-...`) — auf dem Mac mini entsteht durch den anderen
  Pfad ein *anderer* Ordner. Das Wissen splittet sich zwischen den Maschinen.

Daraus entstand das Konzept **„Projekt-Atlas"** (Arbeitstitel).

## Entscheidungen

1. **Kernidee: Projekt ≠ Ordner.** Die App führt eine Identitäts-Ebene ein
   (Klarname, Aliasse, Kunde, Status), an der beliebig viele Ordner, Claude-Memories,
   Git-Repos und Live-URLs hängen.
2. **Fünf Bausteine:** Projektkartei · Claude-Layer (Memories/Sessions sichtbar
   machen) · Gesundheits-Checks (automatisierte Aufräumliste) · Quick-Switcher
   (Aliasse verstehen) · Maschinen-Profile (löst das Zwei-Pfade-Problem).
3. **Datenhaltung ohne Server:** eine `atlas.json` im gesyncten Ordner selbst;
   `PROJEKTE.md` wird künftig daraus *generiert*, damit Claude sie weiter lesen kann.
4. **Roadmap in drei Stufen:** V1 read-only (Kartei + Schnellaktionen),
   V2 Verwalten & Heilen, V3 Quick-Switcher + Session-Browser + MCP-Server.

## Ergebnis

Konzeptdokument als Artifact:
<https://claude.ai/code/artifact/220bf16b-5beb-4d8f-a952-fbe390b9dee6>

Freigabe durch Jörn („klingt alles schon sehr gut") mit einer wichtigen Auflage:
**Die Entstehung der App wird bei jedem wichtigen Schritt dokumentiert** — genau
dieses Making-Of.
