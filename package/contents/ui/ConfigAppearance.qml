import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

Item {
    id: root

    property alias cfg_sortByName: sortByName.checked
    property alias cfg_sortByRepo: sortByRepo.checked

    property alias cfg_showStatusBar: showStatusBar.checked
    property alias cfg_showCheckBtn: showCheckBtn.checked
    property alias cfg_showDatabaseBtn: showDatabaseBtn.checked
    property alias cfg_showSortBtn: showSortBtn.checked
    property alias cfg_showColsBtn: showColsBtn.checked

    property var columns: plasmoid.configuration.columns

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
    }
}
