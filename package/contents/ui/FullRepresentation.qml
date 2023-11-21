import QtQuick 2.5
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.4
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents

Item {
    RowLayout {
        id: footer
        width: parent.width

        anchors {
            bottom: parent.bottom
        }

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
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: footer.top
        }

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

    BusyIndicator {
        anchors.centerIn: parent
        width: 128
        height: 128
        opacity: 0.3
        visible: root.checkStatus
    }

    Loader {
        anchors.centerIn: parent
        width: parent.width - (PlasmaCore.Units.largeSpacing * 4)

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
