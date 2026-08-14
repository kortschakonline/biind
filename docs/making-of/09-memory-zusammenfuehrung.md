# 09 · Memory-Zusammenführung: Die Heilung des Ursprungsproblems

**Datum:** 14.08.2026

## Ausgangslage

Der Kreis schließt sich: Das ganze Projekt begann mit dem Ärgernis, dass Claudes
Gedächtnis pfadgebunden ist und sich zwischen den Macs (oder nach Umbenennungen)
splittet. Die Gesundheits-Checks *finden* verwaiste Speicher seit Kapitel 06 —
jetzt können sie **geheilt** werden.

## Was passiert ist

1. **`MemoryZusammenfuehrer`** — die einzige schreibende Operation der App in
   `~/.claude`, und sie bleibt pro Fall bestätigungspflichtig. Prinzip:
   **verschieben, nie löschen.**
   - Sessions (`.jsonl` samt Zubehör-Ordnern) wandern in den aktiven Speicher
     des Zielordners; bei Namenskollision bleiben sie in der Quelle liegen.
   - Memories wandern nach `memory/`; Kollisionen werden mit Suffix
     `-zusammengefuehrt` umbenannt statt überschrieben.
   - Der `MEMORY.md`-Index wird vereinigt (fehlende Zeilen angehängt).
   - Die Quelle wird nur entfernt, wenn sie danach wirklich leer ist.
2. **Isolierter Test zuerst:** Statt an den echten Orphans zu üben, lief die
   Mechanik gegen einen künstlichen verwaisten Speicher mit präparierter
   Namenskollision — alle Erwartungen grün, Testreste restlos entfernt.
   Die echten Fälle (MDX, MDX-Kopie, Trofaiach-Animationen) gehören Jörn:
   Zusammenführen ist eine Menschen-Entscheidung per Klick.
3. **UI:** Verwaiste-Speicher-Befunde haben jetzt einen prominenten
   „Zusammenführen …"-Button. Das Sheet zeigt vorher, was in der Quelle liegt
   (n Sessions, m Memories), lässt Projekt + Ordner als Ziel wählen und
   berichtet hinterher exakt, was passiert ist — inklusive Umbenennungen
   und etwaiger Reste.

## Entscheidungen

- **Kollisions-Strategie asymmetrisch:** Session-Dateien (UUID-Namen) kollidieren
  praktisch nie — falls doch, ist Liegenlassen die sicherste Antwort. Memories
  kollidieren realistisch (gleicher Slug auf beiden Macs) — Umbenennen erhält
  beide Fassungen, und der Suffix macht das Duplikat beim nächsten
  Memory-Aufräumen sichtbar.
- **Bericht statt Vertrauen:** Das Sheet bestätigt nicht nur „fertig", sondern
  zählt nach — wer Daten verschiebt, soll sehen, was verschoben wurde.

## Ergebnis

Build fehlerfrei. Der Weg vom Befund „Verwaister Claude-Speicher" zur Heilung
ist jetzt: ein Klick, ein Ziel, eine Bestätigung. Damit ist das Problem, das
diese App ausgelöst hat, nicht nur sichtbar, sondern behandelbar.
