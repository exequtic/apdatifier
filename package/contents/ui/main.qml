import QtQuick 2.6
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "../tools/tools.js" as JS

Item {
	id: root

	Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
	Plasmoid.compactRepresentation: CompactRepresentation {}
	Plasmoid.fullRepresentation: FullRepresentation {}

	Plasmoid.status: updCount > 0 | busy | error
							? PlasmaCore.Types.ActiveStatus
							: PlasmaCore.Types.PassiveStatus

	property var listModel: listModel
	property var listeners: ({})
	property var updList
	property var updCount: 0
	property var error: null
	property var busy: true
	property var statusMsg
	property var commands

	property int interval: plasmoid.configuration.interval * 60000
	property var packages: plasmoid.configuration.packages
	property int sortingMode: plasmoid.configuration.sortingMode
	property int columnsMode: plasmoid.configuration.columnsMode
	property var searchMode: [plasmoid.configuration.pacmanMode,
							  plasmoid.configuration.checkupdatesMode,
							  plasmoid.configuration.wrapperMode,
							  plasmoid.configuration.flatpakEnabled]

	ListModel  {
		id: listModel
	}

	DataSource {
		id: sh
	}

	Timer {
		id: timer
		interval: root.interval
		running: true
		repeat: true
		onTriggered: JS.checkUpdates()
	}

	onIntervalChanged: {
		timer.restart()
	}

	onSearchModeChanged: {
		JS.checkDependencies()
	}
}
