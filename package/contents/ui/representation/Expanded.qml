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
    property string currVersion: "v2.9.9"
    property bool searchFieldOpen: false
    property bool expanded: root.expanded
    onExpandedChanged: {
        if (plasmoid.configuration.switchDefaultTab && !expanded)
            listCompactMode = (plasmoid.configuration.defaultTab !== 0)
    }

    function svg(icon) {
        return Qt.resolvedUrl("../assets/icons/" + icon + ".svg")
    }

    property var backgroundHidden: (Plasmoid.formFactor === PlasmaCore.Types.Planar) && (Plasmoid.userBackgroundHints === PlasmaCore.Types.ShadowBackground)
    onBackgroundHiddenChanged: topHeader.background.visible = bottomHeader.background.visible = !backgroundHidden


    property bool activeNewsItems: false
    function checkActiveNewsItems() {
        activeNewsItems = false
        for (let i = 0; i < newsModel.count; ++i) {
            if (newsModel.get(i).removed === false) {
                activeNewsItems = true
                return
            }
        }
    }

    Connections {
        target: newsModel
        function onDataChanged() {
            checkActiveNewsItems()
        }
        function onCountChanged() {
            checkActiveNewsItems()
        }
    }

    Component.onCompleted: checkActiveNewsItems()

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
                    visible: cfg.searchButton && sts.count
                    enabled: visible && swipeView.currentIndex === 0
                    onClicked: {
                        if (searchFieldOpen) searchField.text = ""
                        searchFieldOpen = !searchField.visible
                        searchField.focus = searchFieldOpen
                    }
                }

                ToolbarButton {
                    tooltipText: sts.paused ? i18n("Enable auto search updates") : i18n("Disable auto search updates")
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
                    enabled: visible && swipeView.currentIndex === 0
                    onClicked: cfg.sorting = !cfg.sorting
                }

                ToolbarButton {
                    tooltipText: listCompactMode ? i18n("Extended") : i18n("Compact")
                    iconSource: cfg.ownIconsUI ? (listCompactMode ? svg("tab_extended") : svg("tab_compact"))
                                               : (listCompactMode ? "view-split-top-bottom" : "view-split-left-right")


                    visible: cfg.viewButton && sts.count && swipeView.currentIndex === 0
                    enabled: visible
                    onClicked: listCompactMode = !listCompactMode
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
                    onClicked: sts.proc ? JS.stopCheck() : JS.checkUpdates()
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
        visible: cfg.tabBarVisible && cfg.feedsEnabled && !sts.error

        contentItem: TabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.fillHeight: true
            position: TabBar.Footer
            currentIndex: swipeView.currentIndex
            onCurrentIndexChanged: {
                swipeView.currentIndex = currentIndex
                if (swipeView.currentIndex >= 1) {
                    searchFieldOpen = false
                    searchField.text = ""
                }
            }

            Repeater {
                model: [
                    {
                        id: "updates",
                        icon: "status_package",
                        fallback: "kpackagekit-updates",
                        label: i18n("Updates"),
                    },
                    cfg.feedsEnabled ? {
                        id: "news",
                        icon: "status_news",
                        fallback: "news-subscribe",
                        label: i18n("News"),
                    } : null
                    ].filter(Boolean)

                delegate: TabButton {
                    required property var modelData
                    contentItem: RowLayout {
                        Kirigami.Theme.inherit: true
                        Item { Layout.fillWidth: true }
                        Kirigami.Icon {
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            source: cfg.ownIconsUI ? svg(modelData.icon) : modelData.fallback
                            color: (modelData.id === "news" && activeNewsItems) ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.colorSet
                            isMask: cfg.ownIconsUI
                            smooth: true
                        }
                        Label { text: modelData.label; visible: cfg.tabBarTexts }
                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Loader {
            Layout.fillWidth: true
            active: sts.busy
            sourceComponent: ProgressBar { from: 0; to: 100; indeterminate: true }
        }

        TextField {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing * 2
            Layout.bottomMargin: Kirigami.Units.smallSpacing * 2
            Layout.leftMargin: Kirigami.Units.smallSpacing * 2
            Layout.rightMargin: Kirigami.Units.smallSpacing * 2

            id: searchField
            clearButtonShown: true
            visible: searchFieldOpen && sts.count
            placeholderText: i18n("Filter by package name")
            onTextChanged: modelList.setFilterFixedString(text)
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing * 2
            Layout.bottomMargin: Kirigami.Units.smallSpacing * 2
            text: "<b>" + i18n("Check out release notes")+" "+currVersion+"</b>"
            type: Kirigami.MessageType.Positive
            visible: !searchFieldOpen && isOnline &&
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

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing * 2
            Layout.bottomMargin: Kirigami.Units.smallSpacing * 2
            text: "<b>" + i18n("No internet connection") + "</b>"
            type: Kirigami.MessageType.Error
            visible: !isOnline
        }

        SwipeView {
            id: swipeView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            currentIndex: 0
            Repeater {
                model: [
                    { component: "updates" },
                    cfg.feedsEnabled ? { component: "news" } : null
                ].filter(Boolean)

                delegate: Loader {
                    required property var modelData
                    sourceComponent: modelData.component === "updates" ? updatesComp : newsComp
                }
            }

            Component { id: updatesComp; View.Updates {} }
            Component { id: newsComp; View.News { id: newsPage } }
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
