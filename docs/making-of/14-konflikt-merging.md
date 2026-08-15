# 14 · Konflikt-Merging: Zwei Macs, eine Wahrheit

**Datum:** 15.08.2026

## Ausgangslage

Das letzte Backlog-Stück. Bisher galt beim Sync „letzte Datei gewinnt komplett":
Ändert Jörn am Mac mini Projekt X und am MacBook gleichzeitig Projekt Y,
überschreibt die später gesyncte atlas.json die frühere — eine der beiden
Änderungen ist weg. Seit Jörn tatsächlich parallel an beiden Macs sitzt,
ist das kein theoretisches Problem mehr.

## Was passiert ist

1. **`AtlasMerger`** — Union statt Überschreiben: Projekte werden per UUID
   vereinigt, bei beidseitiger Änderung gewinnt der jüngere
   `geaendert`-Zeitstempel, einseitig Neues überlebt immer. Gruppen und
   Maschinen als Union, Freitexte von der Seite mit dem jüngsten Zeitstempel
   (fehlende Gruppen-Einleitungen von der anderen ergänzt).
2. **Konfliktkopien-Sweep:** Legt MEGA bei Gleichzeitigkeit ein Duplikat an
   („atlas (1).json"), wird es beim Laden und bei jedem Watcher-Event
   verschmolzen und ins `konflikt-archiv/` verschoben — verschieben statt
   löschen, wie immer.
3. **Store-Integration:** Der Watcher ersetzt externe Stände nicht mehr,
   er verschmilzt sie. Hat die eigene Seite etwas beizutragen, geht die Union
   zurück in den Sync; ist der externe Stand schon vollständig, wird nur
   übernommen.

## Der Befund des Schritts: die Ping-Pong-Falle

Der CLI-Test prüfte auch **Symmetrie**: merge(A⊕B) muss denselben Stand ergeben
wie merge(B⊕A). Die erste Fassung fiel durch — jede Seite behielt *ihre*
Gruppen-Reihenfolge, hätte also nach jedem Sync ihr abweichendes Ergebnis
zurückgespeichert: eine **endlose Ping-Pong-Schleife** über MEGA, harmlos für
die Daten, aber Dauerfeuer für den Sync. Fix: Die Reihenfolgen sind kanonisch —
die jüngere Seite gibt sie vor. Damit konvergieren beide Maschinen nach einem
Durchlauf auf den identischen Stand, und es gibt nichts mehr zurückzuschreiben.

Ohne den Symmetrie-Test wäre das erst aufgefallen, wenn MEGA heißgelaufen wäre.

## Bekannte Grenzen (ehrlich)

- **Granularität Projekt, nicht Feld:** Ändern beide Macs *dasselbe* Projekt,
  gewinnt der jüngere Datensatz komplett — Feld-Merging wäre die nächste Stufe.
- **Kein Löschen, keine Tombstones:** Die App kann Projekte bisher nicht
  löschen, „fehlt auf einer Seite" heißt daher immer „neu". Kommt je eine
  Lösch-Funktion, braucht sie Löschmarken.

## Ergebnis

Build fehlerfrei, alle Merge-Tests grün (jünger gewinnt, beidseitiges Überleben,
Unionen, Symmetrie, Konfliktkopie-Sweep mit Archiv). Das Zwei-Mac-Szenario ist
damit vollständig: Pfade pro Maschine aufgelöst (Kapitel 08), externe Syncs
live übernommen (Kapitel 10), Gleichzeitigkeit verschmolzen (dieses Kapitel).
**Das Backlog ist leer.**
