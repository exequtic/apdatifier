import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Plasma5Support.DataSource {
    id: executable
    engine: "executable"
    connectedSources: []
    onNewData: (sourceName, data) => {
        var cmd = sourceName
        var out = data["stdout"]
        var err = data["stderr"]
        var code = data["exit code"]

        exited(cmd, out, err, code)

        const cb = listeners[cmd]
        if (cb) cb(cmd, out, err, code)
    }

    signal exited(string cmd, string out, string err, int code)

    property var listeners: ({})

    function exec(cmd, callback) {
        listeners[cmd] = execCallback.bind(executable, callback)
        connectSource(cmd)
    }

    function execCallback(callback, cmd, out, err, code) {
        cleanup()
        if (callback) callback(cmd, out, err, code)
    }

    function cleanup() {
        for (var cmd in listeners) {
            delete listeners[cmd]
            disconnectSource(cmd)
        }

        if (typeof sts !== 'undefined' && sts?.proc === executable) sts.proc = null

        executable.destroy()
    }
}
