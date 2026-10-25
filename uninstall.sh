#!/bin/sh
rm -f "$HOME/.local/bin/screenconfiger"
kpackagetool6 --type Plasma/Applet --remove org.kde.screenconfiger
