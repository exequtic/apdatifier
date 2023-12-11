import QtQuick 2.6
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.notification 1.0
import "../tools/tools.js" as JS

Item {
	id: root

	Plasmoid.compactRepresentation: CompactRepresentation {}
	Plasmoid.fullRepresentation: FullRepresentation {}

	Plasmoid.status: count > 0 | busy | error
						? PlasmaCore.Types.ActiveStatus
						: PlasmaCore.Types.PassiveStatus

	Plasmoid.toolTipSubText: !busy && lastCheck
								? "The last check was at " + lastCheck
								: "Checking..." 

	property var applet: Plasmoid.pluginName
	property var listModel: listModel
	property var listeners: ({})
	property var updList: []
	property var count
	property var error: ''
	property var busy: false
	property var statusMsg: ''
	property var statusIco: ''
	property var commands: []
	property int responseCode: 0
	property var action
	property var lastCheck
	property var notifyTitle: ''
	property var notifyBody: ''

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

	Notification {
		id: notify
		componentName: "apdatifier"
		eventId: plasmoid.configuration.withSound ? "sound" : "popup"
		title: notifyTitle
		text: notifyBody
		iconName: "apdatifier-plasmoid-updates"
	}

	Timer {
		id: timer
		interval: root.time
		running: true
		repeat: true
		onTriggered: JS.checkUpdates()
	}

	Timer {
		id: waitConnection
		interval: 5000
		repeat: true
		onTriggered: JS.checkConnection()
    }

	WorkerScript {
		id: connection
		source: "../tools/connection.js"
		onMessage: JS.sendCode(messageObject.code)
	}

	onTimeChanged: {
		timer.restart()
	}

	onIntervalChanged: {
		interval ? timer.start() : timer.stop()
	}

	onSortingChanged: {
		JS.applySort()
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
