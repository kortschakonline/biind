# 13 · GitHub-Veröffentlichung: biind geht in die Welt

**Datum:** 15.08.2026

## Ausgangslage

Von Anfang an war die Perspektive: Wenn die App gut wird, soll sie öffentlich
werden. Zwölf Kapitel später ist sie gut — V1 + V2 komplett, Name, Logo, Icon.
Und die Gesundheits-Checks meldeten seit Tag eins süffisant ihren letzten
offenen Punkt: „Git ohne Remote: Projekte Mac-App".

## Was passiert ist

1. **Sicherheits-Durchgang zuerst.** Secret-Scan über alle getrackten Dateien
   (sauber — die Treffer waren die Such*muster* im Checker-Code), keine
   .env/Key-Dateien im Repo. Aber: Das Making-Of nennt den Fundort des
   Klartext-Tokens aus Kapitel 06 — und der lag noch immer in der Config des
   Nachbarprojekts. Ein öffentliches Repo hätte eine lebende Schwachstelle
   dokumentiert.
2. **Erst heilen, dann veröffentlichen** (Jörns Entscheidung): Das
   Token-Remote wurde auf SSH umgestellt — mit derselben Backup-Logik, die
   die App als Heil-Aktion anbietet. Der alte Token: von Jörn bei GitHub
   widerrufen. Die App hat damit ihr eigenes Sicherheits-Feature einmal
   komplett im Ernstfall durchlaufen, bevor sie öffentlich wurde.
3. **Veröffentlichungs-Paket:** MIT-Lizenz, README mit der Wortmarke
   (hell/dunkel via `<picture>`), Feature-Überblick, Build-Anleitung,
   ehrlicher Zuschnitt-Hinweis (persönliches Werkzeug, kein Support-Versprechen)
   — und dem Making-Of als Herzstück.
4. **Repo:** `kortschakonline/biind`, öffentlich, gepusht mit der kompletten
   Historie — alle Meilenstein-Commits von „Initial" bis hierher. Die
   Entstehungsgeschichte ist damit nicht nur erzählt, sondern nachvollziehbar.

## Entscheidungen

- **Öffentlich mit kompletter Historie** statt Squash: Die Commits SIND das
  Making-Of in Maschinenform.
- **Deutsches README** mit englischem Einzeiler: Das Projekt ist durch und
  durch deutschsprachig (UI, Doku, Domänenbegriffe) — das zu verstecken wäre
  unehrlich. Wer es liest, liest auch das Making-Of.
- **Kein Support-Versprechen:** biind ist Blaupause und Lesestoff, auf ein
  konkretes Setup zugeschnitten. Issues willkommen, Erwartungsmanagement klar.

## Ergebnis

biind ist öffentlich — und der letzte ironische Befund („Git ohne Remote:
Projekte Mac-App") heilt sich mit diesem Push von selbst. Damit ist die
Geschichte rund: Eine App, die Ordnung in Projekte bringt, hat ihre eigene
Entstehung als geordnetes, veröffentlichtes Projekt hinterlassen.
