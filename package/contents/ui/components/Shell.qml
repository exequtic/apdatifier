/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

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

        listeners[cmd](cmd, out, err, code)
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
        this.destroy()
    }
}
