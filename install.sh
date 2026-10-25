#!/bin/sh
# Builds the Rust helper and installs helper + plasmoid for the current user.
set -eu
cd "$(dirname "$0")"
cargo build --release
install -Dm755 target/release/screenconfiger "$HOME/.local/bin/screenconfiger"
kpackagetool6 --type Plasma/Applet --install plasmoid 2>/dev/null \
  || kpackagetool6 --type Plasma/Applet --upgrade plasmoid
echo "Done. Add the widget 'Screen Switch' to your panel or desktop."
