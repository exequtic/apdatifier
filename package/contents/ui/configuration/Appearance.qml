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
    property alias cfg_hideIconPolicy: hideIconPolicy.value
    property string cfg_selectedIcon: plasmoid.configuration.selectedIcon

    property string cfg_pauseBadgePosition: plasmoid.configuration.pauseBadgePosition
    property string cfg_updatedBadgePosition: plasmoid.configuration.updatedBadgePosition
    property alias cfg_badgeOffsetX: badgeOffsetX.value
    property alias cfg_badgeOffsetY: badgeOffsetY.value

    property string cfg_counterMode: plasmoid.configuration.counterMode
    property string cfg_counterSidePosition: plasmoid.configuration.counterSidePosition
    property string cfg_counterBadgePosition: plasmoid.configuration.counterBadgePosition
    property alias cfg_counterOffsetX: counterOffsetX.value
    property alias cfg_counterOffsetY: counterOffsetY.value
    property string cfg_counterColor: plasmoid.configuration.counterColor
    property alias cfg_counterRadius: counterRadius.value
    property alias cfg_counterOpacity: counterOpacity.value
    property string cfg_counterFontFamily: plasmoid.configuration.counterFontFamily
    property alias cfg_counterFontBold: counterFontBold.checked
    property alias cfg_counterFontSize: counterFontSize.value
    property alias cfg_counterGapsInner: counterGapsInner.value
    property alias cfg_counterGapsOuter: counterGapsOuter.value

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

    readonly property bool inTray: (plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentDrawsPlasmoidHeading)
    readonly property bool onDesktop: plasmoid.location === PlasmaCore.Types.Floating
    readonly property bool horizontal: plasmoid.location === PlasmaCore.Types.TopEdge || plasmoid.location === PlasmaCore.Types.BottomEdge

    readonly property bool allowOnlyCounterBadge: inTray || !horizontal

    readonly property bool counterEnabled: cfg_counterMode !== "disabled"
    readonly property bool sideMode: cfg_counterMode === "side"
    readonly property bool badgeMode: cfg_counterMode === "badge"

    readonly property var positions: [
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
                text: i18n("Panel Icon")
                checked: currentTab === 0
                onTriggered: currentTab = 0
            },
            Kirigami.Action {
                icon.name: "view-split-left-right"
                text: i18n("Full View")
                checked: currentTab === 1
                onTriggered: currentTab = 1
            }
        ]
    }

    Kirigami.FormLayout {
        id: iconViewTab
        visible: currentTab === 0

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Icon")
            Kirigami.FormData.isSection: true
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

        RowLayout {
            Kirigami.FormData.label: i18n("Hide") + ":"

            Label {
                text: i18n("when less than")
            }

            SpinBox {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                id: hideIconPolicy
                from: 0
                to: 999
                stepSize: 1
            }

            Label {
                text: i18np("update", "updates", hideIconPolicy.value)
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("If the widget is on a panel, you can access the hidden icon in Panel Configuration mode.")
            }
        }
// --------------------------------------------- COUNTER SECTION ------------------------------------------------
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Counter")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Mode") + ":"

            RowLayout {
                id: counterMode
                spacing: Kirigami.Units.largeSpacing

                ButtonGroup {
                    id: counterModeGroup
                    onCheckedButtonChanged: {
                        if (checkedButton) {
                            cfg_counterMode = checkedButton.modeValue
                        }
                    }
                }
                RadioButton {
                    text: i18n("Off")
                    property string modeValue: "disabled"
                    ButtonGroup.group: counterModeGroup
                }
                RadioButton {
                    text: i18n("Side")
                    property string modeValue: "side"
                    ButtonGroup.group: counterModeGroup
                    enabled: !allowOnlyCounterBadge
                }
                RadioButton {
                    text: i18n("Badge")
                    property string modeValue: "badge"
                    ButtonGroup.group: counterModeGroup
                }
                Component.onCompleted: {
                    if (allowOnlyCounterBadge && plasmoid.configuration.counterMode === "side") {
                        plasmoid.configuration.counterMode = "badge"
                    }

                    for (let i = 0; i < counterModeGroup.buttons.length; ++i) {
                        const b = counterModeGroup.buttons[i]
                        if (b.modeValue === plasmoid.configuration.counterMode) {
                            b.checked = true
                            break
                        }
                    }
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Position") + ":"
            ComboBox {
                id: counterBadgePosition
                enabled: badgeMode
                textRole: "name"
                model: positions.slice(1).concat([{ name: i18n("Center"), value: "center" }])
                onCurrentIndexChanged: cfg_counterBadgePosition = model[currentIndex].value
                Component.onCompleted: currentIndex = JS.setIndex(plasmoid.configuration.counterBadgePosition, model)
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Side") + ":"
            enabled: sideMode
            spacing: Kirigami.Units.largeSpacing
            RadioButton {
                text: i18n("Left")
                checked: cfg_counterSidePosition === "left"
                onCheckedChanged: {
                    if (checked) cfg_counterSidePosition = "left"
                }
            }
            RadioButton {
                text: i18n("Right")
                checked: cfg_counterSidePosition === "right"
                onCheckedChanged: {
                    if (checked) cfg_counterSidePosition = "right"
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Gaps") + ":"
            enabled: sideMode
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Label { text: i18n("Inner") + ":" }
                SpinBox {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    enabled: sideMode
                    id: counterGapsInner
                    from: 0
                    to: 99
                    stepSize: 1
                }
            }

            RowLayout {
                Label { text: i18n("Outer") + ":" }
                SpinBox {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    enabled: sideMode
                    id: counterGapsOuter
                    from: 0
                    to: 99
                    stepSize: 1
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Offset") + ":"
            enabled: badgeMode
            Label { text: "X:" }
            SpinBox {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                id: counterOffsetX
                from: -5
                to: 5
                stepSize: 1
            }

            Label { text: "Y:" }
            SpinBox {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                id: counterOffsetY
                from: -5
                to: 5
                stepSize: 1
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        ComboBox {
            Kirigami.FormData.label: i18n("Font family") + ":"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            enabled: counterEnabled
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

        Slider {
            Kirigami.FormData.label: i18n("Font size") + ":"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            enabled: counterEnabled
            id: counterFontSize
            from: 2
            to: 8
            stepSize: 1
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Font bold") + ":"
            enabled: counterEnabled
            id: counterFontBold
            text: i18n("Enable")
            onCheckedChanged: cfg_counterFontBold = counterFontBold.checked
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        Button {
            Kirigami.FormData.label: i18n("Badge color") + ":"
            Layout.leftMargin: Kirigami.Units.gridUnit
            enabled: badgeMode

            id: counterColor
            implicitWidth: Kirigami.Units.gridUnit * 4
            implicitHeight: Kirigami.Units.gridUnit

            background: Item {
                Rectangle {
                    id: bg
                    anchors.fill: parent
                    radius: counterRadius.value
                    border.width: 1
                    border.color: "black"
                    color: cfg_counterColor ? cfg_counterColor : Kirigami.Theme.backgroundColor
                }

                Text {
                    anchors.centerIn: parent
                    text: bg.color.toString().toUpperCase()
                    font.bold: true
                    color: Kirigami.ColorUtils.brightnessForColor(bg.color) === Kirigami.ColorUtils.Dark ? "white" : "black"
                }
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
                visible: !cfg_counterColor && counterColor.hovered
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Badge radius") + ":"
            enabled: badgeMode

            Slider {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                id: counterRadius
                from: 0
                to: 100
                stepSize: 1
            }

            Label {
                text: counterRadius.value
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Badge opacity") + ":"
            enabled: badgeMode

            Slider {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                id: counterOpacity
                from: 0
                to: 10
                stepSize: 1
            }

            Label {
                text: counterOpacity.value / 10
            }
        }
// --------------------------------------------- BADGES SECTION ------------------------------------------------
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Icon Badges")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Paused") + ":"
            ComboBox {
                id: pauseBadgePosition
                textRole: "name"
                model: positions
                onCurrentIndexChanged: cfg_pauseBadgePosition = model[currentIndex].value
                Component.onCompleted: currentIndex = JS.setIndex(plasmoid.configuration.pauseBadgePosition, model)
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Updated") + ":"
            ComboBox {
                id: updatedBadgePosition
                textRole: "name"
                model: positions
                onCurrentIndexChanged: cfg_updatedBadgePosition = model[currentIndex].value
                Component.onCompleted: currentIndex = JS.setIndex(plasmoid.configuration.updatedBadgePosition, model)
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Offset") + ":"
            Label { text: "X:" }
            SpinBox {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                id: badgeOffsetX
                from: -5
                to: 5
                stepSize: 1
            }

            Label { text: "Y:" }
            SpinBox {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                id: badgeOffsetY
                from: -5
                to: 5
                stepSize: 1
            }
        }
    }
// --------------------------------------------- ------------------------------------------------
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
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                id: spacing
                from: 0
                to: 12
                stepSize: 1
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
