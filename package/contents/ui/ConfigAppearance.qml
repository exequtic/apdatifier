/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls

import org.kde.kcmutils
import org.kde.ksvg
import org.kde.iconthemes
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

import "../tools/tools.js" as JS

SimpleKCM {
    property alias cfg_fullView: extView.checked
    property alias cfg_spacing: spacing.value

    property alias cfg_showStatusBar: showStatusBar.checked
    property alias cfg_searchButton: searchButton.checked
    property alias cfg_viewButton: viewButton.checked
    property alias cfg_sortButton: sortButton.checked
    property alias cfg_upgradeButton: upgradeButton.checked
    property alias cfg_checkButton: checkButton.checked

    property alias cfg_sortByName: sortByName.checked

    property alias cfg_relevantIcon: relevantIcon.checked
    property string cfg_selectedIcon: plasmoid.configuration.selectedIcon

    property alias cfg_indicatorCounter: indicatorCounter.checked
    property alias cfg_indicatorScale: indicatorScale.checked
    property alias cfg_indicatorCircle: indicatorCircle.checked
    property string cfg_indicatorColor: plasmoid.configuration.indicatorColor
    property alias cfg_indicatorUpdates: indicatorUpdates.checked
    property alias cfg_indicatorStop: indicatorStop.checked

    property bool cfg_indicatorTop: plasmoid.configuration.indicatorTop
    property bool cfg_indicatorBottom: plasmoid.configuration.indicatorBottom
    property bool cfg_indicatorRight: plasmoid.configuration.indicatorRight
    property bool cfg_indicatorLeft: plasmoid.configuration.indicatorLeft

    Kirigami.FormLayout {
        id: appearancePage

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("List View")
        }

        ButtonGroup {
            id: viewGroup
        }

        RadioButton {
            Kirigami.FormData.label: i18n("View:")

            ButtonGroup.group: viewGroup
            id: extView
            text: "Extended"

            onCheckedChanged: cfg_fullView = checked

            Component.onCompleted: {
                checked = plasmoid.configuration.fullView
            }

        }

        RadioButton {
            id: compactView
            ButtonGroup.group: viewGroup
            text: "Compact"

            Component.onCompleted: {
                checked = !plasmoid.configuration.fullView
            }
        }


        RowLayout {
            Kirigami.FormData.label: i18n("Spacing:")
            enabled: compactView.checked

            Slider {
                id: spacing
                from: 0
                to: 12
                stepSize: 1
                value: spacing.value

                onValueChanged: {
                    plasmoid.configuration.spacing = spacing.value
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            id: showStatusBar
            Kirigami.FormData.label: i18n("Status bar:")
            text: i18n("Show status bar")
        }

        RowLayout {
            enabled: showStatusBar.checked
            CheckBox {
                id: searchButton
                icon.name: "search"
            }
            CheckBox {
                id: viewButton
                icon.name: "view-split-top-bottom"
            }
            CheckBox {
                id: sortButton
                icon.name: "sort-name"
            }
            CheckBox {
                id: upgradeButton
                icon.name: "akonadiconsole"
            }
            CheckBox {
                id: checkButton
                icon.name: "view-refresh"
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        ButtonGroup {
            id: sortGroup
        }

        RadioButton {
            id: sortByName
            Kirigami.FormData.label: i18n("Sorting:")
            text: i18n("By name")
            checked: true

            Component.onCompleted: {
                checked = plasmoid.configuration.sortByName
            }

            ButtonGroup.group: sortGroup
        }

        RadioButton {
            id: sortByRepo
            text: i18n("By repository")

            Component.onCompleted: {
                checked = !plasmoid.configuration.sortByName
            }

            ButtonGroup.group: sortGroup
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Panel Icon View")
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Icon:")
            id: relevantIcon
            text: "Shown when relevant"
        }

        Button {
            id: iconButton

            implicitWidth: iconFrame.width + Kirigami.Units.smallSpacing
            implicitHeight: implicitWidth
            hoverEnabled: true

            ToolTip.text: cfg_selectedIcon === JS.defaultIcon ? i18n("Default icon") : cfg_selectedIcon
            ToolTip.delay: Kirigami.Units.toolTipDelay
            ToolTip.visible: iconButton.hovered

            FrameSvgItem {
                id: iconFrame
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.medium + fixedMargins.left + fixedMargins.right
                height: width
                imagePath: "widgets/background"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.medium
                    height: width
                    source: JS.setIcon(cfg_selectedIcon)
                }
            }

            IconDialog {
                id: iconsDialog
                onIconNameChanged: cfg_selectedIcon = iconName || JS.defaultIcon
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            onPressed: menu.opened ? menu.close() : menu.open()

            Menu {
                id: menu
                y: +parent.height

                MenuItem {
                    text: i18n("Default 1")
                    icon.name: "apdatifier-plasmoid"
                    enabled: cfg_selectedIcon !== JS.defaultIcon
                    onClicked: cfg_selectedIcon = JS.defaultIcon
                }

                MenuItem {
                    text: i18n("Default 2")
                    icon.name: "apdatifier-packages"
                    enabled: cfg_selectedIcon !== icon.name
                    onClicked: cfg_selectedIcon = icon.name
                }

                MenuItem {
                    text: i18n("Select...")
                    icon.name: "document-open-folder"
                    onClicked: iconsDialog.open()
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Indicators:")
            id: indicatorStop
            text: i18n("Stopped interval")
        }

        CheckBox {
            id: indicatorUpdates
            text: i18n("Status of updates")
        }

        ColumnLayout {
            enabled: indicatorUpdates.checked

            ButtonGroup {
                id: indicator
            }

            RowLayout {
                RadioButton {
                    id: indicatorCounter
                    text: i18n("Counter")
                    checked: true
                    ButtonGroup.group: indicator
                }

                CheckBox {
                    id: indicatorScale
                    Layout.leftMargin: Kirigami.Units.gridUnit
                    text: i18n("Scale with icon")
                    visible: indicatorCounter.checked
                }
            }

            RowLayout {
                RadioButton {
                    id: indicatorCircle
                    text: i18n("Circle")
                    ButtonGroup.group: indicator
                }

                Button {
                    id: colorButton

                    Layout.leftMargin: (indicatorCounter.width - indicatorCircle.width) + Kirigami.Units.gridUnit * 1.1

                    implicitWidth: Kirigami.Units.gridUnit
                    implicitHeight: implicitWidth
                    visible: indicatorCircle.checked

                    ToolTip.text: cfg_indicatorColor ? cfg_indicatorColor : i18n("Default accent color from current color scheme")
                    ToolTip.delay: Kirigami.Units.toolTipDelay
                    ToolTip.visible: colorButton.hovered

                    background: Rectangle {
                        radius: colorButton.implicitWidth / 2
                        color: cfg_indicatorColor ? cfg_indicatorColor : Kirigami.Theme.highlightColor
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    onPressed: menuColor.opened ? menuColor.close() : menuColor.open()

                    Menu {
                        id: menuColor
                        y: +parent.height

                        MenuItem {
                            text: i18n("Default color")
                            icon.name: "edit-clear"
                            enabled: cfg_indicatorColor && cfg_indicatorColor !== Kirigami.Theme.highlightColor
                            onClicked: cfg_indicatorColor = ""
                        }

                        MenuItem {
                            text: i18n("Select...")
                            icon.name: "document-open-folder"
                            onClicked: colorDialog.open()
                        }
                    }

                    ColorDialog {
                        id: colorDialog
                        visible: false
                        title: i18n("Select circle color")
                        selectedColor: cfg_indicatorColor

                        onAccepted: {
                            cfg_indicatorColor = selectedColor
                        }
                    }
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        GridLayout {
            Layout.fillWidth: true
            enabled: indicatorUpdates.checked
            columns: 4
            rowSpacing: 0
            columnSpacing: 0

            ButtonGroup {
                id: position
            }

            Label {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: Kirigami.Units.smallSpacing * 2.5
                text: i18n("Top-Left")

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        topleft.checked = true
                    }
                }
            }

            RadioButton {
                id: topleft
                ButtonGroup.group: position
                checked: cfg_indicatorTop && cfg_indicatorLeft

                onCheckedChanged: {
                    if (checked) {
                        cfg_indicatorTop = true
                        cfg_indicatorBottom = false
                        cfg_indicatorRight = false
                        cfg_indicatorLeft = true
                    }
                }
            }

            RadioButton {
                id: topright
                ButtonGroup.group: position
                checked: cfg_indicatorTop && cfg_indicatorRight

                onCheckedChanged: {
                    if (checked) {
                        cfg_indicatorTop = true
                        cfg_indicatorBottom = false
                        cfg_indicatorRight = true
                        cfg_indicatorLeft = false
                    }
                }
            }

            Label {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignLeft
                text: i18n("Top-Right")

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        topright.checked = true
                    }
                }
            }

            Label {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: Kirigami.Units.smallSpacing * 2.5
                text: i18n("Bottom-Left")

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        bottomleft.checked = true
                    }
                }
            }

            RadioButton {
                id: bottomleft
                ButtonGroup.group: position
                checked: cfg_indicatorBottom && cfg_indicatorLeft

                onCheckedChanged: {
                    if (checked) {
                        cfg_indicatorTop = false
                        cfg_indicatorBottom = true
                        cfg_indicatorRight = false
                        cfg_indicatorLeft = true
                    }
                }
            }

            RadioButton {
                id: bottomright
                ButtonGroup.group: position
                checked: cfg_indicatorBottom && cfg_indicatorRight

                onCheckedChanged: {
                    if (checked) {
                        cfg_indicatorTop = false
                        cfg_indicatorBottom = true
                        cfg_indicatorRight = true
                        cfg_indicatorLeft = false
                    }
                }
            }

            Label {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignLeft
                text: i18n("Bottom-Right")

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        bottomright.checked = true
                    }
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }
    }
}