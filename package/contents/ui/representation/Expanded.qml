/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.kitemmodels
import org.kde.plasma.extras
import org.kde.plasma.components
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

import "../components" as QQC
import "../scrollview" as View
import "../../tools/tools.js" as JS

Representation {
    property string currVersion: "v2.8"
    property bool searchFieldOpen: false

    property string statusIcon: {
        var icons = {
            "0": cfg.ownIconsUI ? "status_error" : "error",
            "1": cfg.ownIconsUI ? "status_pending" : "accept_time_event",
            "2": cfg.ownIconsUI ? "status_blank" : ""
        }
        return icons[sts.statusIco] !== undefined ? icons[sts.statusIco] : sts.statusIco
    }

    header: PlasmoidHeading {
        visible: cfg.showStatusText || cfg.showToolBar
        contentItem: RowLayout {
            id: toolBar
            Layout.fillWidth: true
            Layout.minimumHeight: Kirigami.Units.iconSizes.medium
            Layout.maximumHeight: Kirigami.Units.iconSizes.medium

            RowLayout {
                id: status
                Layout.alignment: cfg.showToolBar ? Qt.AlignLeft : Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing / 2
                visible: cfg.showStatusText

                QQC.ToolButton {
                    icon.source: statusIcon
                    hoverEnabled: false
                    highlighted: false
                    enabled: !cfg.ownIconsUI
                }

                DescriptiveLabel {
                    Layout.maximumWidth: toolBar.width - toolBarButtons.width - Kirigami.Units.iconSizes.smallMedium
                    Layout.alignment: Qt.AlignLeft
                    text: sts.statusMsg
                    elide: Text.ElideRight
                    font.bold: true
                }
            }

            RowLayout {
                id: toolBarButtons
                Layout.alignment: Qt.AlignRight
                spacing: Kirigami.Units.smallSpacing
                visible: cfg.showToolBar

                QQC.ToolButton {
                    id: searchButton
                    icon.source: cfg.ownIconsUI ? "toolbar_search" : "search"
                    onClicked: {
                        if (searchFieldOpen) searchField.text = ""
                        searchFieldOpen = !searchField.visible
                        searchField.focus = searchFieldOpen
                    }
                    enabled: sts.pending
                    visible: enabled && cfg.searchButton
                    tooltipText: i18n("Filter by package name")
                }
                QQC.ToolButton {
                    icon.source: cfg.ownIconsUI
                                    ? (cfg.interval ? "toolbar_pause" : "toolbar_start")
                                    : (cfg.interval ? "media-playback-paused" : "media-playback-playing")
                    color: !cfg.interval && !cfg.indicatorStop ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.colorSet
                    onClicked: JS.switchInterval()
                    enabled: sts.idle
                    visible: enabled && cfg.intervalButton
                    tooltipText: cfg.interval ? i18n("Disable auto search updates") : i18n("Enable auto search updates")
                }
                QQC.ToolButton {
                    icon.source: cfg.ownIconsUI ? "toolbar_sort" : "sort-name"
                    onClicked: cfg.sorting = !cfg.sorting
                    enabled: sts.pending
                    visible: enabled && cfg.sortButton
                    tooltipText: cfg.sorting ? i18n("Sort packages by name") : i18n("Sort packages by repository")
                }
                QQC.ToolButton {
                    icon.source: cfg.ownIconsUI ? "toolbar_management" : "tools"
                    onClicked: JS.management()
                    enabled: sts.idle && pkg.pacman !== "" && cfg.terminal
                    visible: enabled && cfg.managementButton
                    tooltipText: i18n("Management")
                }
                QQC.ToolButton {
                    icon.source: cfg.ownIconsUI ? "toolbar_upgrade" : "akonadiconsole"
                    onClicked: JS.upgradeSystem()
                    enabled: sts.pending && cfg.terminal
                    visible: enabled && cfg.upgradeButton
                    tooltipText: i18n("Upgrade system")
                }
                QQC.ToolButton {
                    icon.source: cfg.ownIconsUI ? (sts.busy ? "toolbar_stop" : "toolbar_check")
                                                : (sts.busy ? "media-playback-stopped" : "view-refresh")
                    onClicked: JS.checkUpdates()
                    visible: cfg.checkButton && !sts.upgrading
                    tooltipText: sts.busy ? i18n("Stop checking") : i18n("Check updates")
                }
            }
        }
    }

    footer: PlasmoidHeading {
        spacing: 0
        topPadding: 0
        height: Kirigami.Units.iconSizes.medium
        visible: cfg.showTabBar && sts.pending

        contentItem: TabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.fillHeight: true
            position: TabBar.Footer

            property int listView: cfg.listView
            onListViewChanged: currentIndex = listView
            onCurrentIndexChanged: cfg.listView = currentIndex
            Component.onCompleted: currentIndex = listView

            QQC.TabButton {
                id: compactViewTab
                icon.source: cfg.ownIconsUI ? "tab_compact" : "view-split-left-right"
                ToolTip { text: i18n("Compact view") }
            }

            QQC.TabButton {
                id: extendViewTab
                icon.source: cfg.ownIconsUI ? "tab_extended" : "view-split-top-bottom"
                ToolTip { text: i18n("Extended view") }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TextField {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing * 2
            Layout.bottomMargin: Kirigami.Units.smallSpacing * 2
            Layout.leftMargin: Kirigami.Units.smallSpacing * 2
            Layout.rightMargin: Kirigami.Units.smallSpacing * 2

            id: searchField
            clearButtonShown: true
            visible: searchFieldOpen && sts.pending
            placeholderText: i18n("Filter by package name")

            onTextChanged: {
                if (searchFieldOpen) modelList.setFilterFixedString(text)
                if (!searchFieldOpen) return
            }
        }

        Kirigami.InlineMessage {
            id: releaseMsg
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.smallSpacing * 2
            icon.source: "apdatifier-plasmoid"
            text: "<b>" + i18n("Check out release notes")+" "+currVersion+"</b>"
            type: Kirigami.MessageType.Positive
            visible: sts.idle && !searchFieldOpen &&
                     parseFloat(plasmoid.configuration.version.replace(/v/g, "")) < parseFloat(currVersion.replace(/v/g, ""))

            actions: [
                Kirigami.Action {
                    tooltip: i18n("Select...")
                    icon.name: "menu_new"
                    expandible: true

                    Kirigami.Action {
                        text: "GitHub"
                        icon.name: "internet-web-browser"
                        onTriggered: Qt.openUrlExternally("https://github.com/exequtic/apdatifier/releases")
                    }
                    Kirigami.Action {
                        text: i18n("Hide")
                        icon.name: "gnumeric-row-hide"
                        onTriggered: releaseMsg.visible = false
                    }
                    Kirigami.Action {
                        text: i18n("Dismiss")
                        icon.name: "dialog-close"
                        onTriggered: plasmoid.configuration.version = currVersion
                    }
                }
            ]
        }

        Kirigami.InlineMessage {
            id: newsMsg
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.smallSpacing * 2
            icon.source: "news-subscribe"
            text: cfg.news
            type: Kirigami.MessageType.Warning
            visible: sts.pending && cfg.newsMsg && !searchFieldOpen

            actions: [
                Kirigami.Action {
                    tooltip: i18n("Select...")
                    icon.name: "menu_new"
                    expandible: true

                    Kirigami.Action {
                        text: i18n("Read article")
                        icon.name: "internet-web-browser"
                        onTriggered: JS.openNewsLink()
                    }
                    Kirigami.Action {
                        text: i18n("Hide")
                        icon.name: "gnumeric-row-hide"
                        onTriggered: newsMsg.visible = false
                    }
                    Kirigami.Action {
                        text: i18n("Dismiss")
                        icon.name: "dialog-close"
                        onTriggered: cfg.newsMsg = false
                    }
                }
            ]
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            View.Compact {}
            View.Extended {}
        }
    }

    ColumnLayout {
        Layout.maximumWidth: 128
        Layout.maximumHeight: 128
        anchors.centerIn: parent
        spacing: Kirigami.Units.largeSpacing * 5
        enabled: sts.busy && plasmoid.location !== PlasmaCore.Types.Floating
        visible: enabled
        
        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 128
            Layout.preferredHeight: 128
            opacity: 0.6
            running: true
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            visible: !cfg.showStatusText

            QQC.ToolButton {
                icon.source: statusIcon
                hoverEnabled: false
                highlighted: false
                enabled: false
            }

            DescriptiveLabel {
                text: sts.statusMsg
            }
        }
    }

    PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - (Kirigami.Units.gridUnit * 4)
        enabled: sts.updated
        visible: enabled
        iconName: "checkmark"
        text: i18n("System updated")
    }

    PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - (Kirigami.Units.gridUnit * 4)
        enabled: !sts.busy && sts.err
        visible: enabled
        iconName: "error"
        text: sts.errMsg
    }

    KSortFilterProxyModel {
        id: modelList
        sourceModel: listModel
        filterRoleName: "name"
        filterRowCallback: (sourceRow, sourceParent) => {
            return sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), filterRole).includes(searchField.text)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons

        property real startX: 0

        onPressed: mouse => {
            if (mouse.button == Qt.LeftButton) {
                mouse.accepted = false
            } else {
                holdTimer.start()
                startX = mouseArea.mouseX
            }
        }

        onReleased: {
            holdTimer.stop()
            mouseArea.cursorShape = Qt.ArrowCursor
        }

        onPositionChanged: {
            if (mouseArea.cursorShape == Qt.ClosedHandCursor) {
                var deltaX = mouseX - startX
                if (deltaX > 80) {
                    tabBar.currentIndex = 1
                } else if (deltaX < -80) {
                    tabBar.currentIndex = 0
                } else {
                    return
                }
                startX = mouseArea.mouseX
            }
        }

        Timer {
            id: holdTimer
            interval: 200
            repeat: true
            onTriggered: mouseArea.cursorShape = Qt.ClosedHandCursor
        }
    }
}
