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
    id: root
    property bool searchFieldOpen: false
    property var pkgIcons: cfg.customIcons
    property bool newsVisibility: !busy && Object.keys(news).length !== 0 && !news.dismissed && !searchFieldOpen
    function updateVisibility() { newsVisibility = !news.dismissed; }

    property string statusIcon: {
        var icons = {
            "0": cfg.ownIconsUI ? "status_error" : "error",
            "1": cfg.ownIconsUI ? "status_pending" : "accept_time_event",
            "2": cfg.ownIconsUI ? "status_blank" : ""
        }
        return icons[statusIco] !== undefined ? icons[statusIco] : statusIco
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
                    text: statusMsg
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
                    enabled: !busy && !error && count > 0
                    visible: enabled && cfg.searchButton
                    tooltipText: i18n("Filter by package name")
                }
                QQC.ToolButton {
                    icon.source: cfg.ownIconsUI
                                    ? (cfg.interval ? "toolbar_pause" : "toolbar_start")
                                    : (cfg.interval ? "media-playback-paused" : "media-playback-playing")
                    color: !cfg.interval && !cfg.indicatorStop ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.colorSet
                    onClicked: JS.switchInterval()
                    enabled: !busy && !error
                    visible: enabled && cfg.intervalButton
                    tooltipText: cfg.interval ? i18n("Disable auto search updates") : i18n("Enable auto search updates")
                }
                QQC.ToolButton {
                    icon.source: cfg.ownIconsUI ? "toolbar_sort" : "sort-name"
                    onClicked: cfg.sorting = !cfg.sorting
                    enabled: !busy && !error && count > 0
                    visible: enabled && cfg.sortButton
                    tooltipText: cfg.sorting ? i18n("Sort packages by name") : i18n("Sort packages by repository")
                }
                QQC.ToolButton {
                    icon.source: cfg.ownIconsUI ? "toolbar_management" : "tools"
                    onClicked: JS.management()
                    enabled: !busy && !error && pkg.pacman && cfg.terminal
                    visible: enabled && cfg.managementButton
                    tooltipText: i18n("Management")
                }
                QQC.ToolButton {
                    icon.source: cfg.ownIconsUI ? "toolbar_upgrade" : "akonadiconsole"
                    onClicked: JS.upgradeSystem()
                    enabled: !busy && !error && count > 0 && cfg.terminal
                    visible: enabled && cfg.upgradeButton
                    tooltipText: i18n("Upgrade system")
                }
                QQC.ToolButton {
                    icon.source: cfg.ownIconsUI ? (busy ? "toolbar_stop" : "toolbar_check")
                                                : (busy ? "media-playback-stopped" : "view-refresh")
                    onClicked: JS.checkUpdates()
                    visible: cfg.checkButton && !upgrading
                    tooltipText: busy ? i18n("Stop checking") : i18n("Check updates")
                }
            }
        }
    }

    footer: PlasmoidHeading {
        spacing: 0
        topPadding: 0
        height: Kirigami.Units.iconSizes.medium
        visible: cfg.showTabBar && !error && !busy && count > 0

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
            visible: searchFieldOpen && !busy && !error && count > 0
            placeholderText: i18n("Filter by package name")

            onTextChanged: {
                if (searchFieldOpen) modelList.setFilterFixedString(text)
                if (!searchFieldOpen) return
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: newsVisibility

            icon.source: "news-subscribe"
            text: news ? i18n("<b>Check out the latest news!") + " (" + news.date + ")</b>" + i18n("<br><b>Article: </b>") + news.article : ""
            onLinkActivated: Qt.openUrlExternally(link)
            type: Kirigami.MessageType.Positive

            actions: [
                Kirigami.Action {
                    text: i18n("Read article")
                    icon.name: "internet-web-browser"
                    onTriggered: {
                        Qt.openUrlExternally(news.link)
                    }
                },
                Kirigami.Action {
                    text: i18n("Dismiss")
                    icon.name: "dialog-close"
                    onTriggered: {
                        news.dismissed = true
                        sh.exec(JS.writeFile(JSON.stringify(news), JS.newsFile))
                        updateVisibility()
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

    Loader {
        anchors.centerIn: parent
        enabled: busy && plasmoid.location !== PlasmaCore.Types.Floating
        visible: enabled
        asynchronous: true

        ColumnLayout {
            Layout.maximumWidth: 128
            Layout.maximumHeight: 128
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing * 5
            
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
                    text: statusMsg
                }
            }
        }
    }

    Loader {
        anchors.centerIn: parent
        width: parent.width - (Kirigami.Units.gridUnit * 4)
        enabled: !busy && !error && count === 0
        visible: enabled
        asynchronous: true
        sourceComponent: PlaceholderMessage {
            width: parent.width
            iconName: "checkmark"
            text: i18n("System updated")
        }
    }

    Loader {
        anchors.centerIn: parent
        width: parent.width - (Kirigami.Units.gridUnit * 4)
        enabled: !busy && error
        visible: enabled
        asynchronous: true
        sourceComponent: PlaceholderMessage {
            width: parent.width
            iconName: "error"
            text: error
        }
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
            running: false
            repeat: true
            onTriggered: {
                mouseArea.cursorShape = Qt.ClosedHandCursor
            }
        }
    }
}
