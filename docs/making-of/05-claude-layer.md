# 05 · Claude-Layer: Gedächtnis & Sessions sichtbar machen

**Datum:** 14.08.2026

## Ausgangslage

Bisher zeigte die Akte nur *Zahlen* über Claude (13 Sessions, 6 Memories).
Das Alleinstellungsmerkmal der App ist aber, die **Inhalte** sichtbar zu machen:
Was weiß Claude über dieses Projekt? Woran wurde zuletzt gearbeitet?

## Was passiert ist

Neuer Baustein `ClaudeLeser` (ausschließlich lesend — die App fasst `~/.claude/`
nie schreibend an):

1. **Memories als Karten.** Die `memory/*.md`-Dateien haben ein
   Frontmatter-Format (`name:`, `description:`, dann Inhalt). Der Leser parst
   das minimal selbst — keine YAML-Library für drei Felder. In der Akte werden
   sie als aufklappbare Karten gezeigt: Titel + Kurzbeschreibung, Klick öffnet
   den vollen Inhalt. **Damit ist Claudes Projektgedächtnis zum ersten Mal
   ohne Terminal lesbar.**
2. **Session-Verlauf mit Titeln.** Die `*.jsonl`-Transcripts können viele
   Megabyte groß sein — der Leser liest bewusst nur die ersten 256 KB und
   sucht darin: bevorzugt die `summary`-Zeile (Claudes eigene Zusammenfassung),
   sonst die erste echte Nutzer-Nachricht (Meta-Zeilen und `<`-Systemtags
   werden übersprungen). Ergebnis: eine Zeitleiste wie
   *„14. Aug 2026, 18:42 · hi! wir haben gerade ein Problem mit gesyncten…"*
3. **„Mit Claude weiterarbeiten".** Prominenter Button im Akten-Kopf: öffnet
   per AppleScript ein Terminal im Projektordner und startet `claude`.
   Beim ersten Klick fragt macOS einmalig nach der Automation-Berechtigung
   für Terminal — erwartbar und in Ordnung für ein persönliches Werkzeug.

Ladeverhalten: Memories/Sessions werden erst beim Öffnen einer Akte gelesen
(`.task(id:)`, auf einem Hintergrund-Task) — der App-Start bleibt sofort da.

## Entscheidungen

- **Nur-Lesen als Prinzip bestätigt:** Auch der Claude-Layer schreibt nichts.
  Die einzige spätere Ausnahme bleibt die bestätigte Memory-Zusammenführung (V2).
- **Best-effort statt Perfektion bei Session-Titeln:** Das JSONL-Format ist
  intern und kann sich ändern. Der Parser ist defensiv (jede Zeile einzeln,
  Fehler → überspringen) und liefert zur Not „Session" als Titel.
- **Terminal statt Deep-Link:** Ob die Claude-Desktop-App ein URL-Schema hat,
  ist undokumentiert — das Terminal funktioniert heute sicher. Kann später
  eleganter werden.

## Ergebnis

Build fehlerfrei. Die Akte beantwortet jetzt die Frage „Wo waren wir hier
stehengeblieben?" auf einen Blick: Gedächtnis-Karten + Session-Zeitleiste +
ein Klick zum Weiterarbeiten. Außerdem ab jetzt: **Git-Workflow** — Claude
committet selbstständig bei jedem Meilenstein und sagt nur kurz Bescheid
(erster Commit `1026562`, dieser Schritt ist der zweite).
