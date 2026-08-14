# 06 · Gesundheits-Checks: Die Aufräumliste wird automatisch

**Datum:** 14.08.2026

## Ausgangslage

Die Aufräumliste in PROJEKTE.md war eine einmalige Inventur — wertvoll, aber ab
dem Tag ihrer Erstellung veraltet. Idee aus dem Konzept: Die App prüft die
Projektlandschaft **laufend** und meldet Befunde mit Schweregrad. Der Datenlieferant
existierte schon: Katalog + Ordner-Scan aus den Kapiteln 03/04.

## Was passiert ist

Neuer Baustein `GesundheitsPruefer` mit elf Checks (alles nur lesend):

| Schweregrad | Check |
|---|---|
| KRITISCH | Token/Zugangsdaten in `.git/config` (Muster: `ghp_`, `github_pat_`, eingebettete `https://…@…`-Credentials) |
| KRITISCH | Datei-/Ordnernamen, die nach Passwörtern klingen (Tiefe ≤ 3) |
| WARNUNG | Live-Projekt ohne Git-Remote (produktiv, aber nicht extern gesichert) |
| WARNUNG | Duplikat-Verdacht (normalisierte Namen: gleich, Präfix ± ≤ 3 Zeichen oder Levenshtein ≤ 2) |
| WARNUNG | Leerzeichen am Rand von Ordnernamen |
| WARNUNG | Verwaister Claude-Speicher (kein passender Ordner mehr) |
| HINWEIS | Git ohne Remote (nicht-live) · praktisch leere Ordner · `node_modules` im Sync (aggregiert) · Ordner ohne PROJEKTE.md-Eintrag · referenzierte Ordner, die auf diesem Mac fehlen |

**Verifikation wieder zuerst per CLI** — und der erste echte Lauf war der
Moment, in dem die App ihren Wert bewiesen hat: **32 Befunde in 0,5 Sekunden.**

- Beide bekannten kritischen Probleme aus der manuellen Aufräumliste wurden
  **selbstständig wiedergefunden**: der GitHub-Token in
  `trofaiach-mcp-bridge-git/.git/config` und „Kontakte und Passwörter" im
  Netzlaufwerk (doppelt — Backup-Ordner überlappt).
- Dazu **neue Funde**, die in der manuellen Inventur fehlten:
  `portal_password.php`, `05-passwort-wiederherstellung.md`.
- Die Verwaisten-Erkennung unterscheidet korrekt: die Claude-Speicher der noch
  existierenden Unterordner-Projekte (Preise, sommer-sets) blieben unbeanstandet,
  der des gelöschten `Trofaiach Webshop/Animationen` wurde gemeldet — ebenso die
  MDX-Altlasten.
- Und die schönste Zeile des Laufs: **„Git ohne Remote: Projekte Mac-App"** —
  der Check hat sein eigenes Projekt erwischt. (Remote folgt mit der
  GitHub-Veröffentlichung.)

In der UI: neuer Sidebar-Eintrag **Gesundheit** mit Befund-Badge, Befundliste
mit Schweregrad-Chips (rot/orange/petrol), Erklärung, Pfad und „Zeigen"-Button.
Die Checks laufen nach dem Start im Hintergrund.

## Entscheidungen

1. **Ein Befund ist ein Hinweis, kein Urteil** — Formulierungen wie „Mögliches
   Duplikat", „deutet auf … hin". Die App verändert nichts; Aufräumen bleibt
   eine Menschen-Entscheidung. (Geführte Aktionen sind V2-Material.)
2. **Duplikat-Heuristik bewusst konservativ getunt:** Präfix-Regel auf ± 3 Zeichen
   begrenzt, damit `…-git`-Arbeitskopien gefunden werden, aber „Trofaiach Webshop"
   vs. „Trofaiach Webshop 2026" (Absicht: Code vs. Material) nicht anschlägt.
   Kurznamen (< 4 Zeichen) nur bei exakter Gleichheit.
3. **node_modules als ein aggregierter Befund** statt 14 Einzelmeldungen —
   sonst fluten Hinweise die Liste und die kritischen Funde gehen unter.
4. **Bekannte Lücke:** Nicht referenzierte Kunden-Ordner (z. B. das
   „TRofaiach"-Tippfehler-Doppel in `~/Kunden 2026`) sieht der Scan noch nicht —
   er prüft nur die Projektlandschaft. Erweiterung fürs Backlog.

## Ergebnis

Build fehlerfrei, Checks laufen bei jedem App-Start automatisch. Aus der
statischen Aufräumliste ist ein lebendes Frühwarnsystem geworden, das am ersten
Tag zwei echte Sicherheitsfunde ergänzt hat.
