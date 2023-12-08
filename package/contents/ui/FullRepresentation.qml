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
        enabled: plasmoid.configuration.showStatusBar
        visible: enabled

        RowLayout {
            spacing: 0
            visible: footer.visible

            PlasmaComponents.ToolButton {
                icon.name: statusIco
                enabled: false
            }

            PlasmaExtras.DescriptiveLabel {
                text: statusMsg
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 0

            PlasmaComponents.ToolButton {
                icon.name: columns >= 0 && columns < 3 ? 'hide_table_column' : 'show_table_column'
                visible: footer.visible && !error && !busy && count > 0 && plasmoid.configuration.showColsBtn

                PlasmaComponents.ToolTip {
                    text: ['Hide repository',
                           'Hide current version',
                           'Hide new version',
                           'Show repository',
                           'Show new version', 
                           'Show current version']
                          [columns]
                }

                onClicked: {
                    plasmoid.configuration.columns = columns >= 0 && columns < 5 ? columns + 1 : 0
                }
            }

            PlasmaComponents.ToolButton {
                icon.name: plasmoid.configuration.sortByName ? 'repository' : 'sort-name'
                visible: footer.visible && !error && !busy && count > 1 && plasmoid.configuration.showSortBtn

                PlasmaComponents.ToolTip {
                    text: plasmoid.configuration.sortByName ? 'Sorting by repository' : 'Sorting by name'
                }

                onClicked: {
                    plasmoid.configuration.sortByName = !plasmoid.configuration.sortByName
                    plasmoid.configuration.sortByRepo = !plasmoid.configuration.sortByRepo
                    JS.sortList(updList)
                }
            }

            PlasmaComponents.ToolButton {
                icon.name: 'download'
                visible: footer.visible && !busy && plasmoid.configuration.showDatabaseBtn && !plasmoid.configuration.checkupdates

                PlasmaComponents.ToolTip {
                    text: 'Download databases'
                }

                onClicked: JS.refreshDatabase()
            }

            PlasmaComponents.ToolButton {
                icon.name: 'view-refresh-symbolic'
                visible: footer.visible && plasmoid.configuration.showCheckBtn

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
        visible: footer.visible
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
        active: count == 0 || !busy && error
        visible: active
        asynchronous: true
        sourceComponent: PlasmaExtras.PlaceholderMessage {
            width: parent.width
            iconName: count == 0 ? 'checkmark' : 'error'
            text: count == 0 ? 'System updated' : error
        }
    }
}
