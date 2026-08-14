# 02 · Namensfindung

**Datum:** 14.08.2026 · **Status: offen** — Jörn denkt weiter nach

## Kriterien

1. Funktioniert als Mac-App-Name: kurz, gut im Dock und in der Menüleiste
2. Deutsch oder sprachneutral, passend zur Marke JRN.digital
3. Erzählt die Kernidee — Überblick, Zuordnung, Navigation durch die Projektlandschaft
4. Kein Konflikt mit bekannten Apps/Marken (finale Prüfung vor Fixierung!)
5. Erst nach der Namens-Entscheidung: Logo → App-Icon (macOSicons-API)

## Shortlist (Claude, erste Runde)

| Name | Idee dahinter | Risiko |
|---|---|---|
| **Projektor** | Wortspiel Projekt + Projektor — „wirft alle Projekte an die Wand" | generisches Wort, Nähe zu Video-Apps |
| **Kontor** | das historische Handelsbüro, die Schaltzentrale des Hauses | Kontor Records (Musik, andere Branche) |
| **Lotse** | kennt jedes Fahrwasser und jeden Spitznamen — passt zum Quick-Switcher | eher Dienst als Ort; weniger „Übersicht" |
| **Kataster** | das amtliche Verzeichnis, das Flächen ihren Eigentümern zuordnet — exakt die Kernidee (Ordner ↔ Identität) | klingt amtlich-trocken (kann aber Charme sein) |
| **Atlas** | der Arbeitstitel; knüpft an die „Landkarte" (PROJEKTE.md) an | in Software sehr verbreitet (MongoDB Atlas u. a.) |

## Kandidaten von Jörn (in Prüfung)

| Name | Stärken | Schwächen (Recherche 15.08.2026) |
|---|---|---|
| **Orbito** | passt in die scano-Familie (zweisilbig, -o, freundlich), eindeutige Aussprache DE/EN, starke Bildwelt (Projekte im Orbit → Logo-Potenzial) | „Orbito" existiert bereits im Mac App Store (Brettspiel-Umsetzung); Orbit-Metapher im Mac-Utility-Raum überlaufen (Orbit, Orbital, OrbitRing, Expo Orbit — teils Launcher, unser Quick-Switcher-Terrain) |
| **biind** ⭐ Jörns Favorit | Bedeutung trifft den Kern exakt (bindet Ordner ↔ Identität, Gedächtnis ↔ Projekt, Mac ↔ Mac); Doppel-i erzählbar (zwei Macs / zwei Welten) und als Logo-Leitidee stark (zwei i-Punkte, verbunden); scano-Familie; kurz, modern | visuelle Nähe zu „blind"; Buchstabier-Reibung („mit Doppel-i" — flickr-Effekt); schwache Kollision: BIIND Music (Pre-Seed-Musik-Streaming, anderer Sektor, kein Mac-Store-Eintrag) — bei Kommerzialisierung erneut prüfen, `biind.app`-Domain checken |

Abgeleiteter Funke aus der Orbito-Diskussion: **„karto"** — die Landkarte, im
scano-Stil. Noch ungeprüft.

## Verworfen

| Name | Idee | Warum verworfen (15.08.2026) |
|---|---|---|
| **ProCen** (Jörn) | Kontraktion aus „Projekt-Zentrale" | Aussprache stolpert (deutsch „Prozen" ≈ „Prozent", englisch „Pro-Sen"), schwimmt im Meer der Pro-Kontraktionen (ProCount, Prokon, ProDG …) und erzählt nichts vom Charakter der App. Kollisionsprüfung war immerhin frei. Abgeleiteter Twist „ProZen" (Zen im Projektchaos) bleibt als Option im Raum. |

## Zwischenstand

Solange kein Name fixiert ist, läuft alles unter **Arbeitstitel „Projekt-Atlas"**
(Xcode-Target: `Atlas`). Bundle-ID und Anzeigename sind bewusst leicht änderbar
gehalten — die Umbenennung kostet später eine Zeile in `project.yml`.
