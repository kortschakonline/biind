# 07 · Quick-Switcher: ⌥ Leertaste

**Datum:** 14.08.2026

## Ausgangslage

Der Quick-Switcher stand eigentlich in V3 — aber er ist das Feature für jeden
Tag, und die Alias-Suche aus Kapitel 04 war schon die halbe Miete. Also
vorgezogen. Ziel: von überall im System **⌥ Leertaste** drücken, „portal"
tippen, Enter — und im Kortschak Studio landen.

## Was passiert ist

Vier Bausteine in einem Schritt:

1. **`KatalogStore`-Refactoring.** Bisher hielt das Hauptfenster die Daten
   lokal. Jetzt teilen sich Hauptfenster und Switcher einen `@Observable`-Store
   (Katalog, Befunde, Auswahl) — der Switcher kann so die Auswahl im
   Hauptfenster setzen. Schnellaktionen (Finder/Terminal/Claude) wanderten
   dedupliziert in einen `AktionsHelfer`.
2. **Globaler Hotkey über Carbon.** `RegisterEventHotKey` ist Ur-Mac-API,
   funktioniert aber bis heute — ohne Zusatz-Framework und ohne
   Bedienungshilfen-Berechtigung. ~40 Zeilen inklusive C-Callback.
3. **Schwebendes Panel im Spotlight-Stil.** Randloses `NSPanel`
   (`.nonactivatingPanel`, Level floating, auf allen Spaces), Material-Hintergrund,
   schließt sich beim Fokusverlust von selbst. `canBecomeKey` muss überschrieben
   werden — randlose Panels verweigern sonst die Tastatur.
4. **Ranking-Suche.** Klarname schlägt Alias schlägt Ordnername, Präfix schlägt
   Enthalten. Der Untertitel erklärt den Treffer („Kortschak · ‚das Portal‘"),
   damit man versteht, *warum* etwas gefunden wurde. Ohne Eingabe: die zuletzt
   bearbeiteten Projekte (aus den Claude-Session-Daten!). Tastatur:
   ↑↓ wählen, ↩ öffnen, ⌘↩ startet Claude direkt im Projekt, ⌥↩ Finder, esc weg.

Dazu ein **Menüleisten-Eintrag** (MenuBarExtra) mit Switcher, Hauptfenster
und Beenden — die App ist damit auch bei geschlossenem Fenster erreichbar.

## Entscheidungen

- **Carbon statt Package-Dependency:** Für einen einzigen Hotkey lohnt kein
  SPM-Paket. Die Carbon-API ist deprecated-aber-stabil seit 20 Jahren.
- **⌥ Leertaste als Default** — bewusst nah an Spotlight (⌘ Leertaste).
  Konfigurierbarkeit kommt, wenn sie gebraucht wird.
- **Panel aktiviert die App**, statt Alfred-artig „unsichtbar" zu bleiben —
  garantiert zuverlässigen Tastaturfokus. Verfeinerung möglich, wenn es stört.
- **„Zuletzt bearbeitet" als Leer-Zustand:** Die Session-Zeitstempel aus dem
  Claude-Layer machen den Switcher schon beim Öffnen nützlich — die acht
  zuletzt angefassten Projekte, ohne einen Buchstaben zu tippen.

## Ergebnis

Build fehlerfrei auf Anhieb (das erste Mal in diesem Projekt!). ⌥ Leertaste →
tippen → Enter: Der Weg von „wie hieß der Ordner nochmal?" zu „drin" ist jetzt
unter zwei Sekunden. Damit ist auch das letzte Stück V1 plus der wichtigste
V3-Baustein fertig.
