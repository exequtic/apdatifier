/*
	SPDX-FileCopyrightText: 2023 Evgeny Kazantsev <exequtic@gmail.com>
	SPDX-License-Identifier: MIT
*/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.notification 1.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.networkmanagement 0.2
import Qt.labs.platform 1.1
import "../tools/tools.js" as JS

Item {
	id: root

	Plasmoid.compactRepresentation: CompactRepresentation {}
	Plasmoid.fullRepresentation: FullRepresentation {}

    Plasmoid.preferredRepresentation: plasmoid.location === PlasmaCore.Types.Floating
                                      	? Plasmoid.fullRepresentation
                                    	: Plasmoid.compactRepresentation

	Plasmoid.switchWidth: PlasmaCore.Units.gridUnit * 20
    Plasmoid.switchHeight: PlasmaCore.Units.gridUnit * 10

	Plasmoid.busy: busy
	Plasmoid.status: count > 0 || busy || error
						? PlasmaCore.Types.ActiveStatus
						: PlasmaCore.Types.PassiveStatus

	Plasmoid.icon: plasmoid.configuration.selectedIcon

	Plasmoid.toolTipMainText: ""
	Plasmoid.toolTipSubText: busy ? statusMsg : i18n("The last check was at %1", lastCheck)

	property var applet: Plasmoid.pluginName
	property var listModel: listModel
	property var updList: []
	property var shell: []
	property bool busy: false
	property bool upgrading: false
	property bool downloading: false
	property string error: ""
	property string statusMsg: ""
	property string statusIco: ""
	property string notifyTitle: ""
	property string notifyBody: ""
	property string lastCheck: i18n("never")
	property var action
	property var count

	property bool interval: plasmoid.configuration.interval
	property int time: plasmoid.configuration.time * 60000
	property bool sorting: plasmoid.configuration.sortByName
	property var packages: plasmoid.configuration.packages

	property var searchMode: [plasmoid.configuration.pacman,
							  plasmoid.configuration.checkupdates,
							  plasmoid.configuration.wrapper,
							  plasmoid.configuration.flatpak]

	ListModel  {
		id: listModel
	}

	Shell {
		id: sh
	}

	Notification {
		id: notify
		componentName: "apdatifier"
		eventId: plasmoid.configuration.withSound ? "sound" : "popup"
		title: notifyTitle
		text: notifyBody
		iconName: "apdatifier-packages"
	}

    ConnectionIcon {
        id: connection
    }

	Timer {
		id: searchTimer
		interval: root.time
		running: true
		repeat: true
		onTriggered: JS.checkUpdates()
	}

	Timer {
		id: connectionTimer
		interval: 5000
		repeat: true
		onTriggered: JS.waitConnection()
    }

	onTimeChanged: {
		searchTimer.restart()
	}

	onIntervalChanged: {
		interval ? searchTimer.start()
				 : searchTimer.stop()
	}

	onSortingChanged: {
		JS.refreshListModel()
	}

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

		Plasmoid.setAction("check", i18n("Check updates"), "view-refresh-symbolic")
        Plasmoid.action("check").visible = Qt.binding(() => {
            return !upgrading && !downloading
        })

		Plasmoid.setAction("upgrade", i18n("Upgrade system"), "akonadiconsole")
        Plasmoid.action("upgrade").visible = Qt.binding(() => {
            return !busy && !error && count > 0 && plasmoid.configuration.selectedTerminal
        })

		Plasmoid.setAction("database", i18n("Download database"), "repository")
        Plasmoid.action("database").visible = Qt.binding(() => {
            return !busy && !searchMode[1] && plasmoid.configuration.showDownloadBtn
        })
	}
}
