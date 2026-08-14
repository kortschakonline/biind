# 08 · V2: Die Daten-Umkehr — atlas.json wird die Quelle

**Datum:** 14.08.2026

## Ausgangslage

Bis hierhin war die handgepflegte PROJEKTE.md die Wahrheit und die App las nur.
V2 dreht das um: Die App hält die Daten in einer **atlas.json** im gesyncten
Ordner (`~/Projekte/.atlas/`), und PROJEKTE.md wird daraus **generiert** —
Claude liest sie weiter wie bisher, aber sie kann nicht mehr veralten.

## Was passiert ist

1. **atlas.json** mit Maschinen-Profilen: Pfade werden als Tokens gespeichert
   (`$PROJEKTE/Online-Freigabe-Tool`, `$HEIM/Kunden 2026/…`), jede Maschine
   registriert sich mit ihren eigenen Roots (MacBook: `~/Projekte`, Mac mini:
   `/Volumes/MacUser/Projekte`). **Damit ist das Zwei-Mac-Problem strukturell
   gelöst** — dieselbe atlas.json funktioniert auf beiden Rechnern.
2. **Einmalige Migration** aus PROJEKTE.md — inklusive Freitext-Erhalt:
   Kopftext, Gruppen-Einleitungen (der Trofaiach-Warnhinweis) und der gesamte
   Fusstext (Kunden-Ordner, Aufräumliste, Namens-Konvention — 2.400 Zeichen)
   wandern mit in die atlas.json und kommen beim Export wieder heraus.
3. **Export mit doppeltem Netz:** Das Original wird einmalig nach
   `.atlas/PROJEKTE-original-backup.md` gesichert, und geschrieben wird nur,
   wenn der Export sich selbst wieder sauber parsen lässt (Roundtrip-Guard).
4. **Verwalten-UI:** Drei Sheets — Projekt bearbeiten (Klarname, Aliasse,
   Gruppe, Live-URL, Notizen), Ordner **als neues Projekt aufnehmen** und
   Ordner **einem bestehenden Projekt zuordnen** (die beiden Heil-Aktionen für
   die „Nicht zugeordnet"-Gruppe). Jede Änderung: atlas.json speichern →
   PROJEKTE.md exportieren → Katalog neu aufbauen → Checks aktualisieren.

## Der Beinahe-Datenverlust (und warum Verifikation sich lohnt)

Der CLI-Roundtrip-Test war grün: 38 Projekte, alle Namen, Pfade, Aliasse
überleben. Aber beim Prüfen der **echten** generierten Datei fiel auf: Die
2-spaltige Trofaiach-Tabelle hatte ihre Anmerkungen *in der Ordner-Spalte*
(„(Python-Tools, XLSX, Stadtfest)", „⚠️ redundante Arbeitskopie") — der Parser
rettete nur die Pfade, die Notizen fehlten im Export. Zählwerte prüfen reicht
also nicht; man muss das Ergebnis *lesen*.

Fix: Der Parser rettet jetzt alles aus der Ordner-Zelle außer den Pfaden selbst
in die Details — auch Nicht-Pfad-Codespans wie Git-Remotes. Danach: Migration
zurückgerollt (Backup!), neu gebaut, neu migriert. Jetzt steht sogar das
„⚠️ historischer Name" vom Kortschak Studio wieder in der generierten Datei.

## Entscheidungen

- **Pfad-Tokens statt absoluter Pfade** — der Kern der Maschinen-Profile.
  In PROJEKTE.md bleibt die maschinenneutrale `~/Projekte`-Notation (Konvention
  der Original-Datei).
- **Konflikte:** Last-write-wins pro Projekt über den `geaendert`-Zeitstempel,
  atomare Schreibvorgänge. Echtes Merging ist Backlog — bei einem
  Ein-Personen-Workflow mit zwei Macs reicht das vorerst.
- **Roundtrip-Guard als Schreibsperre:** Lieber eine veraltete PROJEKTE.md als
  eine kaputte.
- **Bekannte Grenze:** Die Migration lief auf dem MacBook; liefe sie erstmals
  auf dem Mac mini, würden `~`-Pfade dort anders aufgelöst. Einmalig migrieren,
  dann syncen — so ist es gedacht und so ist es passiert.

## Ergebnis

`.atlas/atlas.json` (38 Projekte, 6 Gruppen, 1 Maschine) existiert, PROJEKTE.md
ist ab jetzt ein Generat mit Generator-Marker in Zeile 1, das Original liegt im
Backup. Bearbeiten, Aufnehmen und Zuordnen funktionieren aus der App heraus —
die „Nicht zugeordnet"-Gruppe kann jetzt per Klick abgearbeitet werden.
