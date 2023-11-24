import QtQuick 2.6
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1

Item {
    property alias cfg_interval: interval.value
    property alias cfg_wrapper: wrapper.checked

    ColumnLayout {
        RowLayout {
            Label {
                text: "Check interval:"
            }
            SpinBox {
                id: interval
                stepSize: 5
                minimumValue: 5
                maximumValue: 1440
                value: cfg_interval
                suffix: " min"
            }
        }

        CheckBox {
            id: wrapper
            text: "Use pacman wrapper for searching updates"
        }
    }
}
