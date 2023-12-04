import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1
import "../tools/tools.js" as JS

Item {
    id: root

    property alias cfg_interval: interval.value
    property alias cfg_flatpakEnabled: flatpakEnabled.checked
    property alias cfg_pacmanMode: pacmanMode.checked
    property alias cfg_checkupdatesMode: checkupdatesMode.checked
    property alias cfg_wrapperMode: wrapperMode.checked
    property alias cfg_dependencies: dependencies.text

    property var searchCmd: plasmoid.configuration.searchCmd
    property var cacheCmd: plasmoid.configuration.cacheCmd

    property var sortingMode: plasmoid.configuration.sortingMode
    property var columnsMode: plasmoid.configuration.columnsMode

    property var depsBin: plasmoid.configuration.depsBin
    property var wrappersBin: plasmoid.configuration.wrappersBin
    property var selectedWrapperBin: plasmoid.configuration.selectedWrapperBin

    property alias cfg_selectedWrapperIndex: root.selectedWrapper
    property int selectedWrapper

    ColumnLayout {
        RowLayout {
            Label {
                text: 'Check interval:'
            }
            SpinBox {
                id: interval
                from: 15
                to: 1440
                stepSize: 5
                value: interval
            }
            Label {
                text: 'minutes'
            }
        }

        CheckBox {
            id: flatpakEnabled
            text: 'Enable Flatpak support'
            enabled: depsBin[2]

            Component.onCompleted: {
                if (checked && !depsBin[2]) {
                    checked = false
                }
            }
        }

		TextField {
			id: dependencies
            visible: false
		}

        RadioButton {
            id: pacmanMode
            text: 'pacman'
        }

        RadioButton {
            id: checkupdatesMode
            text: 'checkupdates'
            enabled: depsBin[1]
        }

        RadioButton {
            id: wrapperMode
            text: 'wrapper'
            enabled: wrappersBin
        }

        ComboBox {
            model: wrappersBin
            textRole: 'name'
            enabled: wrapperMode.checked
            implicitWidth: 150

            onCurrentIndexChanged: {
                plasmoid.configuration.selectedWrapperBin = model[currentIndex]['bin']
                root.selectedWrapper = currentIndex
            }

            Component.onCompleted: {
                if (wrappersBin) {
                    currentIndex = JS.setIndex(selectedWrapperBin, wrappersBin)
                    currentIndex = JS.setIndexInit(plasmoid.configuration.selectedWrapperIndex)
                }
            }
        }
    }
}
