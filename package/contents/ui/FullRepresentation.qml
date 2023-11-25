import QtQuick 2.5
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.4
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami
import "../tools/tools.js" as Util

Item {
    Layout.minimumWidth: 400
    Layout.minimumHeight: 200

    ScrollView {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: separator.top
        ListView {
            model: listModel
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

    RowLayout {
        anchors.bottom: parent.bottom
        id: footer
        width: parent.width

        PlasmaExtras.DescriptiveLabel {
            text: checkStatus ? 'Checking updates...' :
                  updatesCount > 0 ? 'Total updates pending: ' + updatesCount : ' '
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 0

            PlasmaComponents.ToolButton {
                icon.name: sort === 0 ? 'repository' : 'sort-name'
                PlasmaComponents.ToolTip {
                    text: sort === 0 ? "Sorting by repository" : "Sorting by name"
                }
                onClicked: {
                            plasmoid.configuration.sort = sort === 0 ? sort + 1 : 0
                            Util.makeList()
                }
                visible: !errorStd && !checkStatus && updatesCount > 1
            }

            PlasmaComponents.ToolButton {
                icon.name: 'view-refresh-symbolic'
                PlasmaComponents.ToolTip {
                    text: "Check updates"
                }
                onClicked: Util.checkUpdates()
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
        active: checkStatus
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
        width: parent.width - (PlasmaCore.Units.largeSpacing * 4)
        active: updatesCount === 0 || !checkStatus && errorStd
        visible: active
        asynchronous: true
        sourceComponent: PlasmaExtras.PlaceholderMessage {
            width: parent.width
            iconName: updatesCount === 0 ? "checkmark" : "error"
            text: updatesCount === 0 ? "System updated" : errorStd[0]
        }
    }
}
