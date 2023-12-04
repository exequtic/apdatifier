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
	Plasmoid.status: updCount > 0 | busy | error ?
					 PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus

	property var listModel: updListModel
	property var listeners: ({})
	property var updListObj
	property var updCount: 0
	property var cache: null
	property var error: null
	property var busy: true

	property int interval: plasmoid.configuration.interval * 60000
	property int sortingMode: plasmoid.configuration.sortingMode
	property int columnsMode: plasmoid.configuration.columnsMode

	property var searchMode: [plasmoid.configuration.pacmanMode,
							  plasmoid.configuration.wrapperMode]

	ListModel  {
		id: updListModel
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
		JS.setBin()
	}

	Component.onCompleted: {
		JS.checkDependencies()
	}
}
