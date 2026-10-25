import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string output: Plasmoid.configuration.output
    readonly property bool valid: /^[A-Za-z0-9_.-]+$/.test(output)
    property bool outputOn: false
    property bool busy: false
    property string error: ""

    // The same UI is used in panels and on the desktop.
    preferredRepresentation: fullRepresentation
    Plasmoid.icon: "preferences-desktop-display"
    toolTipMainText: valid ? output : i18n("Screen Switch")
    toolTipSubText: !valid ? i18n("Choose an output in the widget settings")
        : error !== "" ? error
        : (outputOn ? i18n("On – click to switch off, long press for display settings")
                    : i18n("Off – click to switch on, long press for display settings"))

    Backend { id: backend }

    function refresh() {
        if (!valid) return;
        backend.run("status " + output, (ok, out) => { if (ok) outputOn = (out === "on"); });
    }

    function toggle() {
        if (!valid || busy) return;
        busy = true;
        backend.run("toggle " + output, (ok, out, err) => {
            busy = false;
            error = ok ? "" : err;
            if (ok) outputOn = (out === "on");
            else refresh();
        });
    }

    function openSettings() {
        backend.run("settings", () => {});
    }

    onOutputChanged: refresh()
    Component.onCompleted: refresh()

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    fullRepresentation: Item {
        id: full
        Layout.minimumWidth: Kirigami.Units.gridUnit * 2
        Layout.minimumHeight: Kirigami.Units.gridUnit
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5

        // Set when a long press was handled so the release does not toggle.
        property bool longPressed: false

        Item {
            id: sw
            anchors.centerIn: parent
            // Keep a 2:1 aspect ratio, fitted into the available area.
            width: Math.min(parent.width, parent.height * 2)
            height: width / 2
            opacity: root.valid ? (root.busy ? 0.6 : 1) : 0.4

            Rectangle {
                id: track
                anchors.fill: parent
                radius: height / 2
                color: root.outputOn ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                border.width: 1
                border.color: Qt.darker(color, 1.3)
                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
            }
            Rectangle {
                id: knob
                width: sw.height * 0.8
                height: width
                radius: width / 2
                y: (sw.height - height) / 2
                x: root.outputOn ? sw.width - width - (sw.height - height) / 2 : (sw.height - height) / 2
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: Kirigami.Theme.textColor
                Behavior on x { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.InOutQuad } }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: parent.width * 0.6
                    height: width
                    source: "video-display"
                    color: Kirigami.Theme.textColor
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onPressed: full.longPressed = false
            onPressAndHold: {
                full.longPressed = true;
                root.openSettings();
            }
            onClicked: {
                if (!full.longPressed) {
                    if (root.valid) root.toggle();
                    else root.openSettings();
                }
            }
        }
    }
}
