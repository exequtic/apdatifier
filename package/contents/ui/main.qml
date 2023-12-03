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
	property var updListOut
	property var updListObj
	property var updCount
	property var cache
	property var error
	property var busy

	property int interval: plasmoid.configuration.interval * 60000
	property int sortingMode: plasmoid.configuration.sortingMode
	property int columnsMode: plasmoid.configuration.columnsMode

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
		Component.onCompleted: triggered()
	}

	onIntervalChanged: {
		timer.restart()
	}

	Component.onCompleted: {
		JS.checkDependencies()
	}
}
