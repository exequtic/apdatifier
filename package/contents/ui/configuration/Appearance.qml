/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls

import org.kde.ksvg
import org.kde.kcmutils
import org.kde.iconthemes
import org.kde.kquickcontrolsaddons
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

import "../../tools/tools.js" as JS

SimpleKCM {
    property alias cfg_relevantIcon: relevantIcon.value
    property string cfg_selectedIcon: plasmoid.configuration.selectedIcon
    property alias cfg_indicatorStop: indicatorStop.checked
    property alias cfg_counterEnabled: counterEnabled.checked
    property string cfg_counterColor: plasmoid.configuration.counterColor
    property alias cfg_counterSize: counterSize.value
    property alias cfg_counterRadius: counterRadius.value
    property alias cfg_counterOpacity: counterOpacity.value
    property alias cfg_counterShadow: counterShadow.checked
    property string cfg_counterFontFamily: plasmoid.configuration.counterFontFamily
    property alias cfg_counterFontBold: counterFontBold.checked
    property alias cfg_counterFontSize: counterFontSize.value
    property alias cfg_counterSpacing: counterSpacing.value
    property alias cfg_counterMargins: counterMargins.value
    property alias cfg_counterOffsetX: counterOffsetX.value
    property alias cfg_counterOffsetY: counterOffsetY.value
    property alias cfg_counterCenter: counterCenter.checked
    property bool cfg_counterTop: plasmoid.configuration.counterTop
    property bool cfg_counterBottom: plasmoid.configuration.counterBottom
    property bool cfg_counterRight: plasmoid.configuration.counterRight
    property bool cfg_counterLeft: plasmoid.configuration.counterLeft

    property alias cfg_ownIconsUI: ownIconsUI.checked
    property int cfg_listView: plasmoid.configuration.listView
    property alias cfg_spacing: spacing.value
    property alias cfg_sorting: sorting.checked
    property alias cfg_showStatusText: showStatusText.checked
    property alias cfg_showToolBar: showToolBar.checked
    property alias cfg_searchButton: searchButton.checked
    property alias cfg_intervalButton: intervalButton.checked
    property alias cfg_sortButton: sortButton.checked
    property alias cfg_managementButton: managementButton.checked
    property alias cfg_upgradeButton: upgradeButton.checked
    property alias cfg_checkButton: checkButton.checked
    property alias cfg_tabBarVisible: tabBarVisible.checked
    property alias cfg_tabBarTexts: tabBarTexts.checked

    property bool inTray: (plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentDrawsPlasmoidHeading)
    property bool horizontal: plasmoid.location === 3 || plasmoid.location === 4
    property bool counterOverlay: inTray || !horizontal
    property bool counterRow: !inTray && horizontal

    property int currentTab
    signal tabChanged(currentTab: int)
    onCurrentTabChanged: tabChanged(currentTab)
 
    header: Kirigami.NavigationTabBar {
        actions: [
            Kirigami.Action {
                icon.name: "view-list-icons"
                text: i18n("Panel Icon View")
                checked: currentTab === 0
                onTriggered: currentTab = 0
            },
            Kirigami.Action {
                icon.name: "view-split-left-right"
                text: i18n("List View")
                checked: currentTab === 1
                onTriggered: currentTab = 1
            }
        ]
    }

    Kirigami.FormLayout {
        id: iconViewTab
        visible: currentTab === 0

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Shown when")
            enabled: counterOverlay

            SpinBox {
                id: relevantIcon
                from: 0
                to: 999
                stepSize: 1
                value: relevantIcon.value
            }

            Label {
                text: i18np("update is pending ", "updates are pending ", relevantIcon.value)
            }
        }

        Button {
            id: iconButton

            implicitWidth: iconFrame.width + Kirigami.Units.smallSpacing
            implicitHeight: implicitWidth
            hoverEnabled: true

            FrameSvgItem {
                id: iconFrame
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.large + fixedMargins.left + fixedMargins.right
                height: width
                imagePath: "widgets/background"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.large
                    height: width
                    source: JS.setIcon(cfg_selectedIcon)
                }
            }

            IconDialog {
                id: iconDialog
                onIconNameChanged: cfg_selectedIcon = iconName || JS.defaultIcon
            }

            onClicked: menu.opened ? menu.close() : menu.open()

            Menu {
                id: menu
                y: +parent.height

                MenuItem {
                    text: i18n("Default") + " 1"
                    icon.name: "apdatifier-plasmoid"
                    enabled: cfg_selectedIcon !== JS.defaultIcon
                    onClicked: cfg_selectedIcon = JS.defaultIcon
                }
                MenuItem {
                    text: i18n("Default") + " 2"
                    icon.name: "apdatifier-packages"
                    enabled: cfg_selectedIcon !== icon.name
                    onClicked: cfg_selectedIcon = icon.name
                }
                MenuItem {
                    text: i18n("Default") + " 3"
                    icon.name: "apdatifier-package"
                    enabled: cfg_selectedIcon !== icon.name
                    onClicked: cfg_selectedIcon = icon.name
                }
                MenuItem {
                    text: i18n("Default") + " 4"
                    icon.name: "apdatifier-flatpak"
                    enabled: cfg_selectedIcon !== icon.name
                    onClicked: cfg_selectedIcon = icon.name
                }

                MenuItem {
                    text: i18n("Select...")
                    icon.name: "document-open-folder"
                    onClicked: iconDialog.open()
                }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            ToolTip {
                text: cfg_selectedIcon === JS.defaultIcon ? i18n("Default icon") : cfg_selectedIcon
                delay: Kirigami.Units.toolTipDelay
                visible: iconButton.hovered
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Stopped interval") + ":"
            id: indicatorStop
            text: i18n("Enable")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Counter") + ":"
            id: counterEnabled
            text: i18n("Enable")
        }

        Button {
            Kirigami.FormData.label: i18n("Color") + ":"
            id: counterColor

            Layout.leftMargin: Kirigami.Units.gridUnit

            implicitWidth: Kirigami.Units.gridUnit
            implicitHeight: implicitWidth
            visible: counterOverlay
            enabled: counterEnabled.checked

            background: Rectangle {
                radius: counterRadius.value
                border.width: 1
                border.color: "black"
                color: cfg_counterColor ? cfg_counterColor : Kirigami.Theme.backgroundColor
            }

            onPressed: menuColor.opened ? menuColor.close() : menuColor.open()

            Menu {
                id: menuColor
                y: +parent.height

                MenuItem {
                    text: i18n("Default color")
                    icon.name: "edit-clear"
                    enabled: cfg_counterColor && cfg_counterColor !== Kirigami.Theme.backgroundColor
                    onClicked: cfg_counterColor = ""
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
                title: i18n("Select counter background color")
                selectedColor: cfg_counterColor

                onAccepted: {
                    cfg_counterColor = selectedColor
                }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            ToolTip {
                text: cfg_counterColor ? cfg_counterColor : i18n("Default background color from current theme")
                delay: Kirigami.Units.toolTipDelay
                visible: counterColor.hovered
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Size") + ":"
            visible: counterOverlay
            enabled: counterEnabled.checked

            Slider {
                id: counterSize
                from: -5
                to: 10
                stepSize: 1
                value: counterSize.value
                onValueChanged: plasmoid.configuration.counterSize = counterSize.value
            }

            Label {
                text: counterSize.value
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Radius") + ":"
            visible: counterOverlay
            enabled: counterEnabled.checked

            Slider {
                id: counterRadius
                from: 0
                to: 100
                stepSize: 1
                value: counterRadius.value
                onValueChanged: plasmoid.configuration.counterRadius = counterRadius.value
            }

            Label {
                text: counterRadius.value
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Opacity") + ":"
            visible: counterOverlay
            enabled: counterEnabled.checked

            Slider {
                id: counterOpacity
                from: 0
                to: 10
                stepSize: 1
                value: counterOpacity.value
                onValueChanged: plasmoid.configuration.counterOpacity = counterOpacity.value
            }

            Label {
                text: counterOpacity.value / 10
            }
        }


        CheckBox {
            Kirigami.FormData.label: i18n("Shadow") + ":"
            visible: counterOverlay
            enabled: counterEnabled.checked
            id: counterShadow
            text: i18n("Enable")
        }

        ComboBox {
            Kirigami.FormData.label: i18n("Font") + ":"
            enabled: counterEnabled.checked
            implicitWidth: 250
            editable: true
            textRole: "name"
            model: {
                let fonts = Qt.fontFamilies()
                let arr = []
                arr.push({"name": i18n("Default system font"), "value": ""})
                for (let i = 0; i < fonts.length; i++) {
                    arr.push({"name": fonts[i], "value": fonts[i]})
                }
                return arr
            }

            onCurrentIndexChanged: cfg_counterFontFamily = model[currentIndex]["value"]
            Component.onCompleted: currentIndex = JS.setIndex(plasmoid.configuration.counterFontFamily, model)
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Font bold") + ":"
            enabled: counterEnabled.checked
            id: counterFontBold
            text: i18n("Enable")
        }

        Slider {
            Kirigami.FormData.label: i18n("Font size") + ":"
            visible: counterRow
            enabled: counterEnabled.checked
            id: counterFontSize
            from: 4
            to: 8
            stepSize: 1
            value: counterFontSize.value
            onValueChanged: plasmoid.configuration.counterFontSize = counterFontSize.value
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Left spacing") + ":"
            visible: counterRow
            enabled: counterEnabled.checked
            id: counterSpacing
            from: 0
            to: 99
            stepSize: 1
            value: counterSpacing.value
            onValueChanged: plasmoid.configuration.counterSpacing = counterSpacing.value
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Side margins") + ":"
            visible: counterRow
            id: counterMargins
            from: 0
            to: 99
            stepSize: 1
            value: counterMargins.value
            onValueChanged: plasmoid.configuration.counterMargins = counterMargins.value
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Offset") + ":"
            visible: counterOverlay
            enabled: counterEnabled.checked

            Label { text: "X:" }
            SpinBox {
                id: counterOffsetX
                from: -10
                to: 10
                stepSize: 1
                value: counterOffsetX.value
                onValueChanged: plasmoid.configuration.counterOffsetX = counterOffsetX.value
            }

            Label { text: "Y:" }
            SpinBox {
                id: counterOffsetY
                from: -10
                to: 10
                stepSize: 1
                value: counterOffsetY.value
                onValueChanged: plasmoid.configuration.counterOffsetY = counterOffsetY.value
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Position") + ":"
            visible: counterOverlay
            enabled: counterEnabled.checked
            id: counterCenter
            text: i18n("Center")
        }

        GridLayout {
            Layout.fillWidth: true
            visible: counterOverlay
            enabled: counterEnabled.checked
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
                checked: cfg_counterTop && cfg_counterLeft

                onCheckedChanged: {
                    if (checked) {
                        cfg_counterTop = true
                        cfg_counterBottom = false
                        cfg_counterRight = false
                        cfg_counterLeft = true
                    }
                }
            }

            RadioButton {
                id: topright
                ButtonGroup.group: position
                checked: cfg_counterTop && cfg_counterRight

                onCheckedChanged: {
                    if (checked) {
                        cfg_counterTop = true
                        cfg_counterBottom = false
                        cfg_counterRight = true
                        cfg_counterLeft = false
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
                checked: cfg_counterBottom && cfg_counterLeft

                onCheckedChanged: {
                    if (checked) {
                        cfg_counterTop = false
                        cfg_counterBottom = true
                        cfg_counterRight = false
                        cfg_counterLeft = true
                    }
                }
            }

            RadioButton {
                id: bottomright
                ButtonGroup.group: position
                checked: cfg_counterBottom && cfg_counterRight

                onCheckedChanged: {
                    if (checked) {
                        cfg_counterTop = false
                        cfg_counterBottom = true
                        cfg_counterRight = true
                        cfg_counterLeft = false
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

    Kirigami.FormLayout {
        id: listViewTab
        visible: currentTab === 1

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: "UI:"
            CheckBox {
                id: ownIconsUI
                text: i18n("Use built-in icons")
            }
            
            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Override custom icon theme and use default Apdatifier icons instead.")
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        ButtonGroup {
            id: viewGroup
        }

        RowLayout {
            Kirigami.FormData.label: i18n("View") + ":"

            RadioButton {
                id: compactView
                ButtonGroup.group: viewGroup
                text: i18n("Compact")
                Component.onCompleted: checked = !plasmoid.configuration.listView
            }

            RowLayout {
                Slider {
                    id: spacing
                    from: 0
                    to: 12
                    stepSize: 1
                    value: spacing.value
                    onValueChanged: plasmoid.configuration.spacing = spacing.value
                }

                Label {
                    text: spacing.value
                }
            }
        }

        RadioButton {
            ButtonGroup.group: viewGroup
            text: i18n("Extended")
            onCheckedChanged: cfg_listView = checked
            Component.onCompleted: checked = plasmoid.configuration.listView
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        ButtonGroup {
            id: sortGroup
        }

        RadioButton {
            id: sorting
            Kirigami.FormData.label: i18n("Sorting") + ":"
            text: i18n("By repository")
            checked: true
            Component.onCompleted: checked = plasmoid.configuration.sorting
            ButtonGroup.group: sortGroup
        }

        RadioButton {
            text: i18n("By name")
            Component.onCompleted: checked = !plasmoid.configuration.sorting
            ButtonGroup.group: sortGroup
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            id: showStatusText
            Kirigami.FormData.label: i18n("Header") + ":"
            text: i18n("Show status")
        }

        CheckBox {
            id: showToolBar
            text: i18n("Show tool bar")
        }

        RowLayout {
            enabled: showToolBar.checked
            CheckBox {
                id: searchButton
                icon.name: "search"
            }
            CheckBox {
                id: intervalButton
                icon.name: "media-playback-paused"
            }
            CheckBox {
                id: sortButton
                icon.name: "sort-name"
            }
        }
        RowLayout {
            enabled: showToolBar.checked
            CheckBox {
                id: managementButton
                icon.name: "tools"
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

        RowLayout {
            Kirigami.FormData.label: i18n("Footer") + ":"

            CheckBox {
                id: tabBarVisible
                text: i18n("Show tab bar")
            }
        }

        CheckBox {
            id: tabBarTexts
            text: i18n("Show tab texts")
            enabled: tabBarVisible.checked
        }

        Item {
            Kirigami.FormData.isSection: true
        }
    }
}
