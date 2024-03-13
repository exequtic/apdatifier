/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents

import "../tools/tools.js" as JS

Item {
    Kirigami.ScrollablePage {
        background: Kirigami.Theme.backgroundColor
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.bottom: separator.top

        ListView {
            id: list
            visible: !busy && !error && count > 0
            model: listModel

            delegate: ItemDelegate {
                id: delegate
                width: list.width
                height: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.5 + cfg.spacing)
                highlighted: false
                hoverEnabled: false
                enabled: false

                contentItem: RowLayout {
                    RowLayout {
                        Layout.preferredWidth: list.width / 2
                        Layout.maximumWidth: list.width / 2
                        Layout.fillHeight: true

                        Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            elide: Text.ElideRight
                            text: model.name
                        }
                    }

                    RowLayout {
                        Layout.preferredWidth: list.width / 2
                        Layout.maximumWidth: list.width / 2
                        Layout.fillHeight: true

                        Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            elide: Text.ElideRight
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            text: model.repo + " → " + model.curr + " → " + model.newv
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        anchors.bottom: parent.bottom
        id: footer
        width: parent.width
        enabled: cfg.showStatusBar
        visible: enabled

        RowLayout {
            spacing: 0
            visible: footer.visible

            PlasmaComponents.ToolButton {
                icon.name: statusIco
                hoverEnabled: false
                highlighted: false
                enabled: false
            }

            PlasmaExtras.DescriptiveLabel {
                text: statusMsg
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 0

            PlasmaComponents.ToolButton {
                onClicked: {
                    cfg.sortByName = !cfg.sortByName;
                }
                icon.name: "view-sort"
                visible: footer.visible
                            && !busy
                            && !error
                            && count > 0

                PlasmaComponents.ToolTip {
                    text: i18n("Sort by name/repository")
                }
            }

            PlasmaComponents.ToolButton {
                onClicked: JS.upgradeSystem()
                icon.name: "akonadiconsole"
                visible: footer.visible
                            && !busy
                            && !error
                            && count > 0
                            && cfg.terminal

                PlasmaComponents.ToolTip {
                    text: i18n("Upgrade system")
                }
            }

            PlasmaComponents.ToolButton {
                onClicked: JS.checkUpdates()
                icon.name: "view-refresh"
                visible: footer.visible && !upgrading

                PlasmaComponents.ToolTip {
                    text: i18n("Check updates")
                }
            }
        }
    }

    Rectangle {
        anchors.bottom: footer.top
        id: separator
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
        PlasmaComponents.BusyIndicator {
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
        enabled: !busy && !error && count === 0 && Object.keys(listModel).length === 0
        visible: enabled
        asynchronous: true
        sourceComponent: PlasmaExtras.PlaceholderMessage {
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
        sourceComponent: PlasmaExtras.PlaceholderMessage {
            width: parent.width
            iconName: "error"
            text: error
        }
    }
}
