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
    property alias cfg_counterOnLeft: counterOnLeft.checked
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
    property alias cfg_badgeOffsetX: badgeOffsetX.value
    property alias cfg_badgeOffsetY: badgeOffsetY.value
    property string cfg_counterPosition: plasmoid.configuration.counterPosition
    property string cfg_pauseBadgePosition: plasmoid.configuration.pauseBadgePosition
    property string cfg_updatedBadgePosition: plasmoid.configuration.updatedBadgePosition

    property alias cfg_ownIconsUI: ownIconsUI.checked
    property int cfg_defaultTab: plasmoid.configuration.defaultTab
    property alias cfg_switchDefaultTab: switchDefaultTab.checked
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
    property alias cfg_pinButton: pinButton.checked
    property alias cfg_settingsButton: settingsButton.checked
    property alias cfg_tabBarVisible: tabBarVisible.checked
    property alias cfg_tabBarTexts: tabBarTexts.checked

    property bool inTray: (plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentDrawsPlasmoidHeading)
    property bool onDesktop: plasmoid.location === PlasmaCore.Types.Floating
    property bool horizontal: plasmoid.location === 3 || plasmoid.location === 4
    property bool counterOverlay: inTray || !horizontal
    property bool counterRow: !inTray && horizontal
    property bool counterEnabled: plasmoid.configuration.counterPosition !== "disabled"

    readonly property var positionModel: [
        { name: i18n("Disabled"),     value: "disabled" },
        { name: i18n("Top-Left"),     value: "topLeft" },
        { name: i18n("Top-Right"),    value: "topRight" },
        { name: i18n("Bottom-Left"),  value: "bottomLeft" },
        { name: i18n("Bottom-Right"), value: "bottomRight" }
    ]

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

        RowLayout {
            height: 30
            Label {
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.bold: true
                color: Kirigami.Theme.neutralTextColor
                text: i18n("Settings take effect immediately after changes")
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Pause badge") + ":"
            ComboBox {
                id: pauseBadgePosition
                textRole: "name"
                model: positionModel
                currentIndex: JS.setIndex(plasmoid.configuration.pauseBadgePosition, model)
                onCurrentIndexChanged: cfg_pauseBadgePosition = plasmoid.configuration.pauseBadgePosition = model[currentIndex].value
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Updated badge") + ":"
            ComboBox {
                id: updatedBadgePosition
                textRole: "name"
                model: positionModel
                currentIndex: JS.setIndex(plasmoid.configuration.updatedBadgePosition, model)
                onCurrentIndexChanged: cfg_updatedBadgePosition = plasmoid.configuration.updatedBadgePosition = model[currentIndex].value
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Badges offset") + ":"
            Label { text: "X:" }
            SpinBox {
                id: badgeOffsetX
                from: -5
                to: 5
                stepSize: 1
                value: badgeOffsetX.value
                onValueChanged: plasmoid.configuration.badgeOffsetX = badgeOffsetX.value
                Layout.preferredWidth: 50
            }

            Label { text: "Y:" }
            SpinBox {
                id: badgeOffsetY
                from: -5
                to: 5
                stepSize: 1
                value: badgeOffsetY.value
                onValueChanged: plasmoid.configuration.badgeOffsetY = badgeOffsetY.value
                Layout.preferredWidth: 50
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Counter") + ":"
            ComboBox {
                id: counterPosition
                textRole: "name"
                model: positionModel.concat([{ name: i18n("Center"), value: "center" }])
                currentIndex: JS.setIndex(plasmoid.configuration.counterPosition, model)
                onCurrentIndexChanged: cfg_counterPosition = plasmoid.configuration.counterPosition = model[currentIndex].value
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Counter offset") + ":"
            Label { text: "X:" }
            SpinBox {
                id: counterOffsetX
                from: -5
                to: 5
                stepSize: 1
                value: counterOffsetX.value
                onValueChanged: plasmoid.configuration.counterOffsetX = counterOffsetX.value
                Layout.preferredWidth: 50
            }

            Label { text: "Y:" }
            SpinBox {
                id: counterOffsetY
                from: -5
                to: 5
                stepSize: 1
                value: counterOffsetY.value
                onValueChanged: plasmoid.configuration.counterOffsetY = counterOffsetY.value
                Layout.preferredWidth: 50
            }
        }


        CheckBox {
            Kirigami.FormData.label: "On left" + ":"
            id: counterOnLeft
            text: i18n("Enable")
            visible: counterRow
            enabled: counterEnabled
            onCheckedChanged: plasmoid.configuration.counterOnLeft = counterOnLeft.checked
        }

        Button {
            Kirigami.FormData.label: i18n("Background color") + ":"
            id: counterColor

            Layout.leftMargin: Kirigami.Units.gridUnit

            implicitWidth: Kirigami.Units.gridUnit
            implicitHeight: implicitWidth
            visible: counterOverlay
            enabled: counterEnabled

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
            Kirigami.FormData.label: i18n("Background radius") + ":"
            visible: counterOverlay
            enabled: counterEnabled

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
            Kirigami.FormData.label: i18n("Background opacity") + ":"
            visible: counterOverlay
            enabled: counterEnabled

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
            Kirigami.FormData.label: i18n("Background shadow") + ":"
            visible: counterOverlay
            enabled: counterEnabled
            id: counterShadow
            text: i18n("Enable")
        }

        ComboBox {
            Kirigami.FormData.label: i18n("Font") + ":"
            enabled: counterEnabled
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

            onCurrentIndexChanged: cfg_counterFontFamily = plasmoid.configuration.counterFontFamily = model[currentIndex]["value"]
            Component.onCompleted: currentIndex = JS.setIndex(plasmoid.configuration.counterFontFamily, model)
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Font Size") + ":"
            visible: counterOverlay
            enabled: counterEnabled

            Slider {
                id: counterSize
                from: -5
                to: 10
                stepSize: 1
                value: counterSize.value
                onValueChanged: plasmoid.configuration.counterSize = counterSize.value
            }
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Font bold") + ":"
            enabled: counterEnabled
            id: counterFontBold
            text: i18n("Enable")
            onCheckedChanged: plasmoid.configuration.counterFontBold = counterFontBold.checked
        }

        Slider {
            Kirigami.FormData.label: i18n("Font size") + ":"
            visible: counterRow
            enabled: counterEnabled
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
            enabled: counterEnabled
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

        RadioButton {
            Kirigami.FormData.label: i18n("Default tab") + ":"
            id: compactView
            ButtonGroup.group: viewGroup
            text: i18n("Compact")
            Component.onCompleted: checked = !plasmoid.configuration.defaultTab
        }

        RadioButton {
            ButtonGroup.group: viewGroup
            text: i18n("Extended")
            onCheckedChanged: cfg_defaultTab = checked
            Component.onCompleted: checked = plasmoid.configuration.defaultTab
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Behavior") + ":"
            id: switchDefaultTab
            text: i18n("Always switch to default tab")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Item spacing (Compact)") + ":"
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
            CheckBox {
                id: managementButton
                icon.name: "tools"
            }
        }
        RowLayout {
            enabled: showToolBar.checked
            CheckBox {
                id: upgradeButton
                icon.name: "akonadiconsole"
            }
            CheckBox {
                id: checkButton
                icon.name: "view-refresh"
            }
            CheckBox {
                id: settingsButton
                icon.name: "settings-configure"
                enabled: !inTray
            }
            CheckBox {
                id: pinButton
                icon.name: "pin"
                enabled: !inTray && !onDesktop
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
