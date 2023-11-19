import QtQuick 2.5
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponent

Item {
	id: root

	Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
	Plasmoid.compactRepresentation: CompactRepresentation {}
	Plasmoid.fullRepresentation: FullRepresentation {}

	property var theModel: updatesListModel
	property var updatesList
	property var updatesCount: '?'

	readonly property int interval: plasmoid.configuration.interval * 1000
	readonly property string command: 'checkupdates'

	PlasmaCore.DataSource {
		id: executable
		engine: "executable"
		connectedSources: []
		onNewData: {
			var exitCode = data["exit code"]
			var exitStatus = data["exit status"]
			var stdout = data["stdout"]
			var stderr = data["stderr"]
			exited(sourceName, exitCode, exitStatus, stdout, stderr)
			disconnectSource(sourceName)
		}
		function exec(cmd) {
			if (cmd) {
				connectSource(cmd)
			}
		}
		signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
	}

	Connections {
		target: executable
		onExited: {
			if (cmd == command) {
				updatesList = stdout
				updatesList = updatesList.split("\n")
				updatesCount = updatesList.length - 1
				
				updatesListModel.clear()
				for (var i = 0; i < updatesCount; i++) {
            		updatesListModel.append({"text": updatesList[i]});
        		}
			}
		}
	}

	Timer {
		id: timer
		interval: root.interval
		running: true
		repeat: false
		onTriggered: runCommand()

		Component.onCompleted: {
			triggered()
		}
	}
	
	onIntervalChanged: {
		timer.restart()
	}

	ListModel {
        id: updatesListModel
    }

	function runCommand() {
		executable.exec(command)
	}
}
