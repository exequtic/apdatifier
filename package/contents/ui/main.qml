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
        Layout.minimumHeight: Kirigami.Units.gridUnit * 16
        anchors.fill: parent
        focus: true
    }

    switchWidth: Kirigami.Units.gridUnit * 24
    switchHeight: Kirigami.Units.gridUnit * 16

    Plasmoid.busy: sts.busy
    Plasmoid.status: cfg.relevantIcon > 0 ? (sts.count >= cfg.relevantIcon || sts.busy || sts.err) ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus : PlasmaCore.Types.ActiveStatus

    Plasmoid.icon: plasmoid.configuration.selectedIcon

    toolTipMainText: !interval && sts.idle ? i18n("Auto check disabled") : ""
    toolTipSubText: sts.busy ? sts.statusMsg : sts.err ? sts.errMsg : sts.checktime

    property var listModel: listModel
    property var cache: []
    property var cmd: []
    property var notify: JS.notifyParams
    property int time: plasmoid.configuration.time
    property bool interval: plasmoid.configuration.interval
    property bool sorting: plasmoid.configuration.sorting
    property string rules: plasmoid.configuration.rules || ""
    property var pkg: plasmoid.configuration.packages || ""
    property var cfg: plasmoid.configuration
    property var configuration: JSON.stringify(cfg)

    QtObject {
        id: sts
        property int count: 0
        property bool busy: false
        property bool upgrading: false
        property bool err: !!errMsg
        property bool idle: !busy && !err
        property bool updated: idle && !count
        property bool pending: idle && count
        property string errMsg: ""
        property string statusMsg: ""
        property string statusIco: ""
        property string checktime: ""
    }

    ListModel  {
        id: listModel
    }

    Notification {
        id: notification
        componentName: "apdatifier"
        eventId: notify.event
        title: notify.title
        text: notify.body
        iconName: notify.icon
        flags: cfg.notifyPersistent ? Notification.Persistent : Notification.CloseOnTimeout
        urgency: Notification[notify.urgency] || Notification.DefaultUrgency
        actions: [
            NotificationAction {
                label: notify.label
                onActivated: JS[notify.action]()
            }
        ]
    }

    DataSource.Shell {
        id: sh
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Check updates")
            icon.name: "view-refresh"
            enabled: !sts.upgrading
            onTriggered: JS.checkUpdates()
        },
        PlasmaCore.Action {
            text: i18n("Upgrade system")
            icon.name: "akonadiconsole"
            enabled: sts.pending && cfg.terminal
            onTriggered: JS.upgradeSystem()
        },
        PlasmaCore.Action {
            text: i18n("Management")
            icon.name: "tools"
            enabled: sts.idle && pkg.pacman && cfg.terminal
            onTriggered: JS.management()
        }
    ]

    Timer {
        id: searchTimer
        interval: time * 1000 * 60
        repeat: true
        onTriggered: JS.checkUpdates()
    }

    Timer {
        id: upgradeTimer
        interval: 5000
        repeat: true
        onTriggered: JS.upgradingState()
    }

    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: JS.saveConfig()
    }

    Timer {
        id: initTimer
        running: true
        interval: 50
    }

    function refresh() {
        if (initTimer.running) return
        JS.refreshListModel()
    }

    onTimeChanged: searchTimer.restart()
    onIntervalChanged: interval ? searchTimer.start() : searchTimer.stop()
    onSortingChanged: refresh()
    onRulesChanged: refresh()
    onConfigurationChanged: saveTimer.start()
	Component.onCompleted: JS.start()
}
