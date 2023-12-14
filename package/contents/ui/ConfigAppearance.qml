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
    // property alias cfg_showSortBtn: showSortBtn.checked
    // property alias cfg_showColsBtn: showColsBtn.checked

    property alias cfg_sortByName: sortByName.checked
    property alias cfg_sortByRepo: sortByRepo.checked

    // property var fontSettings: [plasmoid.configuration.fontIndex,
    //                             plasmoid.configuration.fontBold,
    //                             plasmoid.configuration.fontSize,
    //                             plasmoid.configuration.fontHeight]

    property var columns: plasmoid.configuration.columns
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

    RowLayout {
        spacing: 10

        QQC2.CheckBox {
            id: showDownloadBtn
            text: "Download database"
            icon.name: "repository"
            enabled: showStatusBar.checked && !plasmoid.configuration.checkupdates
        }

        QQC2.Label {
            font.italic: true
            font.pixelSize: 12
            color: Kirigami.Theme.neutralTextColor
            text: "Not needed for checkupdates"
            visible: showStatusBar.checked && plasmoid.configuration.checkupdates
            enabled: visible
        }
    }

    // QQC2.CheckBox {
    //     id: showSortBtn
    //     text: "Sorting columns"
    //     icon.name: "sort-name"
    //     enabled: showStatusBar.checked
    // }

    // QQC2.CheckBox {
    //     id: showColsBtn
    //     text: "Switch columns"
    //     icon.name: "show_table_column"
    //     enabled: showStatusBar.checked
    // }

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

    // after changing the font settings, the columns are layered on top of each other
    // this show all columns
    // temporary workaround
    // onFontSettingsChanged: {
    //     plasmoid.configuration.columns = 0
    // }
}
