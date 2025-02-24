/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.ksvg
import org.kde.plasma.extras
import org.kde.plasma.components
import org.kde.kirigami as Kirigami

import "../../tools/tools.js" as JS
import "../components"

ScrollView {
    ScrollBar.vertical.policy: (sts.count === 0 || sts.busy || sts.err) ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded
    contentItem: ListView {
        model: modelList
        boundsBehavior: Flickable.StopAtBounds
        highlight: Highlight { visible: sts.idle }
        highlightMoveDuration: Kirigami.Units.shortDuration
        highlightResizeDuration: Kirigami.Units.shortDuration
        height: parent.height

        delegate: ExpandableListItem {
            visible: sts.pending
            property var pkg: []
            title: model.NM
            subtitle: model.RE + "  " + model.VO + " → " + model.VN
            icon: model.IC

            contextualActions: [
                Action {
                    id: updateButton
                    icon.name: "edit-download"
                    text: i18n("Upgrade package")
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
                            columnSpacing: 40

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
                                    text: header ? "<b>" + pkg[index] + ":</b>" : pkg[index].indexOf("://") !== -1 ? "<a href=\"" + pkg[index] + "\">" + pkg[index] + "</a>" : pkg[index]
                                    textFormat: header ? Text.StyledText : pkg[index].indexOf("://") !== -1 ? Text.StyledText : Text.PlainText
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
                        model.TP && details.push(i18n("Package type"), model.TP)
                        model.DE && details.push(i18n("Description"), model.DE)
                        model.AU && details.push(i18n("Author"), model.AU)
                        model.LN && details.push("URL", model.LN)
                        model.ID && details.push(i18n("App ID"), model.ID)
                        model.BR && details.push(i18n("Branch"), model.BR)
                        model.CM && details.push(i18n("Commit"), model.CM)
                        model.RT && details.push(i18n("Runtime"), model.RT)
                        model.GR && details.push(i18n("Groups"), model.GR)
                        model.PR && details.push(i18n("Provides"), model.PR)
                        model.DP && details.push(i18n("Depends on"), model.DP)
                        model.RQ && details.push(i18n("Required by"), model.RQ)
                        model.CF && details.push(i18n("Conflicts with"), model.CF)
                        model.RP && details.push(i18n("Replaces"), model.RP)
                        model.IS && details.push(i18n("Installed size"), model.IS)
                        model.DS && details.push(i18n("Download size"), model.DS)
                        model.DT && details.push(i18n("Install date"), model.DT)
                        model.RN && details.push(i18n("Install reason"), model.RN)
                        pkg = details
                    }
                }
            }
        }

        Placeholder {
            anchors.fill: parent
        }
    }
}
