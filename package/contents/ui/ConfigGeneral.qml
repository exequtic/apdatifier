import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1
import "../tools/tools.js" as JS

Item {
    id: root

    property alias cfg_interval: interval.value
    property alias cfg_flatpak: flatpak.checked
    property alias cfg_wrapper: wrapper.checked
    property var sortingMode: plasmoid.configuration.sortingMode
    property var columnsMode: plasmoid.configuration.columnsMode

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
            id: flatpak
            text: "Enable Flatpak support"
        }

        CheckBox {
            id: wrapper
            text: "Use pacman wrapper for searching updates"
        }
    }
}
