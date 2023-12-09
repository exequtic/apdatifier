import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1
import "../tools/tools.js" as JS

Item {
    id: root

    property alias cfg_interval: interval.checked
    property alias cfg_time: time.value
    property alias cfg_flatpak: flatpak.checked
    property alias cfg_pacman: pacman.checked
    property alias cfg_checkupdates: checkupdates.checked
    property alias cfg_wrapper: wrapper.checked

    property var selectedWrapper: plasmoid.configuration.selectedWrapper
    property var dependencies: plasmoid.configuration.dependencies
    property var packages: plasmoid.configuration.packages
    property var wrappers: plasmoid.configuration.wrappers

    property alias cfg_wrapperIndex: root.indexWrapper
    property int indexWrapper

    ColumnLayout {
        RowLayout {
            CheckBox {
                id: interval
                text: 'Interval: '
            }
            SpinBox {
                id: time
                from: 10
                to: 1440
                stepSize: 5
                value: time
                enabled: interval.checked
            }
            Label {
                text: 'minutes'
            }
        }

        CheckBox {
            id: flatpak
            text: 'Enable Flatpak support'
            enabled: packages[2]

            onCheckedChanged: {
                if (checked && !packages[2]) {
                    plasmoid.configuration.flatpak = false
                }
            }

            Component.onCompleted: {
                if (checked && !packages[2]) {
                    checked = false
                }
            }
        }

        ButtonGroup {
            buttons: groupSearch.children
        }

        Column {
            id: groupSearch
        
            RadioButton {
                id: pacman
                text: 'pacman'
                checked: true
            }

            RadioButton {
                id: checkupdates
                text: 'checkupdates'
                enabled: packages[1]
            }

            RadioButton {
                id: wrapper
                text: 'wrapper'
                enabled: wrappers
            }
        }

        ComboBox {
            model: wrappers
            textRole: 'name'
            enabled: wrapper.checked
            implicitWidth: 150
            visible: wrappers && wrappers.length > 1

            onCurrentIndexChanged: {
                plasmoid.configuration.selectedWrapper = model[currentIndex]['value']
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
