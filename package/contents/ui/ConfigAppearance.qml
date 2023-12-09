import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1
import "../tools/tools.js" as JS

Item {
    id: root

    property alias cfg_sortByName: sortByName.checked
    property alias cfg_sortByRepo: sortByRepo.checked

    property alias cfg_showStatusBar: showStatusBar.checked
    property alias cfg_showCheckBtn: showCheckBtn.checked
    property alias cfg_showDatabaseBtn: showDatabaseBtn.checked
    property alias cfg_showSortBtn: showSortBtn.checked
    property alias cfg_showColsBtn: showColsBtn.checked

    property alias cfg_fontDefault: fontDefault.checked
    property alias cfg_fontIndex: root.indexFont
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

    ColumnLayout {
        ButtonGroup {
            buttons: groupSorting.children
        }

        Column {
            id: groupSorting

            RadioButton {
                id: sortByName
                text: 'Sort updates list by name'
                checked: true
            }

            RadioButton {
                id: sortByRepo
                text: 'Sort updates list by repository'
            }
        }

        CheckBox {
            id: showStatusBar
            text: 'Show status line with buttons on bottom'
        }

        CheckBox {
            id: showCheckBtn
            text: 'Show button for searching'
            enabled: showStatusBar.checked
        }

        CheckBox {
            id: showDatabaseBtn
            text: 'Show button for download database'
            enabled: showStatusBar.checked && !plasmoid.configuration.checkupdates
        }

        CheckBox {
            id: showSortBtn
            text: 'Show button for sortiing'
            enabled: showStatusBar.checked
        }

        CheckBox {
            id: showColsBtn
            text: 'Show button for hide/show columns'
            enabled: showStatusBar.checked
        }

        CheckBox {
            id: fontDefault
            text: 'Use default system font'
        }

        ComboBox {
            textRole: 'name'
            implicitWidth: 300
            model: JS.getFonts()
            enabled: !fontDefault.checked

            onCurrentIndexChanged: {
                plasmoid.configuration.selectedFont = model[currentIndex]['value']
                root.indexFont = currentIndex
            }

            Component.onCompleted: {
                currentIndex = JS.setIndex(selectedFont, Qt.fontFamilies())
                currentIndex = JS.setIndexInit(plasmoid.configuration.fontIndex)
            }
        }

        CheckBox {
            id: fontBold
            text: 'Bold'
        }

        RowLayout {
            Label {
                text: 'Font Size: '
            }
            SpinBox {
                id: fontSize
                from: 8
                to: 32
                stepSize: 1
                value: fontSize.value
            }
        }

        RowLayout {
            Label {
                text: 'Spacing: '
            }
            SpinBox {
                id: fontHeight
                from: -6
                to: 12
                stepSize: 1
                value: fontHeight.value
            }
        }
    }

    // after changing the font settings, the columns are layered on top of each other
    // this show all columns
    // temporary workaround
    onFontSettingsChanged: {
        plasmoid.configuration.columns = 0
    }
}
