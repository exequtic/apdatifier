import QtQuick 2.5
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.4
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

Item {

    Layout.minimumWidth: footer.implicitWidth * 2
    Layout.minimumHeight: 200

    RowLayout {
        anchors.bottom: parent.bottom
        id: footer
        width: parent.width

        PlasmaExtras.DescriptiveLabel {
            text: root.checkStatus ? 
                    root.checkStatus :
                        root.updatesCount > 0 ? 
                            'Total updates pending: ' + root.updatesCount : ' '
        }

        PlasmaComponents.ToolButton {
            Layout.alignment: Qt.AlignRight
            icon.name: 'view-refresh-symbolic'
            PlasmaComponents.ToolTip {
                text: "Check updates"
            }
            onClicked: root.checkUpdates()
        }
    }

    ScrollView {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: separator.top
        ListView {
            model: root.listModel
            delegate: Item {
                height: 22
                Text {
                    text: modelData
                    font.pixelSize: 16
                    font.bold: true
                    color: theme.textColor
                }
            }
        }
    }

    Rectangle {
        anchors.bottom: footer.top
        id: separator
        width: footer.width
        height: 1
        color: Kirigami.Theme.textColor
        opacity: 0.1
    }

    Loader {
        anchors.centerIn: parent
        active: root.checkStatus
        visible: active
        asynchronous: true
        sourceComponent: BusyIndicator {
            width: 128
            height: 128
            opacity: 0.3
        }
    }

    Loader {
        anchors.centerIn: parent
        active: root.updatesCount === 0 && !root.checkStatus
        visible: active
        asynchronous: true
        sourceComponent: PlasmaExtras.PlaceholderMessage {
            width: parent.width
            iconName: "checkmark"
            text: "System updated"
        }
    }
}
