import Qt.labs.platform 1.1
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

	Plasmoid.switchWidth: PlasmaCore.Units.gridUnit * 20
    Plasmoid.switchHeight: PlasmaCore.Units.gridUnit * 10

	Plasmoid.status: count > 0 | busy | error
						? PlasmaCore.Types.ActiveStatus
						: PlasmaCore.Types.PassiveStatus

	Plasmoid.toolTipMainText: ''
	Plasmoid.toolTipSubText: busy ? statusMsg : "The last check was at " + lastCheck

	property var applet: Plasmoid.pluginName
	property var listModel: listModel
	property var listeners: ({})
	property var updList: []
	property var count
	property var error: ''
	property var busy: false
	property var upgrade: false
	property var statusMsg: ''
	property var statusIco: ''
	property var shell: []
	property int responseCode: 0
	property var action
	property var lastCheck
	property var notifyTitle: ''
	property var notifyBody: ''

	property bool interval: plasmoid.configuration.interval
	property int time: plasmoid.configuration.time * 60000
	property var packages: plasmoid.configuration.packages
	property bool sorting: plasmoid.configuration.sortByName
	property bool debugging: plasmoid.configuration.debugging

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
		JS.refreshListModel()
	}

	// Triggers update check when search settings are modified.
	// For some reason, it is also triggered when the Desktop Folder Settings (Wallpapers) window is opened
	// Plasma bug?...

	// onSearchModeChanged: {
	// 	JS.checkUpdates()
	// }

    function action_check() {
		JS.checkUpdates()
	}
    function action_upgrade() {
		JS.upgradeSystem()
	}
    function action_database() {
		JS.downloadDatabase()
	}

	Component.onCompleted: {
		JS.runScript()

		Plasmoid.setAction("check", "Check updates", "view-refresh-symbolic")
        Plasmoid.action("check").visible = Qt.binding(() => {
            return !upgrade
        })

		Plasmoid.setAction("upgrade", "Upgrade system", "akonadiconsole")
        Plasmoid.action("upgrade").visible = Qt.binding(() => {
            return !busy && !error && plasmoid.configuration.selectedTerminal
        })

		Plasmoid.setAction("database", "Download database", "repository")
        Plasmoid.action("database").visible = Qt.binding(() => {
            return !busy && !searchMode[1] && plasmoid.configuration.showDownloadBtn
        })
	}
}
