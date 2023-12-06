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

    property var sortingMode: plasmoid.configuration.sortingMode
    property var columnsMode: plasmoid.configuration.columnsMode
    property var selectedWrapper: plasmoid.configuration.selectedWrapper

    property var dependencies: plasmoid.configuration.dependencies
    property var packages: plasmoid.configuration.packages
    property var wrappers: plasmoid.configuration.wrappers

    property int wrapperIndex: root.indexWrapper
    property int indexWrapper

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
            enabled: packages[2]

            onCheckedChanged: {
                if (checked && !packages[2]) {
                    plasmoid.configuration.flatpakEnabled = false
                }
            }

            Component.onCompleted: {
                if (checked && !packages[2]) {
                    checked = false
                }
            }
        }

        RadioButton {
            id: pacmanMode
            text: 'pacman'
        }

        RadioButton {
            id: checkupdatesMode
            text: 'checkupdates'
            enabled: packages[1]
        }

        RadioButton {
            id: wrapperMode
            text: 'wrapper'
            enabled: wrappers
        }

        ComboBox {
            model: wrappers
            textRole: 'name'
            enabled: wrapperMode.checked
            implicitWidth: 150

            onCurrentIndexChanged: {
                plasmoid.configuration.selectedWrapper = model[currentIndex]['bin']
                root.indexWrapper = currentIndex
            }

            Component.onCompleted: {
                if (wrappers) {
                    currentIndex = JS.setIndex(selectedWrapper, wrappers)
                    currentIndex = JS.setIndexInit(plasmoid.configuration.wrapperIndex)
                }
            }
        }
    }
}
