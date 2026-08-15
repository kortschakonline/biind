<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="design/biind-wortmarke-dunkel.svg">
    <img src="design/biind-wortmarke.svg" alt="biind" width="340">
  </picture>
</p>

<p align="center"><b>biind verbindet deine Projektlandschaft.</b><br>
Eine native macOS-App, die Claude-Code-Projekte verwaltet: Identitäten statt Ordnernamen,
Claudes Gedächtnis sichtbar, Gesundheits-Checks mit Heil-Aktionen, Quick-Switcher.<br>
<i>A native macOS app that manages Claude Code projects — identities instead of folder names.</i></p>

---

## Warum?

Projektordner heißen, wie sie vor zwei Jahren hießen — die Projekte darin sind
längst etwas anderes. Claude Code legt sein Gedächtnis pfadgebunden ab — zwei
Macs mit verschiedenen Pfaden splitten das Wissen. Und die handgepflegte
Übersichtsdatei veraltet ab dem Tag ihrer Erstellung.

biind löst das strukturell: **Projekt ≠ Ordner.** Eine Identitäts-Ebene
(Klarname, Aliasse, Kunde) bindet beliebig viele Ordner, Claude-Speicher,
Git-Repos und Live-URLs zusammen — maschinenübergreifend.

## Features

- **Projektkartei** — Projekte nach Kunden gruppiert, mit Klarnamen und Aliassen; die Suche versteht „das Portal", auch wenn der Ordner anders heißt
- **Claude-Layer** — Memories als lesbare Karten, Session-Zeitleiste mit echten Titeln, „Mit Claude weiterarbeiten"-Button (nur lesend; die einzige Schreib-Ausnahme ist die bestätigte Memory-Zusammenführung)
- **Gesundheits-Checks** — elf Checks mit Schweregraden: Secrets in Git-Configs, Duplikat-Verdacht, verwaiste Claude-Speicher, Ordner ohne Eintrag u. v. m.
- **Geführtes Aufräumen** — Heil-Aktionen pro Befund: Archivieren, Papierkorb, Zuordnen, Token-Remote → SSH. Nie endgültig löschen, immer einzeln bestätigt
- **Memory-Zusammenführung** — verwaiste Claude-Speicher (nach Umbenennen/Verschieben) in den aktiven Speicher eines Projekts überführen: verschieben, nie löschen
- **Quick-Switcher** — ⌥ Leertaste von überall: „portal" tippen, ↩ öffnet die Akte, ⌘↩ startet Claude im Projektordner
- **Maschinen-Profile** — Pfade als Tokens (`$PROJEKTE/…`), pro Mac aufgelöst; die Datenbank (`atlas.json`) liegt im gesyncten Ordner selbst
- **Lebendig** — FSEvents-Watcher erkennt neue Ordner („Neues Projekt oder Teil eines bestehenden?") und übernimmt extern gesyncte Datenänderungen live
- **PROJEKTE.md-Export** — die menschen- und Claude-lesbare Landkarte wird generiert statt gepflegt; Freitext-Abschnitte bleiben erhalten

## Das Making-Of 📖

Diese App ist an einem Wochenende mit [Claude Code](https://claude.com/claude-code)
entstanden — und **jeder Schritt ist dokumentiert**: Konzept, Fehlschläge,
Entscheidungen, der Namensfindungs-Prozess, der Logo-Weg inklusive des
„bünd"-Befunds. Die Entstehungsgeschichte ist Teil des Produkts:

**[→ docs/making-of/](docs/making-of/README.md)** — 13 Kapitel von der Idee bis zur Veröffentlichung.

## Build

Voraussetzungen: macOS 26+, Xcode 26+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
cd App && xcodegen generate && xcodebuild -project Atlas.xcodeproj -scheme Atlas -configuration Debug build
```

(„Atlas" ist der interne Codename — die App heißt biind.)

## Zuschnitt & Status

biind ist ein persönliches Werkzeug und bewusst auf ein konkretes Setup
zugeschnitten: Es liest `~/Projekte` und `~/.claude` direkt (kein Sandbox,
kein App-Store-Ziel) und erwartet die dort beschriebene Struktur. Als
Blaupause und Lesestoff gedacht — Issues und Ideen willkommen, aber es gibt
keine Unterstützungs-Garantie.

## Lizenz

[MIT](LICENSE) © 2026 Jörn Martin (JRN.digital)
