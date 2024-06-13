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

import "representation" as Rep
import "components" as DataSource
import "../tools/tools.js" as JS

PlasmoidItem {
    compactRepresentation: Rep.Panel {}
    fullRepresentation: Rep.Expanded {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 24
        Layout.minimumHeight: Kirigami.Units.gridUnit * 10
        anchors.fill: parent
        focus: true
    }

    switchWidth: Kirigami.Units.gridUnit * 24
    switchHeight: Kirigami.Units.gridUnit * 10

    Plasmoid.busy: busy
    Plasmoid.status: cfg.relevantIcon > 0 ? (count >= cfg.relevantIcon || busy || error) ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus : PlasmaCore.Types.ActiveStatus

    Plasmoid.icon: plasmoid.configuration.selectedIcon

    toolTipMainText: !interval && !busy && !error ? i18n("Auto check disabled") : ""
    toolTipSubText: busy ? statusMsg : error ? error : lastCheck

    property var listModel: listModel
    property var count
    property var cache
    property var cmd: []
    property var news: []
    property bool busy: false
    property bool upgrading: false
    property string error: ""
    property string statusMsg: ""
    property string statusIco: ""
    property string notifyTitle: ""
    property string notifyBody: ""
    property string lastCheck
    property string timestamp

    property bool interval: plasmoid.configuration.interval
    property int time: plasmoid.configuration.time
    property bool sorting: plasmoid.configuration.sorting
    property var pkg: plasmoid.configuration.packages
    property var cfg: plasmoid.configuration

    ListModel  {
        id: listModel
    }

    DataSource.Shell {
        id: sh
    }

    Notification {
        id: notify
        componentName: "apdatifier"
        eventId: cfg.withSound ? "sound" : "popup"
        title: notifyTitle
        text: notifyBody
        iconName: notifyTitle.startsWith("+") ? "apdatifier-packages" : "news-subscribe"
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
        },
        PlasmaCore.Action {
            text: i18n("Management")
            icon.name: "tools"
            enabled: !busy && !error && pkg.pacman && cfg.terminal
            onTriggered: JS.management()
        }
    ]

    Timer {
        id: searchTimer
        interval: time * 1000 * 60
        running: true
        repeat: true
        onTriggered: JS.checkUpdates()
    }

    Timer {
        id: upgradeTimer
        interval: 2000
        running: false
        repeat: true
        onTriggered: JS.upgradingState()
    }

    onTimeChanged: searchTimer.restart()
    onIntervalChanged: interval ? searchTimer.start() : searchTimer.stop()
    onSortingChanged: JS.refreshListModel()
	Component.onCompleted: JS.runScript()
}
