import QtQuick 2.6
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.5 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Dialogs 1.2
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons
import "../tools/tools.js" as JS

Kirigami.FormLayout {
    id: appearancePage

    property alias cfg_fontCustom: fontCustom.checked
    property string cfg_selectedFont: plasmoid.configuration.selectedFont
    property alias cfg_fontBold: fontBold.checked
    property alias cfg_fontSize: fontSize.value
    property alias cfg_fontHeight: fontHeight.value

    property alias cfg_showHeaders: showHeaders.checked
    property alias cfg_customHeaders: customHeaders.checked

    property alias cfg_showStatusBar: showStatusBar.checked
    property alias cfg_showCheckBtn: showCheckBtn.checked
    property alias cfg_showUpgradeBtn: showUpgradeBtn.checked
    property alias cfg_showDownloadBtn: showDownloadBtn.checked

    property alias cfg_sortByName: sortByName.checked
    property alias cfg_sortByRepo: sortByRepo.checked

    property string cfg_selectedIcon: plasmoid.configuration.selectedIcon

    property alias cfg_indicatorCounter: indicatorCounter.checked
    property alias cfg_indicatorScale: indicatorScale.checked
    property alias cfg_indicatorCircle: indicatorCircle.checked
    property string cfg_indicatorColor: plasmoid.configuration.indicatorColor
    property alias cfg_indicatorDisable: indicatorDisable.checked

    property bool cfg_indicatorTop: plasmoid.configuration.indicatorTop
    property bool cfg_indicatorBottom: plasmoid.configuration.indicatorBottom
    property bool cfg_indicatorRight: plasmoid.configuration.indicatorRight
    property bool cfg_indicatorLeft: plasmoid.configuration.indicatorLeft

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: "List View"
    }

    QQC2.CheckBox {
        id: fontCustom
        text: "Custom font settings"
    }

    QQC2.ComboBox {
        Kirigami.FormData.label: "Font family:"
        implicitWidth: 300
        textRole: 'name'
        model: JS.getFonts(Kirigami.Theme.defaultFont, Qt.fontFamilies())
        enabled: fontCustom.checked

        onCurrentIndexChanged: {
            cfg_selectedFont = model[currentIndex]['value']
        }

        Component.onCompleted: {
            currentIndex = JS.setIndex(plasmoid.configuration.selectedFont, model)
        }
    }

    QQC2.CheckBox {
        id: fontBold
        text: "Bold"
        enabled: fontCustom.checked
    }

    RowLayout {
        enabled: fontCustom.checked

        Kirigami.FormData.label: "Size:"

        QQC2.SpinBox {
            id: fontSize
            implicitWidth: 100
            from: 8
            to: 32
            stepSize: 1
            value: fontSize.value
        }

        QQC2.Label {
            text: "px"
        }
    }

    RowLayout {
        enabled: fontCustom.checked

        Kirigami.FormData.label: "Spacing:"

        QQC2.SpinBox {
            id: fontHeight
            implicitWidth: 100
            from: -6
            to: 12
            stepSize: 1
            value: fontHeight.value
        }

        QQC2.Label {
            text: "px"
        }
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id: showHeaders
        Kirigami.FormData.label: "Header:"
        text: 'Show table headers'
    }

    QQC2.CheckBox {
        id: customHeaders
        text: 'Apply custom font for headers'
        enabled: showHeaders.checked && fontCustom.checked
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id: showStatusBar
        Kirigami.FormData.label: "Status bar: "
        text: 'Show status bar'
    }

    QQC2.CheckBox {
        id: showCheckBtn
        text: "Search updates"
        icon.name: "view-refresh-symbolic"
        enabled: showStatusBar.checked
    }

    QQC2.CheckBox {
        id: showUpgradeBtn
        text: "Upgrade system"
        icon.name: "akonadiconsole"
        enabled: showStatusBar.checked
    }

    QQC2.CheckBox {
        id: showDownloadBtn
        text: "Download database"
        icon.name: "repository"
        enabled: showStatusBar.checked && !plasmoid.configuration.checkupdates
    }

    Kirigami.Separator {
        Layout.fillWidth: true
        visible: warning.visible || tip.visible
    }

    ColumnLayout {
        id: warning
        spacing: 0
        visible: showDownloadBtn.checked && !plasmoid.configuration.checkupdates

        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            QQC2.Label {
                font.pixelSize: tip.font.pixelSize
                text: "Avoid"
            }

            QQC2.Label {
                font.pixelSize: tip.font.pixelSize
                text: '<a href="https://wiki.archlinux.org/title/System_maintenance#Partial_upgrades_are_unsupported" style="color: ' + Kirigami.Theme.neutralTextColor + '">partial</a>'
                textFormat: Text.RichText
                onLinkActivated: Qt.openUrlExternally(link)
            }

            QQC2.Label {
                font.pixelSize: tip.font.pixelSize
                text: "upgrades!"
            }
        }

        QQC2.Label {
            Layout.maximumWidth: 250
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: tip.font.pixelSize
            text: "If you need to install a package after refreshing the package databases, use -Syu <i>package</i> (install package with full upgrade)."
            wrapMode: Text.WordWrap
        }
    }

    QQC2.Label {
        id: tip
        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize - 4
        text: "Not needed for checkupdates"
        visible: showStatusBar.checked && plasmoid.configuration.checkupdates
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.ButtonGroup {
        id: sortGroup
    }

    QQC2.RadioButton {
        id: sortByName
        Kirigami.FormData.label: "Sort list by:"
        text: 'Name'
        checked: true

        Component.onCompleted: {
            checked = plasmoid.configuration.sortByName
        }

        QQC2.ButtonGroup.group: sortGroup
    }

    QQC2.RadioButton {
        id: sortByRepo
        text: 'Repository'

        Component.onCompleted: {
            checked = !plasmoid.configuration.sortByName
        }

        QQC2.ButtonGroup.group: sortGroup
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: "Panel Icon View"
    }

    QQC2.Button {
        id: iconButton

        Kirigami.FormData.label: "Icon:"

        implicitWidth: iconFrame.width + PlasmaCore.Units.smallSpacing
        implicitHeight: implicitWidth
        hoverEnabled: true

        QQC2.ToolTip.text: cfg_selectedIcon
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        QQC2.ToolTip.visible: iconButton.hovered

        PlasmaCore.FrameSvgItem {
            id: iconFrame
            anchors.centerIn: parent
            width: PlasmaCore.Units.iconSizes.medium + fixedMargins.left + fixedMargins.right
            height: width
            imagePath: "widgets/background"

            PlasmaCore.IconItem {
                anchors.centerIn: parent
                width: PlasmaCore.Units.iconSizes.medium
                height: width
                source: JS.setIcon(cfg_selectedIcon)
            }
        }

        KQuickAddons.IconDialog {
            id: iconsDialog
            onIconNameChanged: cfg_selectedIcon = iconName || JS.defaultIcon
        }

        onPressed: menu.opened ? menu.close() : menu.open()

        QQC2.Menu {
            id: menu
            y: +parent.height

            QQC2.MenuItem {
                text: "Default icon"
                icon.name: "edit-clear"
                enabled: cfg_selectedIcon !== JS.defaultIcon
                onClicked: cfg_selectedIcon = JS.defaultIcon
            }

            QQC2.MenuItem {
                text: "Select..."
                icon.name: "document-open-folder"
                onClicked: iconsDialog.open()
            }
        }
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.ButtonGroup {
        id: indicator
    }

    RowLayout {
        Kirigami.FormData.label: "Indicator:"
        spacing: PlasmaCore.Units.largeSpacing

        QQC2.RadioButton {
            id: indicatorCounter
            text: "Counter"
            checked: true
            QQC2.ButtonGroup.group: indicator
        }

        QQC2.CheckBox {
            id: indicatorScale
            text: "Scale with icon"
            visible: indicatorCounter.checked
        }
    }

    RowLayout {
        spacing: PlasmaCore.Units.largeSpacing

        QQC2.RadioButton {
            id: indicatorCircle
            text: "Circle"    
            QQC2.ButtonGroup.group: indicator
        }


        QQC2.Button {
            id: colorButton

            implicitWidth: PlasmaCore.Units.largeSpacing - PlasmaCore.Units.smallSpacing
            implicitHeight: implicitWidth
            hoverEnabled: true
            visible: indicatorCircle.checked

            QQC2.ToolTip.text: cfg_indicatorColor ? cfg_indicatorColor : "Default accent color from current color scheme"
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            QQC2.ToolTip.visible: colorButton.hovered

            Rectangle {
                anchors.fill: parent
                radius: colorButton.implicitWidth / 2
                color: cfg_indicatorColor ? cfg_indicatorColor : PlasmaCore.ColorScope.highlightColor
            }

            onPressed: menuColor.opened ? menuColor.close() : menuColor.open()

            QQC2.Menu {
                id: menuColor
                y: +parent.height

                QQC2.MenuItem {
                    text: "Reset to default"
                    icon.name: "edit-clear"
                    enabled: cfg_indicatorColor && cfg_indicatorColor !== PlasmaCore.ColorScope.highlightColor
                    onClicked: cfg_indicatorColor = ""
                }

                QQC2.MenuItem {
                    text: "Select..."
                    icon.name: "document-open-folder"
                    onClicked: colorDialog.open()
                }
            }

            ColorDialog {
                id: colorDialog
                visible: false
                title: "Select circle color"
                showAlphaChannel: true
                color: cfg_indicatorColor

                onCurrentColorChanged: {
                    if (visible && color != currentColor) {
                        cfg_indicatorColor = currentColor
                        console.log(currentColor)
                    }
                }
            }
        }
    }

    QQC2.RadioButton {
        id: indicatorDisable
        text: "Nothing"    
        QQC2.ButtonGroup.group: indicator
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    RowLayout {
        visible: !indicatorDisable.checked
        Layout.fillWidth: true

        ColumnLayout {
            QQC2.Label {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignRight
                text: "Top-Left    "
                font.pixelSize: tip.font.pixelSize

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        topleft.checked = true
                    }
                }
            }

            QQC2.Label {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignRight
                text: "Bottom-Left    "
                font.pixelSize: tip.font.pixelSize

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        bottomleft.checked = true
                    }
                }
            }
        }

        QQC2.ButtonGroup {
            id: position
        }

        ColumnLayout {
            QQC2.RadioButton {
                id: topleft
                QQC2.ButtonGroup.group: position
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

            QQC2.RadioButton {
                id: bottomleft
                QQC2.ButtonGroup.group: position
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
        }

        ColumnLayout {
            QQC2.RadioButton {
                id: topright
                QQC2.ButtonGroup.group: position
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

            QQC2.RadioButton {
                id: bottomright
                QQC2.ButtonGroup.group: position
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
        }

        ColumnLayout {
            QQC2.Label {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignLeft
                text: "Top-Right"
                font.pixelSize: tip.font.pixelSize

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        topright.checked = true
                    }
                }
            }

            QQC2.Label {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignLeft
                text: "Bottom-Right"
                font.pixelSize: tip.font.pixelSize

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        bottomright.checked = true
                    }
                }
            }
        }
    }

    Item {
        Kirigami.FormData.isSection: true
    }
}
