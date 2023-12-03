import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1
import "../tools/tools.js" as JS

Item {
    id: root

    property alias cfg_interval: interval.value
    property alias cfg_flatpakEnabled: flatpakEnabled.checked
    property alias cfg_wrapperEnabled: wrapperEnabled.checked
    property var sortingMode: plasmoid.configuration.sortingMode
    property var columnsMode: plasmoid.configuration.columnsMode

    property var flatpakBin: plasmoid.configuration.flatpakBin
    property var wrappersBin: plasmoid.configuration.wrappersBin
    property var selectedWrapperBin: plasmoid.configuration.selectedWrapperBin

    property alias cfg_selectedWrapperIndex: root.selectedWrapper
    property int selectedWrapper

    ColumnLayout {
        RowLayout {
            Label {
                text: "Check interval:"
            }
            SpinBox {
                id: interval
                from: 15
                to: 1440
                stepSize: 5
                value: interval
            }
            Label {
                text: "minutes"
            }
        }

        CheckBox {
            id: flatpakEnabled
            text: "Enable Flatpak support"
            enabled: flatpakBin !== undefined

            Component.onCompleted: {
                if (checked && !flatpakBin) {
                    checked = false
                }
            }
        }

        CheckBox {
            id: wrapperEnabled
            text: "Use pacman wrapper for searching updates"
            enabled: wrappersBin !== undefined

            Component.onCompleted: {
                if (checked && !wrappersBin) {
                    checked = false
                }
            }
        }

        ComboBox {
            model: wrappersBin
            textRole: "name"
            enabled: wrapperEnabled.checked
            implicitWidth: 150

            onCurrentIndexChanged: {
                plasmoid.configuration.selectedWrapperBin = model[currentIndex]["bin"]
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
