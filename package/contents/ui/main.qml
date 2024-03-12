/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts

import org.kde.notification
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.networkmanagement

import "../tools/tools.js" as JS

PlasmoidItem {
    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    switchWidth: Kirigami.Units.gridUnit * 20
    switchHeight: Kirigami.Units.gridUnit * 10

    Plasmoid.busy: busy
    Plasmoid.status: count > 0 || busy || error
                        ? PlasmaCore.Types.ActiveStatus
                        : PlasmaCore.Types.PassiveStatus

    Plasmoid.icon: plasmoid.configuration.selectedIcon

    toolTipMainText: !interval ? "Auto check disabled" : ""
    toolTipSubText: busy ? statusMsg : lastCheck

    property var listModel: listModel
    property var cmd: []
    property bool busy: false
    property bool upgrading: false
    property string error: ""
    property string statusMsg: ""
    property string statusIco: ""
    property string notifyTitle: ""
    property string notifyBody: ""
    property string lastCheck
    property var action
    property var count

    property bool interval: plasmoid.configuration.interval
    property int time: plasmoid.configuration.time
    property bool sorting: plasmoid.configuration.sortByName
    property var pkg: plasmoid.configuration.packages
    property var cfg: plasmoid.configuration

    ListModel  {
        id: listModel
    }

    Shell {
        id: sh
    }

    Notification {
        id: notify
        componentName: "apdatifier"
        eventId: cfg.withSound ? "sound" : "popup"
        title: notifyTitle
        text: notifyBody
        iconName: "apdatifier-packages"
    }

    ConnectionIcon {
        id: network
    }

    Timer {
        id: searchTimer
        interval: time * 1000 * 60
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

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Check updates")
            icon.name: "view-refresh"
            enabled: !upgrading
            onTriggered: JS.checkUpdates()
        },
        PlasmaCore.Action {
            text: i18n("Upgrade system")
            icon.name: "akonadiconsole"
            enabled: !busy && !error && count > 0 && cfg.terminal
            onTriggered: JS.upgradeSystem()
        }
    ]

	Component.onCompleted: {
		JS.runScript()
    }
}
