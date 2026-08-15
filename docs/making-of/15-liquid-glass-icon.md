# 15 · Liquid-Glass-Icon: Die Kür

**Datum:** 15.08.2026

## Ausgangslage

Das klassische Icon (Kapitel 12) saß — aber Jörns Kortschak-Icons setzen die
Messlatte: echte Liquid-Glass-`.icon`-Bundles im Icon-Composer-Format von
macOS 26. Und es gab eine Korrektur einzuarbeiten: Das Icon sollte auf Jörns
**Original-Vektoren** basieren, nicht auf der Rekonstruktion (siehe Nachtrag
in Kapitel 12).

## Was passiert ist

1. **Master-Wechsel:** Jörns Illustrator-Export (`Logo/SVG/Element 1.svg`)
   ersetzt die Rekonstruktion in `design/` — Wortmarke hell/dunkel und das
   extrahierte ii-Motiv (`biind-motiv.svg`) mit den unveränderten
   Original-Pfaden und -Farben (#00E6E9/#F7931E), Z-Ordnung wie im Original
   (Cyan-U über Orange-Stamm).
2. **Format-Studium statt Raten:** Die vorhandenen Kortschak-`.icon`-Bundles
   dienten als Referenz — `icon.json` mit Hintergrund-Fill, Ebenen mit
   Glass-Spezialisierungen, Schatten, Specular und Transluzenz, Assets als
   1024er-SVG.
3. **`AppIcon.icon`** danach gebaut: Midnight-Grund (#23282D), das ii-Motiv
   als eine Glass-Ebene mit den SVG-eigenen Farben. Dazu die Frost-Variante
   (`design/icon/biind-Frost.icon`) — dieselbe Familienlogik wie bei den
   Kortschak-Icons.
4. **Integration:** In der project.yml als Folder-Reference in die
   Resources-Phase. Der Beweis, dass es wirklich kompiliert wurde, steht im
   Assets.car: `assetutil` listet **„Icon Image · AppIcon"** — den neuen
   Icon-Typ — neben dem klassischen MultiSized-Fallback aus dem Asset-Katalog.
   Ältere Systeme bekommen das maskierte Icon, macOS 26 rendert Glas.
5. **Fallback nachgezogen:** Die klassischen maskierten Icons (macOSicons-API)
   und alle appiconset-Größen wurden mit dem Original-Motiv und den
   Original-Farben neu erzeugt.

## Entscheidungen

- **Eine Glass-Ebene statt zwei:** Cyan- und Orange-Pfade liegen in einer
  Ebene mit ihren SVG-Farben — die Z-Ordnung innerhalb der Ebene ist damit
  garantiert die des Originals. Getrennte Ebenen pro Farbe (mehr Tiefen-Effekt)
  sind Jörns Spielwiese im Icon Composer, wo man das Ergebnis live sieht.
- **Beide Icon-Generationen im Bundle:** `.icon` für macOS 26+, Asset-Katalog
  für alles davor — kostet nichts und nimmt niemandem das Icon.

## Ergebnis

biind trägt Liquid Glass im Dock, das Motiv ist pixelgenau Jörns Entwurf,
und die Frost-Variante liegt als Familienmitglied bereit. Damit ist auch die
Kür gelaufen — Logo, Icon und App sind aus einem Guss.
