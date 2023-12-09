import QtQuick 2.6
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.5 as Kirigami
import "../tools/tools.js" as JS

Kirigami.FormLayout {
    id: appearancePage

    property alias cfg_sortByName: sortByName.checked
    property alias cfg_sortByRepo: sortByRepo.checked

    property alias cfg_showStatusBar: showStatusBar.checked
    property alias cfg_showCheckBtn: showCheckBtn.checked
    property alias cfg_showDownloadBtn: showDownloadBtn.checked
    property alias cfg_showSortBtn: showSortBtn.checked
    property alias cfg_showColsBtn: showColsBtn.checked

    property alias cfg_fontCustom: fontCustom.checked
    property alias cfg_fontIndex: appearancePage.indexFont
    property alias cfg_fontBold: fontBold.checked
    property alias cfg_fontSize: fontSize.value
    property alias cfg_fontHeight: fontHeight.value

    property var fontSettings: [plasmoid.configuration.fontIndex,
                                plasmoid.configuration.fontBold,
                                plasmoid.configuration.fontSize,
                                plasmoid.configuration.fontHeight]

    property var columns: plasmoid.configuration.columns

    property var selectedFont: plasmoid.configuration.selectedFont
    property int indexFont


    QQC2.CheckBox {
        id: fontCustom
        text: "Custom font settings"
    }

    QQC2.ComboBox {
        Kirigami.FormData.label: "Font family:"
        implicitWidth: 300
        textRole: 'name'
        model: JS.getFonts()
        enabled: fontCustom.checked

        onCurrentIndexChanged: {
            plasmoid.configuration.selectedFont = model[currentIndex]['value']
            appearancePage.indexFont = currentIndex
        }

        Component.onCompleted: {
            currentIndex = JS.setIndex(selectedFont, Qt.fontFamilies())
            currentIndex = JS.setIndexInit(plasmoid.configuration.fontIndex)
        }
    }

    QQC2.CheckBox {
        id: fontBold
        text: "Bold"
        enabled: fontCustom.checked
    }

    RowLayout {
        Layout.fillWidth: true
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
        Layout.fillWidth: true
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

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id: showCheckBtn
        Kirigami.FormData.label: "Buttons on status bar:"
        text: "Search updates"
        icon.name: "view-refresh-symbolic"
        enabled: showStatusBar.checked
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        QQC2.CheckBox {
            id: showDownloadBtn
            text: "Download database"
            icon.name: "download"
            enabled: showStatusBar.checked && !plasmoid.configuration.checkupdates
        }

        QQC2.Label {
            font.italic: true
            font.pixelSize: 12
            color: Kirigami.Theme.neutralTextColor
            text: "Not needed for checkupdates"
            visible: !showDownloadBtn.enabled
            enabled: visible
        }
    }

    QQC2.CheckBox {
        id: showSortBtn
        text: "Sorting columns"
        icon.name: "sort-name"
        enabled: showStatusBar.checked
    }

    QQC2.CheckBox {
        id: showColsBtn
        text: "Switch columns"
        icon.name: "show_table_column"
        enabled: showStatusBar.checked
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
        QQC2.ButtonGroup.group: sortGroup
    }

    QQC2.RadioButton {
        id: sortByRepo
        text: 'Repository'
        QQC2.ButtonGroup.group: sortGroup
    }

    // after changing the font settings, the columns are layered on top of each other
    // this show all columns
    // temporary workaround
    onFontSettingsChanged: {
        plasmoid.configuration.columns = 0
    }
}
