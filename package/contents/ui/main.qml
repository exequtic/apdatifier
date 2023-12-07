import QtQuick 2.6
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "../tools/tools.js" as JS

Item {
	id: root

	Plasmoid.compactRepresentation: CompactRepresentation {}
	Plasmoid.fullRepresentation: FullRepresentation {}

	Plasmoid.status: count > 0 | busy | error
							? PlasmaCore.Types.ActiveStatus
							: PlasmaCore.Types.PassiveStatus

	property var listModel: listModel
	property var listeners: ({})
	property var updList: []
	property var count: 0
	property var error: ''
	property var busy: true
	property var statusMsg: ''
	property var statusIco: ''
	property var commands: []

	property bool interval: plasmoid.configuration.interval
	property int time: plasmoid.configuration.time * 60000
	property var packages: plasmoid.configuration.packages
	property var sorting: plasmoid.configuration.sortByName
	property int columns: plasmoid.configuration.columns
	property var searchMode: [plasmoid.configuration.pacman,
							  plasmoid.configuration.checkupdates,
							  plasmoid.configuration.wrapper,
							  plasmoid.configuration.flatpak]

	ListModel  {
		id: listModel
	}

	DataSource {
		id: sh
	}

	Timer {
		id: timer
		interval: root.time
		running: true
		repeat: true
		onTriggered: JS.checkUpdates()
	}

	onTimeChanged: {
		timer.restart()
	}

	onIntervalChanged: {
		interval ? timer.start() : timer.stop()
	}

	onSortingChanged: {
		JS.sortList(updList)
	}

	onSearchModeChanged: {
		JS.checkDependencies()

		Plasmoid.setAction('check', 'Check updates', 'view-refresh-symbolic')

		searchMode[1]
			? Plasmoid.removeAction('database')
			: Plasmoid.setAction('database', 'Download database', 'download')

		Plasmoid.setActionSeparator(' ')
	}

    function action_check() {
        JS.checkUpdates()
    }
    function action_database() {
        JS.refreshDatabase()
    }
}
