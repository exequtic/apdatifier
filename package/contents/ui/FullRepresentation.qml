import QtQuick 2.6
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.4
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami
import "../tools/tools.js" as JS

Item {
    Layout.minimumWidth: 400
    Layout.minimumHeight: 200

    ScrollView {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: separator.top
        ListView {
            id: list
            model: listModel
            delegate: GridLayout {
                columns: 4
                height: pkgName.font.pixelSize * 1.5
                Text {
                    id: pkgName
                    Layout.column: 0
                    Layout.minimumWidth: JS.columnWidth(0, list.width)
                    Layout.maximumWidth: pkgName.Layout.minimumWidth
                    text: modelData.split(' ')[0]
                    color: theme.textColor
                    elide: Text.ElideRight
                    font.pixelSize: theme.defaultFont.pixelSize
                    font.family: theme.defaultFont.family
                    font.bold: true
                }
                Text {
                    id: repoName
                    Layout.column: 1
                    Layout.minimumWidth: JS.columnWidth(1, list.width)
                    Layout.maximumWidth: repoName.Layout.minimumWidth
                    text: modelData.split(' ')[1]
                    color: theme.textColor
                    elide: Text.ElideRight
                    font.pixelSize: pkgName.font.pixelSize
                    font.family: pkgName.font.family
                }
                Text {
                    id: currentVersion
                    Layout.column: 2
                    Layout.minimumWidth: JS.columnWidth(2, list.width)
                    Layout.maximumWidth: currentVersion.Layout.minimumWidth
                    text: modelData.split(' ')[2]
                    color: theme.textColor
                    elide: Text.ElideRight
                    font.pixelSize: pkgName.font.pixelSize
                    font.family: pkgName.font.family
                }
                Text {
                    id: newVersion
                    Layout.column: 3
                    Layout.minimumWidth: JS.columnWidth(3, list.width)
                    Layout.maximumWidth: newVersion.Layout.minimumWidth
                    text: modelData.split(' ')[3]
                    color: theme.textColor
                    elide: Text.ElideRight
                    font.pixelSize: pkgName.font.pixelSize
                    font.family: pkgName.font.family
                }
            }
        }
    }

    RowLayout {
        anchors.bottom: parent.bottom
        id: footer
        width: parent.width

        PlasmaExtras.DescriptiveLabel {
            text: statusMsg
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 0

            PlasmaComponents.ToolButton {
                icon.name: columnsMode >= 0 && columnsMode < 3 ? 'hide_table_column' : 'show_table_column'
                PlasmaComponents.ToolTip {
                    text: [
                            'Hide repository',
                            'Hide current version',
                            'Hide new version',
                            'Show repository',
                            'Show new version', 
                            'Show current version'
                          ][columnsMode]
                }
                onClicked: {
                            plasmoid.configuration.columnsMode = columnsMode >= 0 && columnsMode < 5 ? columnsMode + 1 : 0
                }
                visible: !error && !busy && updCount > 1
            }

            PlasmaComponents.ToolButton {
                icon.name: sortingMode == 0 ? 'repository' : 'sort-name'
                PlasmaComponents.ToolTip {
                    text: sortingMode == 0 ? 'Sorting by repository' : 'Sorting by name'
                }
                onClicked: {
                            plasmoid.configuration.sortingMode = sortingMode == 0 ? sortingMode + 1 : 0
                            JS.sortList(updList)
                }
                visible: !error && !busy && updCount > 1
            }

            PlasmaComponents.ToolButton {
                icon.name: 'view-refresh-symbolic'
                PlasmaComponents.ToolTip {
                    text: 'Check updates'
                }
                onClicked: JS.checkUpdates()
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
        active: busy
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
        active: updCount == 0 || !busy && error
        visible: active
        asynchronous: true
        sourceComponent: PlasmaExtras.PlaceholderMessage {
            width: parent.width
            iconName: updCount == 0 ? 'checkmark' : 'error'
            text: updCount == 0 ? 'System updated' : error
        }
    }
}
