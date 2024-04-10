/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls

import org.kde.ksvg
import org.kde.kitemmodels
import org.kde.plasma.extras
import org.kde.plasma.components
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

import "../tools/tools.js" as JS

Item {
    property bool searchFieldOpen: false
    property var pkgIcons: cfg.customIcons

    property bool visibility: !busy && Object.keys(news).length !== 0 && !news.dismissed
    function updateVisibility() {
        visibility = !news.dismissed
    }

    Kirigami.InlineMessage {
        id: newsAlert
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.left: parent.left
        visible: visibility

        icon.source: "news-subscribe"
        text: news ? `<b>Check out the latest news! (${news.date})</b><br><b>Article:</b> ${news.article}` : ""
        onLinkActivated: Qt.openUrlExternally(link)
        type: Kirigami.MessageType.Positive

        actions: [
            Kirigami.Action {
                text: "Read full article"
                icon.name: "internet-web-browser"
                onTriggered: {
                    Qt.openUrlExternally(news.link)
                }
            },
            Kirigami.Action {
                text: "Dismiss"
                icon.name: "dialog-close"
                onTriggered: {
                    news.dismissed = true
                    sh.exec(`echo '${JSON.stringify(news)}' > "${JS.newsFile}"`)
                    updateVisibility()
                }
            }
        ]
    }
    

    ScrollView {
        anchors.top: newsAlert.bottom
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.bottom: separator.top
        visible: !cfg.fullView && !busy && !error && count > 0
        enabled: !cfg.fullView

        ListView {
            id: list
            model: !cfg.fullView ? modelList : []
            delegate: GridLayout {
                property var heightItem: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.5)
                height: heightItem + cfg.spacing
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    height: heightItem
                    width: height
                    color: "transparent"
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        height: heightItem
                        width: height
                        source: !hoverIcon.containsMouse ? JS.setPackageIcon(pkgIcons, model.NM, model.RE, model.GR, model.ID) : "folder-download-symbolic"
                    }
                    MouseArea {
                        id: hoverIcon
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { JS.upgradePackage(model.NM, model.ID, model.CN) }
                    }
                }
                Label {
                    Layout.minimumWidth: list.width / 2
                    Layout.maximumWidth: list.width / 2
                    text: model.NM
                    elide: Text.ElideRight
                }
                Label {
                    Layout.minimumWidth: list.width / 2
                    Layout.maximumWidth: list.width / 2
                    text: model.RE + " → " + model.VN
                    elide: Text.ElideRight
                }
            }
        }
    }

    ScrollView {
        anchors.top: newsAlert.bottom
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.bottom: separator.top
        visible: cfg.fullView && !busy && !error && count > 0
        enabled: cfg.fullView

        contentItem: ListView {
            model: cfg.fullView ? modelList : []
            boundsBehavior: Flickable.StopAtBounds
            highlight: Highlight {}
            highlightMoveDuration: 0
            highlightResizeDuration: 0
            height: parent.height
            visible: !busy && !error && count > 0

            delegate: ExpandableListItem {
                property var pkg: []
                title: model.NM
                subtitle: model.RE + "  " + model.VO + " → " + model.VN
                icon: JS.setPackageIcon(pkgIcons, model.NM, model.RE, model.GR, model.ID)

                contextualActions: [
                    Action {
                        id: updateButton
                        icon.name: "folder-download-symbolic"
                        text: "Upgrade"
                        enabled: cfg.terminal
                        onTriggered: JS.upgradePackage(model.NM, model.ID, model.CN)
                    }
                ]

                customExpandedViewContent: Component {
                    ColumnLayout {
                        spacing: 0

                        SvgItem {
                            Layout.fillWidth: true
                            imagePath: "widgets/line"
                            elementId: "horizontal-line"
                            visible: !updateButton.enabled
                        }

                        Item {
                            Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
                        }

                        MouseArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: details.implicitHeight
                            acceptedButtons: Qt.RightButton
                            activeFocusOnTab: repeater.count > 0

                            GridLayout {
                                id: details
                                width: parent.width
                                columns: 2
                                rowSpacing: Kirigami.Units.smallSpacing / 4
                                columnSpacing: 30

                                Repeater {
                                    id: repeater
                                    model: pkg.length

                                    Label {
                                        property bool header: !(index % 2)
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignTop
                                        horizontalAlignment: Text.AlignLeft
                                        font: Kirigami.Theme.smallFont
                                        opacity: header ? 0.6 : 1
                                        text: header ? "<b>" + pkg[index] + ":</b>"
                                                     : pkg[index].indexOf("://") !== -1
                                                     ? "<a href=\"" + pkg[index] + "\">" + pkg[index] + "</a>"
                                                     : pkg[index]
                                        textFormat: header ? Text.StyledText
                                                           : pkg[index].indexOf("://") !== -1
                                                           ? Text.StyledText
                                                           : Text.PlainText
                                        wrapMode: header ? Text.NoWrap : Text.WordWrap
                                        onLinkActivated: Qt.openUrlExternally(link)
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
                        }

                        Component.onCompleted: {
                            const details = []
                            model.DE && details.push("Description", model.DE)
                            model.AU && details.push("Author", model.AU)
                            model.ID && details.push("App ID", model.ID)
                            model.BR && details.push("Branch", model.BR)
                            model.CM && details.push("Commit", model.CM)
                            model.RT && details.push("Runtime", model.RT)
                            model.LN && details.push("URL", model.LN)
                            model.GR && details.push("Groups", model.GR)
                            model.PR && details.push("Provides", model.PR)
                            model.DP && details.push("Depends on", model.DP)
                            model.RQ && details.push("Required by", model.RQ)
                            model.CF && details.push("Conflicts with", model.CF)
                            model.RP && details.push("Replaces", model.RP)
                            model.IS && details.push("Installed size", model.IS)
                            model.DS && details.push("Download size", model.DS)
                            model.DT && details.push("Install date", model.DT)
                            model.RN && details.push("Install reason", model.RN)
                            pkg = details
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        enabled: cfg.showStatusBar
        visible: enabled

        RowLayout {
            id: status
            spacing: 0
            visible: footer.visible

            ToolButton {
                icon.name: statusIco
                hoverEnabled: false
                highlighted: false
                enabled: false
            }

            DescriptiveLabel {
                text: statusMsg
            }
        }

        SearchField {
            id: searchField
            Layout.fillWidth: true
            focus: true
            visible: searchFieldOpen && footer.visible && !busy && !error && count > 0

            onTextChanged: {
                if (searchFieldOpen) modelList.setFilterFixedString(text)
                if (!searchFieldOpen) return
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 0

            ToolButton {
                id: searchButton
                icon.name: "search"
                visible: footer.visible && !busy && !error && count > 0 && cfg.searchButton
                enabled: visible
                ToolTip { text: i18n("Search") }
                onClicked: {
                    if (searchFieldOpen) searchField.text = ""
                    searchFieldOpen = !searchField.visible
                    status.visible = !status.visible
                    searchField.focus = searchFieldOpen
                }
            }

            ToolButton {
                icon.name: cfg.fullView ? "view-split-left-right" : "view-split-top-bottom"
                visible: footer.visible && !busy && !error && count > 0 && cfg.viewButton
                onClicked: cfg.fullView = !cfg.fullView
                ToolTip { text: i18n("Compact/Extended view") }
            }

            ToolButton {
                icon.name: cfg.sortByName ? "server-database" : "sort-name"
                visible: footer.visible && !busy && !error && count > 0 && cfg.sortButton
                onClicked: cfg.sortByName = !cfg.sortByName
                ToolTip { text: i18n("Sort by name/repository") }
            }

            ToolButton {
                icon.name: "akonadiconsole"
                visible: footer.visible && !busy && !error && count > 0 && cfg.terminal && cfg.upgradeButton
                onClicked: JS.upgradeSystem()
                ToolTip { text: i18n("Upgrade system") }
            }

            ToolButton {
                icon.name: "view-refresh"
                visible: footer.visible && !upgrading && cfg.checkButton
                onClicked: JS.checkUpdates()
                ToolTip { text: i18n("Check updates") }
            }
        }
    }

    Rectangle {
        id: separator
        anchors.bottom: footer.top
        width: footer.width
        height: 1
        color: Kirigami.Theme.textColor
        opacity: 0.3
        visible: footer.visible
    }

    Loader {
        anchors.centerIn: parent
        enabled: busy && plasmoid.location !== PlasmaCore.Types.Floating
        visible: enabled
        asynchronous: true
        BusyIndicator {
            anchors.centerIn: parent
            width: 128
            height: 128
            opacity: 0.6
            running: true
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
}
