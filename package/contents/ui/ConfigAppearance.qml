import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

Item {
    id: root

    property alias cfg_sortByName: sortByName.checked
    property alias cfg_sortByRepo: sortByRepo.checked
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
            id: showSortBtn
            text: 'Show button for sortiing'
        }

        CheckBox {
            id: showColsBtn
            text: 'Show button for hide/show columns'
        }
    }
}
