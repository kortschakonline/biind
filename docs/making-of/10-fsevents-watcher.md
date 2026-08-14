# 10 · FSEvents-Watcher: Die App wird lebendig

**Datum:** 14.08.2026

## Ausgangslage

Bisher las die App den Ist-Zustand beim Start. Wer während der Arbeit einen
Ordner anlegte, sah ihn erst nach einem Neustart. Das Konzept versprach mehr:
Die App erkennt neue Ordner selbst und fragt *„Neues Projekt oder Teil eines
bestehenden?"*

## Was passiert ist

1. **`OrdnerWatcher`** über die FSEvents-API — bewusst **verzeichnisweise**
   statt pro Datei: Events kommen als „in diesem Verzeichnis hat sich etwas
   getan". Der Store filtert auf zwei relevante Orte: den Projekte-Root selbst
   (→ Ordner kam dazu / verschwand / wurde umbenannt) und das
   `.atlas`-Verzeichnis (→ atlas.json wurde geändert). Alles Tiefere —
   Dateispeichern in Projekten, Build-Artefakte, MEGA-Kleinkram — wird
   ignoriert. Dazu 1 s FSEvents-Latenz plus 1,2 s Debounce im Store.
2. **Der Zwei-Mac-Bonus:** Ändert sich die atlas.json **von außen** (MEGA synct
   die Version vom Mac mini heran), erkennt der Store das am Byte-Vergleich mit
   dem zuletzt selbst Geschriebenen und übernimmt den externen Stand —
   Katalog und Checks aktualisieren sich. Die beiden Macs bleiben damit ohne
   Zutun konsistent (letzter Schreiber gewinnt).
3. **Banner statt Dialog:** Neue unzugeordnete Ordner erscheinen als
   unaufdringlicher Banner am Fensterrand — „Neuer Ordner erkannt" mit
   **Als Projekt aufnehmen**, **Zuordnen** und **Später**. Kein modales
   Fenster, das die Arbeit unterbricht; wer den Banner wegklickt, findet den
   Ordner weiter in „Nicht zugeordnet". Verschwindet der Ordner wieder
   (oder wird er zugeordnet), räumt sich der Hinweis selbst auf.

## Entscheidungen

- **Verzeichnisweise Events statt `FileEvents`-Flag:** In einem Ordner, den
  MEGA permanent anfasst, wäre ein Datei-genauer Stream ein Dauerfeuer.
  Die grobe Variante reicht exakt für die zwei Fragen, die uns interessieren.
- **Eigene Schreibvorgänge erkennen:** Der Store merkt sich die Bytes der
  zuletzt selbst geschriebenen atlas.json. Ohne diesen Vergleich würde jeder
  eigene Speichervorgang einen überflüssigen Reload auslösen — mit ihm ist
  der Kreislauf Schreiben → Event → Prüfen → „war ich selbst" sauber
  unterbrochen.
- **Banner-UX:** Die Konzept-Frage wird gestellt, aber nicht aufgedrängt.

## Ergebnis

Build fehlerfrei. Live-Test: Testordner in `~/Projekte` angelegt → Watcher
verarbeitet die Änderung, App stabil; Ordner wieder entfernt → Hinweis räumt
sich selbst auf, App stabil. Ab jetzt gilt: Ordner anlegen, App fragt —
kein Neustart mehr nötig.
