# 03 · Grundgerüst (V1-Skelett)

**Datum:** 14.08.2026

## Ausgangslage

Werkzeuge stehen (Kapitel 01). Ziel dieses Schritts: kein leeres Fenster, sondern
ein Skelett, das schon **echte Daten zeigt** — damit ab dem ersten Start sichtbar
ist, worum es der App geht.

## Was passiert ist

Vier Swift-Dateien, bewusst klein gehalten:

| Datei | Aufgabe |
|---|---|
| `AtlasApp.swift` | App-Einstieg, Fenster (960×640) |
| `Models/ProjektOrdner.swift` | Datenmodell: Ordner + Git-Status + Claude-Daten |
| `Services/OrdnerScanner.swift` | liest `~/Projekte` und `~/.claude/projects` (nur lesend!) |
| `Views/ContentView.swift` + `OrdnerDetailView.swift` | `NavigationSplitView`: Liste links, Projektakte rechts |

**Das fachliche Herzstück** ist eine unscheinbare Funktion: `claudeOrdnerName(fuer:)`
bildet nach, wie Claude Code Projektpfade kodiert — jedes Zeichen außer
ASCII-Buchstaben/Ziffern wird zu `-`:

```
/Users/jornmartin/Projekte/Netzwerk.local
→ -Users-jornmartin-Projekte-Netzwerk-local
```

Damit kann die App jedem Projektordner seine Claude-Daten zuordnen (Sessions
zählen, Memories zählen, letzte Aktivität). Genau diese Pfadbindung ist der
Grund für das Zwei-Mac-Problem — die App versteht sie jetzt, später kann sie
darauf die Maschinen-Profile und die Memory-Zusammenführung bauen.

## Stolpersteine (ehrlich dokumentiert)

1. **Falsche `List`-Überladung:** `List(ordner, selection:)` ließ den Swift-Compiler
   zur Binding-Variante greifen → kryptische Fehler („cannot assign to property").
   Lösung: `List(selection:) { ForEach(…) }` — die robuste Form.
2. **Style-Typen-Mix:** `.secondary : .orange` im Ternary mischt
   `HierarchicalShapeStyle` und `Color` → explizit `Color.secondary : Color.orange`.

Zwei Fehler, zwei Minuten — aber genau solche Dinge sieht man nie, wenn man nur
das fertige Ergebnis zeigt.

## Ergebnis

**BUILD SUCCEEDED.** Die App startet, listet alle ~50 Ordner aus `~/Projekte`,
zeigt pro Ordner: Claude-Symbol (wenn Daten vorhanden), Git-Warnung (wenn ohne
Remote — orange ⚠️, ein Vorgeschmack auf die Gesundheits-Checks), und in der
Detailansicht Sessions-/Memory-Zahlen, letzte Aktivität sowie die ersten
Schnellaktionen (Finder, Terminal).

Noch bewusst offen: die Identitäts-Ebene (Klarnamen/Aliasse aus PROJEKTE.md),
Gruppierung nach Kunden, „Mit Claude weiterarbeiten"-Button.

## Nächste Schritte

1. Name fixieren (Kapitel 02) → Logo → App-Icon via macOSicons-API
2. PROJEKTE.md-Import: aus Ordnern werden Projekte mit Klarnamen und Aliassen
3. Erster Git-Commit
