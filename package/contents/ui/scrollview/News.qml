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

    Kirigami.CardsListView {
        model: activeNewsModel
        removeDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 300 } }
        remove: Transition { ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 300 }
                NumberAnimation { properties: "x"; to: 100; duration: 300 }}}

        delegate: Kirigami.AbstractCard {
            visible: !sts.err && !sts.busy
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
                        source: "news-subscribe"
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
                                ToolTip { text: i18n("Dismiss") }
                                icon.name: "dialog-close"
                                onClicked: JS.removeNewsItem(index)
                            }
                        }
                    }
                }
            }
        }
    }
}
