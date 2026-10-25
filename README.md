# ScreenConfiger – Screen Switch (KDE Plasma 6 Widget)

Ein kleines Plasma-Widget, das wie ein Schalter aussieht und einen Bildschirmausgang (z. B. `DP-2`, `HDMI-A-1`) an- oder ausschaltet. Es funktioniert sowohl im **Panel** als auch auf dem **Desktop**.

- **Klick** auf den Schalter: Ausgang an/aus
- **Langer Klick**: öffnet die Systemeinstellungen direkt in der *Anzeige-Konfiguration* (`kcm_kscreen`)
- Der Zustand wird alle 5 Sekunden aktualisiert (z. B. wenn der Ausgang an anderer Stelle geändert wurde).
- Sicherheitsnetz: der letzte aktive Ausgang kann nicht abgeschaltet werden.

## Aufbau

| Teil | Beschreibung |
|------|--------------|
| `src/main.rs` | Rust-Helfer `screenconfiger` (Backend). Liest und schaltet Ausgänge über `kscreen-doctor` und öffnet `kcmshell6 kcm_kscreen`. |
| `plasmoid/` | Plasma-Widget (QML-UI), das den Helfer aufruft. Plasma-Widgets selbst müssen in QML geschrieben werden, die Logik liegt in Rust. |

Befehle des Helfers:

```
screenconfiger list              # verbundene Ausgänge als JSON
screenconfiger status <Ausgang>  # on | off
screenconfiger toggle <Ausgang>
screenconfiger on|off <Ausgang>
screenconfiger settings          # Anzeige-Konfiguration öffnen
```

## Voraussetzungen

- KDE Plasma 6 (inkl. `kscreen-doctor`, `kcmshell6`, `kpackagetool6`)
- Rust (Cargo, Edition 2024 → Rust ≥ 1.85)

## Bauen

```sh
cargo build --release
```

Das Binary liegt danach in `target/release/screenconfiger`.

## Installieren

```sh
./install.sh
```

Das Skript baut den Helfer, kopiert ihn nach `~/.local/bin/screenconfiger` und installiert das Widget per `kpackagetool6` für den aktuellen Benutzer. Ein erneutes Ausführen aktualisiert das Widget. Falls das Widget nicht in der Liste erscheint, Plasma neu starten:

```sh
systemctl --user restart plasma-plasmashell.service
```

Danach: Rechtsklick auf Panel/Desktop → *Miniprogramme hinzufügen* → **Screen Switch**.

## Einrichten

Rechtsklick auf das Widget → *Screen Switch konfigurieren…* und den gewünschten Ausgang auswählen. Solange keiner gewählt ist, öffnet ein Klick die Anzeigeeinstellungen.

## Deinstallieren

```sh
./uninstall.sh
```

## Hinweise

- Der Helfer muss unter `~/.local/bin` (oder `/usr/local/bin`) liegen, damit das Widget ihn findet.
- Das Widget wurde für Plasma 6 geschrieben; für Plasma 5 sind Anpassungen nötig.
