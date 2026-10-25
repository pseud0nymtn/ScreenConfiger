import QtQuick
import org.kde.plasma.plasma5support as P5Support

// Runs the Rust helper `screenconfiger` through the "executable" data engine.
P5Support.DataSource {
    id: backend
    engine: "executable"
    connectedSources: []

    property var callbacks: ({})

    // The helper is installed to ~/.local/bin, which plasmashell may not have in PATH.
    readonly property string prefix: 'PATH="$HOME/.local/bin:/usr/local/bin:$PATH" screenconfiger '

    function run(args, callback) {
        const cmd = prefix + args;
        callbacks[cmd] = callback;
        connectSource(cmd);
    }

    onNewData: (source, data) => {
        disconnectSource(source);
        const cb = callbacks[source];
        delete callbacks[source];
        if (cb) {
            cb(data["exit code"] === 0, (data["stdout"] || "").trim(), (data["stderr"] || "").trim());
        }
    }
}
