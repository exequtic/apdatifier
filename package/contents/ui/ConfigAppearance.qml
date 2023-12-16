import QtQuick 2.6
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.5 as Kirigami
import "../tools/tools.js" as JS

Kirigami.FormLayout {
    id: appearancePage

    property alias cfg_fontCustom: fontCustom.checked
    property alias cfg_selectedFont: appearancePage.selectedFnt
    property alias cfg_fontBold: fontBold.checked
    property alias cfg_fontSize: fontSize.value
    property alias cfg_fontHeight: fontHeight.value

    property alias cfg_showStatusBar: showStatusBar.checked
    property alias cfg_showCheckBtn: showCheckBtn.checked
    property alias cfg_showUpgradeBtn: showUpgradeBtn.checked
    property alias cfg_showDownloadBtn: showDownloadBtn.checked

    property alias cfg_sortByName: sortByName.checked
    property alias cfg_sortByRepo: sortByRepo.checked

    property string selectedFnt

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
            appearancePage.selectedFnt = model[currentIndex]['value']
        }

        Component.onCompleted: {
            currentIndex = JS.setIndex(plasmoid.configuration.selectedFont, model)

            if (!plasmoid.configuration.selectedFont) {
                plasmoid.configuration.selectedFont = model[currentIndex]['value']
            }
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

    RowLayout {
        QQC2.Label {
            Layout.maximumWidth: 250
            font.pixelSize: tip.font.pixelSize
            text: "Not needed for checkupdates"
            visible: showStatusBar.checked && plasmoid.configuration.checkupdates
            enabled: visible
        }
    }

    ColumnLayout {
        spacing: 0
        visible: showDownloadBtn.checked && !plasmoid.configuration.checkupdates

        RowLayout {
            QQC2.Label {
                id: tip
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize - 4
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
            font.pixelSize: tip.font.pixelSize
            text: "If you need to install a package after refreshing the package databases, use -Syu <i>package</i> (install package with full upgrade)."
            wrapMode: Text.WordWrap
        }
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
}
