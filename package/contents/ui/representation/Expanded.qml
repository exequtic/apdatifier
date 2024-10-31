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

import "../scrollview" as View
import "../../tools/tools.js" as JS

Representation {
    property string currVersion: "v2.8.1"
    property bool searchFieldOpen: false

    property string statusIcon: {
        var icons = {
            "0": cfg.ownIconsUI ? "status_error" : "error",
            "1": cfg.ownIconsUI ? "status_pending" : "accept_time_event",
            "2": cfg.ownIconsUI ? "status_blank" : ""
        }
        return icons[sts.statusIco] !== undefined ? icons[sts.statusIco] : sts.statusIco
    }

    function svg(icon) {
        return Qt.resolvedUrl("../assets/icons/" + icon + ".svg")
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

                ToolButton {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    hoverEnabled: false
                    highlighted: false
                    enabled: !cfg.ownIconsUI
                    Kirigami.Icon {
                        height: parent.height
                        width: parent.height
                        anchors.centerIn: parent
                        source: cfg.ownIconsUI ? svg(statusIcon) : statusIcon
                        color: Kirigami.Theme.colorSet
                        scale: cfg.ownIconsUI ? 0.7 : 0.9
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
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

                ToolButton {
                    id: searchButton
                    ToolTip {text: i18n("Filter by package name")}
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    hoverEnabled: enabled
                    highlighted: enabled
                    enabled: sts.pending
                    visible: enabled && cfg.searchButton
                    onClicked: {
                        if (searchFieldOpen) searchField.text = ""
                        searchFieldOpen = !searchField.visible
                        searchField.focus = searchFieldOpen
                    }
                    Kirigami.Icon {
                        height: parent.height
                        width: parent.height
                        anchors.centerIn: parent
                        source: cfg.ownIconsUI ? svg("toolbar_search") : "search"
                        color: Kirigami.Theme.colorSet
                        scale: cfg.ownIconsUI ? 0.7 : 0.9
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
                }

                ToolButton {
                    ToolTip {text: cfg.interval ? i18n("Disable auto search updates") : i18n("Enable auto search updates")}
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    hoverEnabled: enabled
                    highlighted: enabled
                    enabled: sts.idle
                    visible: enabled && cfg.intervalButton
                    onClicked: JS.switchInterval()
                    Kirigami.Icon {
                        height: parent.height
                        width: parent.height
                        anchors.centerIn: parent
                        source: cfg.ownIconsUI
                                        ? (cfg.interval ? svg("toolbar_pause") : svg("toolbar_start"))
                                        : (cfg.interval ? "media-playback-paused" : "media-playback-playing")
                        color: !cfg.interval && !cfg.indicatorStop ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.colorSet
                        scale: cfg.ownIconsUI ? 0.7 : 0.9
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
                }

                ToolButton {
                    ToolTip {text: cfg.sorting ? i18n("Sort packages by name") : i18n("Sort packages by repository")}
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    hoverEnabled: enabled
                    highlighted: enabled
                    enabled: sts.pending
                    visible: enabled && cfg.sortButton
                    onClicked: cfg.sorting = !cfg.sorting
                    Kirigami.Icon {
                        height: parent.height
                        width: parent.height
                        anchors.centerIn: parent
                        source: cfg.ownIconsUI ? svg("toolbar_sort") : "sort-name"
                        color: Kirigami.Theme.colorSet
                        scale: cfg.ownIconsUI ? 0.7 : 0.9
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
                }

                ToolButton {
                    ToolTip {text: i18n("Management")}
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    hoverEnabled: enabled
                    highlighted: enabled
                    enabled: sts.idle && pkg.pacman !== "" && cfg.terminal
                    visible: enabled && cfg.managementButton
                    onClicked: JS.management()
                    Kirigami.Icon {
                        height: parent.height
                        width: parent.height
                        anchors.centerIn: parent
                        source: cfg.ownIconsUI ? svg("toolbar_management") : "tools"
                        color: Kirigami.Theme.colorSet
                        scale: cfg.ownIconsUI ? 0.7 : 0.9
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
                }

                ToolButton {
                    ToolTip {text: i18n("Upgrade system")}
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    hoverEnabled: enabled
                    highlighted: enabled
                    enabled: sts.pending && cfg.terminal
                    visible: enabled && cfg.upgradeButton
                    onClicked: JS.upgradeSystem()
                    Kirigami.Icon {
                        height: parent.height
                        width: parent.height
                        anchors.centerIn: parent
                        source: cfg.ownIconsUI ? svg("toolbar_upgrade") : "akonadiconsole"
                        color: Kirigami.Theme.colorSet
                        scale: cfg.ownIconsUI ? 0.7 : 0.9
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
                }

                ToolButton {
                    ToolTip {text: sts.busy ? i18n("Stop checking") : i18n("Check updates")}
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    hoverEnabled: enabled
                    highlighted: enabled
                    visible: cfg.checkButton && !sts.upgrading
                    onClicked: JS.checkUpdates()
                    Kirigami.Icon {
                        height: parent.height
                        width: parent.height
                        anchors.centerIn: parent
                        source: cfg.ownIconsUI ? (sts.busy ? svg("toolbar_stop") : svg("toolbar_check"))
                                               : (sts.busy ? "media-playback-stopped" : "view-refresh")
                        color: Kirigami.Theme.colorSet
                        scale: cfg.ownIconsUI ? 0.7 : 0.9
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
                }
            }
        }
    }

    footer: PlasmoidHeading {
        spacing: 0
        topPadding: 0
        height: Kirigami.Units.iconSizes.medium
        // visible: cfg.showTabBar && sts.pending
        visible: cfg.showTabBar

        contentItem: TabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.fillHeight: true
            position: TabBar.Footer

            Component.onCompleted: currentIndex = cfg.listView

            TabButton {
                id: compactViewTab
                ToolTip { text: i18n("Compact view") }
                contentItem: RowLayout {
                    Kirigami.Theme.inherit: true
                    Item { Layout.fillWidth: true }
                    Kirigami.Icon {
                        Layout.preferredHeight: height
                        height: Kirigami.Units.iconSizes.small
                        source: cfg.ownIconsUI ? svg("tab_compact") : "view-split-left-right"
                        color: Kirigami.Theme.colorSet
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
                    Item { Layout.fillWidth: true }
                }
            }

            TabButton {
                id: extendViewTab
                ToolTip { text: i18n("Extended view") }
                contentItem: RowLayout {
                    Kirigami.Theme.inherit: true
                    Item { Layout.fillWidth: true }
                    Kirigami.Icon {
                        Layout.preferredHeight: height
                        height: Kirigami.Units.iconSizes.small
                        source: cfg.ownIconsUI ? svg("tab_extended") : "view-split-top-bottom"
                        color: Kirigami.Theme.colorSet
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
                    Item { Layout.fillWidth: true }
                }
            }

            TabButton {
                id: newsViewTab
                ToolTip { text: i18n("News") }
                contentItem: RowLayout {
                    Kirigami.Theme.inherit: true
                    Item { Layout.fillWidth: true }
                    Kirigami.Icon {
                        id: newsIcon
                        Layout.preferredHeight: height
                        height: Kirigami.Units.iconSizes.small
                        source: cfg.ownIconsUI ? svg("status_news") : "news-subscribe"
                        color: Kirigami.Theme.colorSet
                        isMask: cfg.ownIconsUI
                        smooth: true
                        Label {
                            anchors.right: newsIcon.right
                            anchors.top: newsIcon.top
                            anchors.rightMargin: 6
                            anchors.topMargin: 4
                            visible: activeNewsModel.count > 0
                            text: "●"
                            color: Kirigami.Theme.negativeTextColor
                        }
                    }
                    Item { Layout.fillWidth: true }
                }
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
            Layout.topMargin: Kirigami.Units.smallSpacing * 2
            Layout.bottomMargin: Kirigami.Units.smallSpacing * 2
            icon.source: "apdatifier-plasmoid"
            text: "<b>" + i18n("Check out release notes")+" "+currVersion+"</b>"
            type: Kirigami.MessageType.Positive
            visible: sts.idle && !searchFieldOpen &&
                     plasmoid.configuration.version.localeCompare(currVersion, undefined, { numeric: true, sensitivity: 'base' }) < 0

            actions: [
                Kirigami.Action {
                    tooltip: i18n("Select...")
                    icon.name: "application-menu"
                    expandible: true

                    Kirigami.Action {
                        text: "GitHub"
                        icon.name: "internet-web-browser-symbolic"
                        onTriggered: Qt.openUrlExternally("https://github.com/exequtic/apdatifier/releases")
                    }
                    Kirigami.Action {
                        text: i18n("Hide")
                        icon.name: "hint"
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

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            View.Compact {}
            View.Extended {}
            View.News {}
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

            ToolButton {
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                hoverEnabled: false
                highlighted: false
                enabled: false
                Kirigami.Icon {
                    height: parent.height
                    width: parent.height
                    anchors.centerIn: parent
                    source: cfg.ownIconsUI ? svg(statusIcon) : statusIcon
                    color: Kirigami.Theme.colorSet
                    scale: cfg.ownIconsUI ? 0.7 : 0.9
                    isMask: cfg.ownIconsUI
                    smooth: true
                }
            }

            DescriptiveLabel {
                text: sts.statusMsg
                font.bold: true
            }
        }
    }

    PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - (Kirigami.Units.gridUnit * 4)
        enabled: tabBar.currentIndex < 2 && sts.updated
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

    PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - (Kirigami.Units.gridUnit * 4)
        enabled: tabBar.currentIndex === 2 && activeNewsModel.count === 0 && sts.idle
        visible: enabled
        iconName: "face-cool"
        text: i18n("No unread news")
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
                var index = tabBar.currentIndex
                if (deltaX > 80 && index < 2) {
                    index += 1
                } else if (deltaX < -80 && index > 0) {
                    index -= 1
                } else {
                    return
                }
                tabBar.currentIndex = index
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
