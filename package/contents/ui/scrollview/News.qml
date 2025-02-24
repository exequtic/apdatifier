/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

import org.kde.plasma.components
import org.kde.kirigami as Kirigami

import "../../tools/tools.js" as JS

ScrollView {
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ListView {
        model: activeNewsModel
        spacing: Kirigami.Units.largeSpacing * 2
        topMargin: spacing
        rightMargin: spacing
        leftMargin: spacing
        bottomMargin: spacing

        add: Transition { NumberAnimation { properties: "x"; from: 100; duration: Kirigami.Units.longDuration } }
        removeDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: Kirigami.Units.longDuration } }
        remove: Transition { ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: Kirigami.Units.longDuration }
                NumberAnimation { properties: "x"; to: 100; duration: Kirigami.Units.longDuration }}}

        delegate: Kirigami.AbstractCard {
            contentItem: Item {
                implicitWidth: delegateLayout.implicitWidth
                implicitHeight: delegateLayout.implicitHeight
                GridLayout {
                    id: delegateLayout
                    anchors {
                        left: parent.left
                        top: parent.top
                        right: parent.right
                    }
                    rowSpacing: Kirigami.Units.largeSpacing
                    columnSpacing: Kirigami.Units.largeSpacing
                    columns: width > Kirigami.Units.gridUnit * 20 ? 4 : 2
                    Kirigami.Icon {
                        Layout.fillHeight: true
                        Layout.maximumHeight: Kirigami.Units.iconSizes.huge
                        Layout.preferredWidth: height
                        source: model.title.includes("Arch")        ? "apdatifier-plasmoid" :
                                model.title.includes("Plasma")      ? "note-symbolic" :
                                model.title.includes("Apps")        ? "applications-all-symbolic" :
                                model.title.includes("Community")   ? "start-here-kde-plasma-symbolic"
                                                                    : "news-subscribe"
                    }

                    RowLayout {
                        ColumnLayout {
                            Controls.Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: model.title
                                font.bold: true
                            }
                            Controls.Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: model.date
                                opacity: 0.6
                            }
                            Kirigami.Separator {
                                Layout.fillWidth: true
                            }
                            Controls.Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: model.article
                            }
                        }

                        ColumnLayout {
                            Controls.Button {
                                ToolTip { text: i18n("Read article") }
                                icon.name: "internet-web-browser-symbolic"
                                onClicked: Qt.openUrlExternally(model.link)
                            }
                            Controls.Button {
                                ToolTip { text: i18n("Remove") }
                                icon.name: "delete"
                                onClicked: JS.removeNewsItem(index)
                            }
                        }
                    }
                }
            }
        }

        Loader {
            width: parent.width
            active: sts.busy && (sts.statusIco === "status_news" || sts.statusIco === "news-subscribe")
            sourceComponent: ProgressBar {
                from: 0
                to: 100
                indeterminate: true
            }
        }

        Loader {
            anchors.centerIn: parent
            active: activeNewsModel.count === 0
            sourceComponent: Kirigami.PlaceholderMessage {
                icon.name: "news-subscribe"
                text: i18n("No unread news")
                helpfulAction: Kirigami.Action {
                    enabled: newsModel.count > 0
                    icon.name: "backup"
                    text: i18n("Restore list")
                    onTriggered: JS.restoreNewsList()
                }
            }
        }
    }
}
