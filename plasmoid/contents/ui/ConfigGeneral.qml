import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

Kirigami.FormLayout {
    id: page

    property string cfg_output
    property string cfg_outputDefault
    property var outputs: []
    property var labels: []

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

    QQC2.Label {
        text: i18n("Only connected outputs are listed.")
        font: Kirigami.Theme.smallFont
        opacity: 0.7
    }
}
