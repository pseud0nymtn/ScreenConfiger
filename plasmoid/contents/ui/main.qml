import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
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
    // Readable monitor name (manufacturer + model), falls back to the port name.
    property string outputLabel: ""
    readonly property string displayName: outputLabel !== "" ? outputLabel : output
    // Same without the trailing "(PORT)", used for the text next to the switch.
    readonly property string fullShortName: outputLabel !== "" ? outputLabel.replace(/ \([^)]*\)$/, "") : output
    readonly property int maxChars: Plasmoid.configuration.labelMaxChars
    readonly property string shortName: maxChars > 0 && fullShortName.length > maxChars
        ? fullShortName.substring(0, maxChars).replace(/\s+$/, "") + "..."
        : fullShortName

    // The same UI is used in panels and on the desktop.
    preferredRepresentation: fullRepresentation
    Plasmoid.icon: "preferences-desktop-display"
    // Adds the "Show Background" toggle to the desktop edit-mode toolbar.
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    toolTipMainText: valid ? output : i18n("Screen Switch")
    toolTipSubText: !valid ? i18n("Choose an output in the widget settings")
        : error !== "" ? error
        : (outputOn ? i18n("On – click to switch off, long press for display settings")
                    : i18n("Off – click to switch on, long press for display settings"))

    Backend { id: backend }

    function loadLabel() {
        if (!valid) { outputLabel = ""; return; }
        backend.run("list", (ok, out) => {
            if (!ok) return;
            try {
                const o = JSON.parse(out).find(x => x.name === output);
                outputLabel = o ? o.label : "";
            } catch (e) {}
        });
    }

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

    onOutputChanged: { refresh(); loadLabel(); }
    Component.onCompleted: { refresh(); loadLabel(); }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    fullRepresentation: Item {
        id: full

        // 0 = above, 1 = left, 2 = right, 3 = below
        readonly property int labelPos: Plasmoid.configuration.labelPosition
        readonly property bool showLabel: Plasmoid.configuration.showLabel && root.valid
        readonly property bool horizontal: labelPos === 1 || labelPos === 2
        readonly property bool labelFirst: labelPos === 0 || labelPos === 1
        readonly property real gap: showLabel ? Plasmoid.configuration.labelSpacing : 0

        // Label size is limited so that the switch always keeps some room.
        readonly property real labelW: showLabel ? Math.min(nameLabel.implicitWidth, horizontal ? width * 0.6 : width) : 0
        readonly property real labelH: showLabel ? nameLabel.implicitHeight : 0
        // The switch keeps a 2:1 aspect ratio and fills the space the label leaves free.
        readonly property real swW: Math.max(0, horizontal
            ? Math.min(width - labelW - gap, height * 2)
            : Math.min(width, (height - labelH - gap) * 2))
        readonly property real swH: swW / 2

        Layout.minimumWidth: Kirigami.Units.gridUnit * 2 + (showLabel && horizontal ? nameLabel.implicitWidth + gap : 0)
        Layout.minimumHeight: Kirigami.Units.gridUnit + (showLabel && !horizontal ? nameLabel.implicitHeight + gap : 0)
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5 + (showLabel && horizontal ? nameLabel.implicitWidth + gap : 0)
        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5 + (showLabel && !horizontal ? nameLabel.implicitHeight + gap : 0)

        // Set when a long press was handled so the release does not toggle.
        property bool longPressed: false

        // Label and switch form one group that is centred as a whole,
        // so the distance between them is exactly the configured spacing.
        Item {
            id: group
            anchors.centerIn: parent
            width: full.horizontal ? full.labelW + full.gap + full.swW : Math.max(full.labelW, full.swW)
            height: full.horizontal ? Math.max(full.labelH, full.swH) : full.labelH + full.gap + full.swH

            PlasmaComponents.Label {
                id: nameLabel
                visible: full.showLabel
                text: root.shortName
                font.pointSize: Plasmoid.configuration.labelSize
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                width: full.labelW
                x: full.horizontal ? (full.labelFirst ? 0 : full.swW + full.gap) : (group.width - width) / 2
                y: full.horizontal ? (group.height - height) / 2 : (full.labelFirst ? 0 : full.swH + full.gap)
            }

            Item {
                id: sw
                width: full.swW
                height: full.swH
                x: full.horizontal ? (full.labelFirst ? full.labelW + full.gap : 0) : (group.width - width) / 2
                y: full.horizontal ? (group.height - height) / 2 : (full.labelFirst ? full.labelH + full.gap : 0)
                opacity: root.valid ? (root.busy ? 0.6 : 1) : 0.4

                Rectangle {
                    id: track
                    anchors.fill: parent
                    radius: height / 2
                    // Empty colour settings fall back to the theme colours.
                    readonly property color baseColor: root.outputOn
                        ? (Plasmoid.configuration.colorOn || Kirigami.Theme.highlightColor)
                        : (Plasmoid.configuration.colorOff || Kirigami.Theme.disabledTextColor)
                    color: baseColor
                    opacity: Plasmoid.configuration.backgroundOpacity / 100
                    border.width: 1
                    border.color: Qt.darker(baseColor, 1.3)
                    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
                    Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
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

                    readonly property string iconSource: Plasmoid.configuration.switchIcon || "video-display"
                    readonly property bool isFile: iconSource.startsWith("/") || iconSource.startsWith("file:")

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: parent.width * Plasmoid.configuration.iconSize / 100
                        height: width
                        visible: !knob.isFile
                        source: knob.isFile ? "" : knob.iconSource
                        color: Kirigami.Theme.textColor
                    }
                    // Custom images are shown as-is, clipped to the knob.
                    Image {
                        anchors.fill: parent
                        anchors.margins: parent.width * (1 - Plasmoid.configuration.iconSize / 100) / 2
                        visible: knob.isFile
                        source: knob.isFile ? (knob.iconSource.startsWith("/") ? "file://" + knob.iconSource : knob.iconSource) : ""
                        fillMode: Image.PreserveAspectFit
                        sourceSize.width: width * 2
                        sourceSize.height: height * 2
                        asynchronous: true
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            QQC2.ToolTip.visible: containsMouse
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            QQC2.ToolTip.text: root.valid
                ? i18n("Output: %1", root.displayName)
                : i18n("No output configured")
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
