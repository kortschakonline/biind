# 11 · Geführtes Aufräumen: Befunde bekommen Hände

**Datum:** 14.08.2026

## Ausgangslage

Die Gesundheits-Checks diagnostizieren seit Kapitel 06, die Memory-Zusammenführung
(Kapitel 09) war die erste Therapie. Jetzt bekommen die übrigen Befund-Typen
ihre Aktionen — aus der Befundliste wird ein Aufräum-Werkzeug.

## Was passiert ist

Vier neue Heil-Aktionen, alle nach denselben Grundsätzen — **umkehrbar** und
**einzeln bestätigt**:

| Befund | Aktion |
|---|---|
| Mögliches Duplikat | **Aufräumen …** — Sheet zeigt beide Kandidaten mit Kennzahlen (Einträge, Änderungsdatum, „steht in der Landkarte"), Vorauswahl fällt auf den Ordner *ohne* Landkarten-Eintrag, der Gewählte wandert nach `~/Projekte/_Archiv/` |
| Praktisch leerer Ordner | **In den Papierkorb …** — mac-nativ und wiederherstellbar, mit Bestätigung |
| Ohne Eintrag in PROJEKTE.md | **Aufnehmen … / Zuordnen …** — dieselben Sheets wie in der Akte, direkt am Befund |
| Zugangsdaten in .git/config | **Auf SSH umstellen …** — Vorher/Nachher-Vorschau (Token durchgestrichen, SSH-URL grün), Backup der alten config, danach der deutliche Hinweis: *Token bei GitHub widerrufen — das kann die App nicht für dich tun* |

Dazu Infrastruktur: `_Archiv` wird vom Scanner ignoriert (sonst würde das
Archiv selbst zum Befund), und wer einen Ordner archiviert oder entsorgt, dessen
Verweis wird automatisch aus der atlas.json entfernt — PROJEKTE.md bleibt konsistent.

Schöner Systemeffekt: Archiviert man einen Ordner mit Claude-Speicher, meldet
der nächste Check-Lauf diesen als verwaist — und bietet die Zusammenführung an.
Die Werkzeuge greifen ineinander, ohne dass das jemand extra programmieren musste.

## Verifikation

Wieder isoliert per CLI mit Fake-Daten, bevor die UI etwas durfte:
Archivieren samt Namenskollision (Laufnummer), Papierkorb-Roundtrip (rein und
programmatisch wieder zurück — keine Testreste), SSH-Umstellung an einer
Fake-config mit echtem Token-Muster: Token raus, `fetch`-Zeile unversehrt,
Backup da. Alles grün.

## Entscheidungen

- **Papierkorb statt Löschen:** Die App löscht grundsätzlich nichts endgültig.
  Selbst der leere Ordner geht nur dorthin, wo der Finder ihn zurückholen kann.
- **SSH-Umstellung nur für github.com:** Andere Hosts sind Handarbeit — lieber
  eine Aktion, die sicher funktioniert, als eine generische, die überrascht.
- **Kein „Alle aufräumen"-Knopf:** Jede Aktion einzeln, mit eigenem Kontext.
  Sammel-Automatik wäre schneller — und genau das Gegenteil von geführt.

## Ergebnis

Die Befundliste ist jetzt ein Arbeitsplatz: KRITISCH-Funde haben eine
Ein-Klick-Entschärfung, Duplikate und Leer-Ordner einen begleiteten Ausgang,
Landkarten-Lücken den direkten Weg hinein. Von der ursprünglichen
Aufräumliste in PROJEKTE.md ist damit nichts mehr übrig, was die App nicht
entweder findet oder gleich mit erledigt.
