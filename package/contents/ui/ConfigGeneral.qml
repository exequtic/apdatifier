import QtQuick 2.6
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1

Item {
    property alias cfg_interval: interval.value

    ColumnLayout {
        RowLayout {
            Label {
                text: i18n("Check interval:")
            }
            SpinBox {
                id: interval
                stepSize: 5
                minimumValue: 5
                maximumValue: 1440
                value: cfg_interval
                suffix: i18nc("Minutes", " min")
            }
        }
    }
}
