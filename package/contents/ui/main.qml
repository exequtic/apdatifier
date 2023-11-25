import QtQuick 2.5
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponent
import "../tools/tools.js" as Util

Item {
	id: root

	Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
	Plasmoid.compactRepresentation: CompactRepresentation {}
	Plasmoid.fullRepresentation: FullRepresentation {}
	Plasmoid.status: updatesCount > 0 || checkStatus || errorStd ?
					 PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus

	property var listModel: updatesListModel
	property var updatesListOut
	property var updatesListObj
	property var updatesCount
	property var checkStatus
	property var errorStd

	readonly property int interval: plasmoid.configuration.interval * 60000
	readonly property bool wrapper: plasmoid.configuration.wrapper
	readonly property bool flatpak: plasmoid.configuration.flatpak
	property int sort: plasmoid.configuration.sort

	PlasmaCore.DataSource {
		id: sh
		engine: "executable"
		connectedSources: []
		onNewData: (sourceName, data) => {
			var exitCode = data["exit code"]
			var exitStatus = data["exit status"]
			var stdout = data["stdout"]
			var stderr = data["stderr"]
			exited(sourceName, exitCode, exitStatus, stdout, stderr)
			disconnectSource(sourceName)
		}
		function exec(cmd) {
			connectSource(cmd)
		}
		signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
	}

	Connections {
		target: sh
		function onExited(cmd, exitCode, exitStatus, stdout, stderr) {
			errorStd = stderr ? stderr : null
			updatesListOut = stdout ? stdout : null
			updatesCount = (!stderr && !stdout) ? 0 : null
			Util.makeList()
		}
	}

	Timer {
		id: timer
		interval: root.interval
		running: true
		repeat: true
		onTriggered: Util.checkUpdates()
		Component.onCompleted: triggered()
	}
	
	onIntervalChanged: {
		timer.restart()
	}

	ListModel {
        id: updatesListModel
    }
}
