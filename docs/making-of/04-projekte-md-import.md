# 04 · PROJEKTE.md-Import & Identitäts-Ebene

**Datum:** 14.08.2026

## Ausgangslage

Das Skelett (Kapitel 03) zeigte Ordner. Aber die Kernidee der App ist ja gerade:
**Projekt ≠ Ordner.** Dieser Schritt baut die Identitäts-Ebene — die Klarnamen,
Aliasse und Kunden-Gruppen aus der handgepflegten `PROJEKTE.md` werden importiert
und mit den real gescannten Ordnern verheiratet.

## Was passiert ist

Drei neue Bausteine:

| Baustein | Aufgabe |
|---|---|
| `ProjekteMdParser` | liest die Landkarten-Datei: `##`-Überschriften → Gruppen, Tabellenzeilen → Projekte. Aliasse aus „…"-Anführungszeichen, Ordnerpfade aus Backtick-Spans, Live-URL und Git-Remote aus der Details-Spalte |
| `ProjektIdentitaet` / `ProjektAkte` / `Katalog` | die Modelle: Identität (was ein Projekt *ist*) + gefundene Ordner = Akte; Gruppen in Dokument-Reihenfolge |
| `KatalogBuilder` | das Matching: jeder Pfad aus PROJEKTE.md wird gegen die gescannten Ordner aufgelöst; Ordner außerhalb `~/Projekte` (z. B. `~/Kunden 2026`) werden einzeln nacherfasst; Reste landen in „Nicht zugeordnet" |

Die UI wurde entsprechend umgebaut: Sidebar mit Kunden-Sections und Suche
(findet auch Aliasse — „portal" trifft das Kortschak Studio), Detailseite ist
jetzt eine **Projektakte** mit Aliassen, Live-URL-Button, aggregierten
Claude-Zahlen und der Ordnerliste. Ordner, die auf diesem Mac fehlen, werden
ehrlich als solche angezeigt („liegt vermutlich auf dem anderen Rechner") —
das Zwei-Mac-Setup soll sichtbar sein, nicht verwirren.

## Entscheidungen

1. **Toleranter Zeilen-Parser statt Markdown-Library.** Die Datei hat drei
   verschiedene Tabellenformate (4-, 3- und 2-spaltig) — der Parser mappt Spalten
   über die Kopfzeile („Alias…", „Ordner", „Details") und ignoriert alles ohne
   Tabelle (Aufräumliste, Konventionen). ~150 Zeilen, keine Dependency.
2. **Verifikation vor dem App-Start:** Parser + Scanner wurden als
   Kommandozeilen-Programm kompiliert und gegen die echten Daten laufen gelassen.
   Ergebnis-Auszug:

   ```
   == Kortschak Werbeagentur (Schriften GmbH)  (13 Projekte)
      Kortschak Studio  [1 Ordner · 13 Sessions/6 Mem · live: proof.kortschak.online]
        – das Portal, Kortschak-Portal, Freigabe-Tool, Freigabe-Portal, Proofing-Tool
      Kortschak-Website-Relaunch  [3 Ordner · 3 Sessions/3 Mem]
      3D-Assets Website  [5 Ordner]
   …
   == Nicht zugeordnet  (7 Projekte)
      AlienArrive · Aliens Arrived · MenuStats · Rechnungs-App jrn.digital
      Touareg Test · trofaiach-mcp-bridge · Upload
   ```

   38 Projekte in 6 Gruppen, alle Mehrfach-Ordner-Projekte korrekt gebündelt —
   und „Nicht zugeordnet" fängt exakt die Kandidaten der Aufräumliste. Die
   Gesundheits-Checks (V2) bekommen ihre Daten also geschenkt.
3. **Import ist eine Einbahnstraße — noch.** Der Parser liest nur. In V2 wird die
   Richtung umgedreht: App hält die Daten (`atlas.json`), PROJEKTE.md wird generiert.

## Beobachtungen für später

- **Verschachtelte Claude-Projekte:** Bei „Stefanie Spielberger" hat Claude
  Unterordner als eigene Projekte erfasst (`…/Kunst-Website`, `…/Tattoo-Website`).
  Der Scanner schaut bisher nur auf die oberste Ebene → V2-Thema.
- Die Suche über Aliasse fühlt sich schon jetzt wie der halbe Quick-Switcher an.

## Ergebnis

Build fehlerfrei, App zeigt die Projektlandschaft erstmals so, wie sie
gedacht ist: nach Kunden gruppiert, mit Klarnamen — nicht als Ordnerfriedhof.
