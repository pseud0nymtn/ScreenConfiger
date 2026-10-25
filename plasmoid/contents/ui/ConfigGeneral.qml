import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.iconthemes as KIconThemes
import org.kde.kquickcontrols as KQuickControls
import org.kde.plasma.plasma5support as P5Support

// SimpleKCM provides the scroll view for pages taller than the dialog.
KCMUtils.SimpleKCM {
    id: page

    property string cfg_output
    property string cfg_outputDefault
    property string cfg_switchIcon
    property string cfg_switchIconDefault
    property string cfg_colorOn
    property string cfg_colorOnDefault
    property string cfg_colorOff
    property string cfg_colorOffDefault
    property int cfg_backgroundOpacityDefault
    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_showLabel: showLabelBox.checked
    property bool cfg_showLabelDefault
    property alias cfg_labelPosition: positionBox.currentIndex
    property int cfg_labelPositionDefault
    property alias cfg_labelSize: sizeSpin.value
    property int cfg_labelSizeDefault
    property alias cfg_labelMaxChars: maxCharsSpin.value
    property int cfg_labelMaxCharsDefault
    property alias cfg_labelSpacing: spacingSpin.value
    property int cfg_labelSpacingDefault
    property alias cfg_iconSize: iconSizeSlider.value
    property int cfg_iconSizeDefault
    property var outputs: []
    property var labels: []

    Kirigami.FormLayout {

        P5Support.DataSource {
            id: ds
            engine: "executable"
            connectedSources: ['PATH="$HOME/.local/bin:/usr/local/bin:$PATH" screenconfiger list']
            onNewData: (source, data) => {
                disconnectSource(source);
                try {
                    const list = JSON.parse(data["stdout"]);
                    page.outputs = list.map(o => o.name);
                    page.labels = list.map(o => o.label);
                } catch (e) {
                    page.outputs = [];
                    page.labels = [];
                }
            }
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Display output:")
            model: page.labels
            currentIndex: page.outputs.indexOf(page.cfg_output)
            onActivated: page.cfg_output = page.outputs[currentIndex]
            displayText: {
                const i = page.outputs.indexOf(page.cfg_output);
                return i >= 0 ? page.labels[i] : (page.cfg_output !== "" ? page.cfg_output : i18n("Select…"));
            }
        }

        KIconThemes.IconDialog {
            id: iconDialog
            title: i18n("Choose an icon")
            onAccepted: {
                if (iconName !== "")
                    page.cfg_switchIcon = iconName;
            }
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("Icon:")
            text: i18n("Choose theme icon…")
            icon.name: page.cfg_switchIcon.startsWith("/") || page.cfg_switchIcon.startsWith("file:")
                ? "" : (page.cfg_switchIcon || "video-display")
            icon.source: page.cfg_switchIcon.startsWith("file:") ? page.cfg_switchIcon
                : (page.cfg_switchIcon.startsWith("/") ? "file://" + page.cfg_switchIcon : "")
            icon.width: Kirigami.Units.iconSizes.large
            icon.height: Kirigami.Units.iconSizes.large
            onClicked: iconDialog.open()
        }

        FileDialog {
            id: fileDialog
            title: i18n("Choose an image")
            nameFilters: [i18n("Images (*.png *.jpg *.jpeg *.svg *.svgz *.webp *.bmp *.gif)")]
            onAccepted: page.cfg_switchIcon = selectedFile.toString()
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("Custom image:")
            text: i18n("Choose custom image…")
            icon.name: "document-open"
            onClicked: fileDialog.open()
        }

        QQC2.Slider {
            id: iconSizeSlider
            Kirigami.FormData.label: i18n("Icon size:")
            from: 10
            to: 100
            stepSize: 1
            snapMode: QQC2.Slider.SnapAlways
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Icon size value:")
            text: Math.round(iconSizeSlider.value) + " %"
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("Reset icon:")
            text: i18n("Reset to default")
            icon.name: "edit-undo"
            enabled: page.cfg_switchIcon !== "video-display"
            onClicked: page.cfg_switchIcon = "video-display"
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Background")
        }

        KQuickControls.ColorButton {
            Kirigami.FormData.label: i18n("Color when on:")
            color: page.cfg_colorOn || Kirigami.Theme.highlightColor
            dialogTitle: i18n("Choose color when the switch is on")
            onAccepted: selected => page.cfg_colorOn = selected.toString()
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("Reset on color:")
            text: i18n("Use theme color")
            icon.name: "edit-undo"
            enabled: page.cfg_colorOn !== ""
            onClicked: page.cfg_colorOn = ""
        }

        KQuickControls.ColorButton {
            Kirigami.FormData.label: i18n("Color when off:")
            color: page.cfg_colorOff || Kirigami.Theme.disabledTextColor
            dialogTitle: i18n("Choose color when the switch is off")
            onAccepted: selected => page.cfg_colorOff = selected.toString()
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("Reset off color:")
            text: i18n("Use theme color")
            icon.name: "edit-undo"
            enabled: page.cfg_colorOff !== ""
            onClicked: page.cfg_colorOff = ""
        }

        QQC2.Slider {
            id: opacitySlider
            Kirigami.FormData.label: i18n("Background opacity:")
            from: 0
            to: 100
            stepSize: 1
            snapMode: QQC2.Slider.SnapAlways
            Layout.fillWidth: true
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Opacity value:")
            text: Math.round(opacitySlider.value) + " %"
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Name label")
        }

        QQC2.CheckBox {
            id: showLabelBox
            Kirigami.FormData.label: i18n("Show monitor name:")
        }

        QQC2.ComboBox {
            id: positionBox
            Kirigami.FormData.label: i18n("Position:")
            enabled: showLabelBox.checked
            model: [i18n("Above"), i18n("Left"), i18n("Right"), i18n("Below")]
        }

        QQC2.SpinBox {
            id: maxCharsSpin
            Kirigami.FormData.label: i18n("Max. characters (0 = unlimited):")
            enabled: showLabelBox.checked
            from: 0
            to: 200
        }

        QQC2.SpinBox {
            id: spacingSpin
            Kirigami.FormData.label: i18n("Spacing to switch (px):")
            enabled: showLabelBox.checked
            from: 0
            to: 100
        }

        QQC2.SpinBox {
            id: sizeSpin
            Kirigami.FormData.label: i18n("Text size (pt):")
            enabled: showLabelBox.checked
            from: 6
            to: 72
        }

        QQC2.Label {
            text: i18n("Only connected outputs are listed.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
    }
}
