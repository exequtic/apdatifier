import QtQuick
import QtQuick.Layouts

import org.kde.kitemmodels
import org.kde.plasma.extras
import org.kde.plasma.plasmoid
import org.kde.plasma.components
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

import "../components"
import "../scrollview" as View
import "../../tools/tools.js" as JS

Representation {
    property string currVersion: "v2.9.7"
    property bool searchFieldOpen: false
    property bool expanded: root.expanded
    onExpandedChanged: {
        if (plasmoid.configuration.switchDefaultTab && !expanded)
            swipeView.currentIndex = plasmoid.configuration.defaultTab
    }

    function svg(icon) {
        return Qt.resolvedUrl("../assets/icons/" + icon + ".svg")
    }

    property var backgroundHidden: (Plasmoid.formFactor === PlasmaCore.Types.Planar) && (Plasmoid.userBackgroundHints === PlasmaCore.Types.ShadowBackground)
    onBackgroundHiddenChanged: topHeader.background.visible = bottomHeader.background.visible = !backgroundHidden

    header: PlasmoidHeading {
        id: topHeader
        visible: (cfg.showStatusText || cfg.showToolBar) && !sts.error
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

                Item {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium

                    Kirigami.Icon {
                        height: parent.height
                        width: parent.height
                        anchors.centerIn: parent
                        source: cfg.ownIconsUI ? svg(sts.statusIco) : sts.statusIco
                        color: Kirigami.Theme.colorSet
                        scale: cfg.ownIconsUI ? 0.7 : 0.9
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
                }

                Label {
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

                ToolbarButton {
                    id: searchButton
                    tooltipText: i18n("Filter by package name")
                    iconSource: cfg.ownIconsUI ? svg("toolbar_search") : "search"
                    visible: cfg.searchButton && !sts.busy && sts.count
                    enabled: visible && swipeView.currentIndex != 2
                    onClicked: {
                        if (searchFieldOpen) searchField.text = ""
                        searchFieldOpen = !searchField.visible
                        searchField.focus = searchFieldOpen
                    }
                }

                ToolbarButton {
                    tooltipText: sts.paused ? i18n("Disable auto search updates") : i18n("Enable auto search updates")
                    iconSource: cfg.ownIconsUI ? (!sts.paused ? svg("toolbar_pause") : svg("toolbar_start"))
                                               : (!sts.paused ? "media-playback-paused" : "media-playback-playing")
                    iconColor: sts.paused ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.colorSet
                    enabled: !sts.busy
                    visible: enabled && cfg.intervalButton && cfg.checkMode !== "manual"
                    onClicked: JS.switchScheduler()
                }

                ToolbarButton {
                    tooltipText: cfg.sorting ? i18n("Sort packages by name") : i18n("Sort packages by repository")
                    iconSource: cfg.ownIconsUI ? svg("toolbar_sort") : "sort-name"
                    visible: cfg.sortButton && !sts.busy && sts.count
                    enabled: visible && swipeView.currentIndex != 2
                    onClicked: cfg.sorting = !cfg.sorting
                }

                ToolbarButton {
                    id: managementButton
                    tooltipText: i18n("Management")
                    iconSource: cfg.ownIconsUI ? svg("toolbar_management") : "tools"
                    enabled: !sts.busy && pkg.pacman !== "" && cfg.terminal
                    visible: enabled && cfg.managementButton
                    onClicked: { buttonTooltip.hide(); JS.management() }
                }

                ToolbarButton {
                    id: upgradeButton
                    tooltipText: i18n("Upgrade system")
                    iconSource: cfg.ownIconsUI ? svg("toolbar_upgrade") : "akonadiconsole"
                    enabled: !sts.busy && sts.count && cfg.terminal
                    visible: enabled && cfg.upgradeButton
                    onClicked: { buttonTooltip.hide(); JS.upgradeSystem() }
                }

                ToolbarButton {
                    tooltipText: sts.busy ? i18n("Stop checking") : i18n("Check updates")
                    iconSource: cfg.ownIconsUI ? (sts.busy ? svg("toolbar_stop") : svg("toolbar_check"))
                                               : (sts.busy ? "media-playback-stopped" : "view-refresh")
                    visible: cfg.checkButton && !sts.upgrading
                    onClicked: JS.checkUpdates()
                }

                ToolbarButton {
                    tooltipText: i18n("Open settings")
                    iconSource: cfg.ownIconsUI ? svg("toolbar_settings") : "settings-configure"
                    visible: cfg.settingsButton && !inTray && !sts.busy
                    onClicked: plasmoid.internalAction("configure").trigger()
                }

                ToolbarButton {
                    tooltipText: pinned ? i18n("Unpin window") : i18n("Keep open")
                    iconSource: cfg.ownIconsUI ? (pinned ? svg("toolbar_unpin") : svg("toolbar_pin"))
                                               : (pinned ? "window-unpin" : "window-pin")
                    visible: cfg.pinButton && !inTray && !onDesktop
                    onClicked: pinned = !pinned
                }
            }
        }
    }

    footer: PlasmoidHeading {
        id: bottomHeader
        spacing: 0
        topPadding: 0
        height: Kirigami.Units.iconSizes.medium
        visible: cfg.tabBarVisible && !sts.error

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
            visible: searchFieldOpen && !sts.busy && sts.count
            placeholderText: i18n("Filter by package name")
            onTextChanged: modelList.setFilterFixedString(text)
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing * 2
            Layout.bottomMargin: Kirigami.Units.smallSpacing * 2
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
            currentIndex: plasmoid.configuration.defaultTab
            View.Compact {}
            View.Extended {}
            View.News {}
        }
    }

    Rectangle {
        z: 9998
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        visible: errorLoader.active
    }
    Loader {
        z: 9999
        id: errorLoader
        anchors.centerIn: parent
        active: !sts.busy && sts.error
        sourceComponent: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing * 2
            Layout.fillWidth: true

            RowLayout {
                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    source: cfg.ownIconsUI ? svg("status_error") : "error"
                    isMask: cfg.ownIconsUI
                }
                Kirigami.Heading {
                    text: i18np("%1 error occurred", "%1 errors occurred", sts.errors.length)
                    type: Kirigami.Heading.Primary   
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            ScrollView {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                Layout.preferredHeight: Kirigami.Units.gridUnit * 8

                TextArea {
                    width: parent.width
                    height: parent.height
                    readOnly: true
                    wrapMode: Text.Wrap
                    font.family: "Monospace"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    text: sts.errors.map(err => err?.type ? `${err.type}: ${err.message}` : `${err.message}`).join("\n\n")
                    color: Kirigami.Theme.textColor
                }
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                icon.name: "checkmark"
                text: "OK"
                onClicked: {
                    sts.errors = []
                    JS.setStatusBar()
                }
            }
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
