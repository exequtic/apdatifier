import QtQuick 2.5
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.4

Item {
    ScrollView {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        ListView {
            id: updateListView
            model: root.theModel
            width: parent.width
            height: parent.height
            delegate: Item {
                height: 22
                Text {
                    text: modelData
                    font.pixelSize: 16
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                    color: theme.textColor
                }
            }
            snapMode: ListView.SnapToItem
        }
    }
}
