/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

import "shared"
import "components"
import "representation" as Rep
import "../tools/tools.js" as JS

PlasmoidItem {
    id: root
    compactRepresentation: Rep.Panel {}
    fullRepresentation: Rep.Expanded {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 24
        Layout.minimumHeight: Kirigami.Units.gridUnit * 16
        anchors.fill: parent
        focus: true
    }

    switchWidth: Kirigami.Units.gridUnit * 24
    switchHeight: Kirigami.Units.gridUnit * 16

    Plasmoid.busy: plasmoid.location === PlasmaCore.Types.Floating ? false : sts.busy
    Plasmoid.status: cfg.relevantIcon > 0 ? (sts.count >= cfg.relevantIcon || sts.busy || sts.error) ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus : PlasmaCore.Types.ActiveStatus
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.icon: plasmoid.configuration.selectedIcon

    toolTipMainText: sts.paused ? i18n("Auto check disabled") : ""
    toolTipSubText: sts.busy ? sts.statusMsg : sts.checktime

    hideOnWindowDeactivate: !pinned

    property bool isMainInstance: false
    property bool inTray: (plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentDrawsPlasmoidHeading)
    property bool onDesktop: plasmoid.location === PlasmaCore.Types.Floating
    property bool horizontal: plasmoid.location === PlasmaCore.Types.TopEdge || plasmoid.location === PlasmaCore.Types.BottomEdge
    property bool pinned: false
    property var cache: []
    property string checkMode: plasmoid.configuration.checkMode
    property bool sorting: plasmoid.configuration.sorting
    property string rules: plasmoid.configuration.rules || ""
    property var pkg: plasmoid.configuration.packages || ""
    property var cfg: plasmoid.configuration
    property var configuration: JSON.stringify(cfg)

    QtObject {
        id: sts
        property bool init: false
        property var errors: []
        property int count: 0
        property bool busy: false
        property bool upgrading: false
        property bool error: !busy && errors.length > 0
        property bool paused: !busy && !scheduler.running && cfg.checkMode !== "manual"
        property string statusMsg: ""
        property string statusIco: ""
        property string checktime: ""
        property var proc: null
    }

    ListModel  {
        id: listModel
    }

    ListModel  {
        id: newsModel
    }

    ListModel {
        id: activeNewsModel
    }

    Notification {
        id: notify
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            id: checkUpdatesAction
            text: i18n("Check updates")
            icon.name: "view-refresh"
            enabled: !sts.upgrading
            onTriggered: JS.checkUpdates()
        },
        PlasmaCore.Action {
            id: upgradeSystemAction
            text: i18n("Upgrade system")
            icon.name: "akonadiconsole"
            enabled: (cfg.terminal && cfg.tmuxSession && sts.count) || (cfg.terminal && !sts.busy && sts.count)
            onTriggered: JS.upgradeSystem()
        },
        PlasmaCore.Action {
            id: managementAction
            text: i18n("Management")
            icon.name: "tools"
            enabled: cfg.terminal && pkg.pacman
            onTriggered: JS.management()
        }
    ]

    Timer {
        id: scheduler
        interval: 10 * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: JS.searchScheduler()
    }

    Timer {
        id: upgradeTimer
        interval: 1000
        repeat: true
        onTriggered: JS.upgradingState()
    }

    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: JS.saveConfig()
    }

    onCheckModeChanged: sts.init && scheduler.restart()
    onSortingChanged: sts.init && JS.refreshListModel()
    onRulesChanged: sts.init && JS.refreshListModel()
    onConfigurationChanged: saveTimer.start()

    function applyUiPolicy() {
        Plasmoid.hasConfigurationInterface = false
        checkUpdatesAction.visible = false
        upgradeSystemAction.visible = false
        managementAction.visible = false
    }

	Component.onCompleted: {
        if (!Instance.isRunning) {
            JS.init()
            Instance.isRunning = true
            isMainInstance = true
        } else {
            applyUiPolicy()
            sts.errors = [{code: -1, message: "This widget supports only one running instance. Remove the other instance(s), then restart plasmashell."}]
            root.toolTipMainText = ""
            root.toolTipSubText = sts.errors[0].message
        }
    }
}
