/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kitemmodels
import org.kde.plasma.extras
import org.kde.plasma.components
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

import "../scrollview" as View
import "../../tools/tools.js" as JS

Representation {
    property string currVersion: "v2.9.2"
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
                    visible: cfg.searchButton && sts.pending
                    enabled: visible && swipeView.currentIndex != 2
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
                    visible: cfg.sortButton && sts.pending
                    enabled: visible && swipeView.currentIndex != 2
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
        visible: cfg.tabBarVisible

        contentItem: TabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.fillHeight: true
            position: TabBar.Footer
            currentIndex: swipeView.currentIndex
            onCurrentIndexChanged: {
                swipeView.currentIndex = currentIndex
                if (swipeView.currentIndex === 2) {
                    searchFieldOpen = false
                    searchField.text = ""
                }
            }

            TabButton {
                id: compactViewTab
                ToolTip { text: cfg.tabBarTexts ? "" : i18n("Compact view") }
                contentItem: RowLayout {
                    Kirigami.Theme.inherit: true
                    Item { Layout.fillWidth: true }
                    Kirigami.Icon {
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        source: cfg.ownIconsUI ? svg("tab_compact") : "view-split-left-right"
                        color: Kirigami.Theme.colorSet
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
                    Label { text: i18n("Compact"); visible: cfg.tabBarTexts }
                    Item { Layout.fillWidth: true }
                }
            }

            TabButton {
                id: extendViewTab
                ToolTip { text: cfg.tabBarTexts ? "" : i18n("Extended view") }
                contentItem: RowLayout {
                    Kirigami.Theme.inherit: true
                    Item { Layout.fillWidth: true }
                    Kirigami.Icon {
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        source: cfg.ownIconsUI ? svg("tab_extended") : "view-split-top-bottom"
                        color: Kirigami.Theme.colorSet
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
                    Label { text: i18n("Extended"); visible: cfg.tabBarTexts }
                    Item { Layout.fillWidth: true }
                }
            }

            TabButton {
                id: newsViewTab
                ToolTip { text: cfg.tabBarTexts ? "" : i18n("News") }
                contentItem: RowLayout {
                    Kirigami.Theme.inherit: true
                    Item { Layout.fillWidth: true }
                    Kirigami.Icon {
                        id: newsIcon
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        source: cfg.ownIconsUI ? svg("status_news") : "news-subscribe"
                        color: activeNewsModel.count > 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.colorSet
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
                    Label { text: i18n("News"); visible: cfg.tabBarTexts }
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
            onTextChanged: modelList.setFilterFixedString(text)
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing * 2
            Layout.bottomMargin: Kirigami.Units.smallSpacing * 2
            icon.source: "apdatifier-plasmoid"
            text: "<b>" + i18n("Check out release notes")+" "+currVersion+"</b>"
            type: Kirigami.MessageType.Positive
            visible: !searchFieldOpen &&
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
                        text: i18n("Dismiss")
                        icon.name: "dialog-close"
                        onTriggered: plasmoid.configuration.version = currVersion
                    }
                }
            ]
        }

        SwipeView {
            id: swipeView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            View.Compact {}
            View.Extended {}
            View.News {}
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
}
