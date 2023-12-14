import QtQuick 2.6
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.4
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami
import "../tools/tools.js" as JS

Item {
    property var fontFamily: plasmoid.configuration.fontCustom
                                ? plasmoid.configuration.selectedFont
                                : Kirigami.Theme.defaultFont
    property var fontSize: plasmoid.configuration.fontCustom
                                ? plasmoid.configuration.fontSize
                                : Kirigami.Theme.defaultFont.pixelSize
    property var fontBold: plasmoid.configuration.fontCustom
                                ? plasmoid.configuration.fontBold
                                : false
    property var fontHeight: plasmoid.configuration.fontCustom
                                ? Math.round(plasmoid.configuration.fontSize * 1.5 + plasmoid.configuration.fontHeight)
                                : Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.5)

    Layout.minimumWidth: PlasmaCore.Units.gridUnit * 24
    Layout.minimumHeight: PlasmaCore.Units.gridUnit * 24
    Layout.maximumWidth: PlasmaCore.Units.gridUnit * 80
    Layout.maximumHeight: PlasmaCore.Units.gridUnit * 40
    focus: true


    TableView {
        id: table
        model: listModel

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.bottom: separator.top

        visible: !busy && !error

        // headerVisible: false
        backgroundVisible: false
        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff

        headerDelegate: Rectangle {
            height: fontHeight + 5
            color: Kirigami.Theme.alternateBackgroundColor
            radius: 6

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: styleData.column == 0 ? 10 : 0
                color: Kirigami.Theme.alternateBackgroundColor
            }

            Rectangle {
                width: 1
                height: parent.height * 0.8
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: Kirigami.Theme.backgroundColor
            }

            Text {
                id: textItem
                text: setText(styleData.value)
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                color: Kirigami.Theme.textColor

                font {
                    bold: true
                    pixelSize: fontSize
                    family: fontFamily
                }

                anchors {
                    right: parent.right
                    left: parent.left
                    rightMargin: 0
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                function setText(val) {
                    if ((val == packageCol.title && plasmoid.configuration.sortByName)
                            ||
                        (val == repoCol.title && !plasmoid.configuration.sortByName))
                    {
                        return val + " •"
                    } else {
                        return val
                    }
                }
            }

            property var pressed: styleData.pressed
            onPressedChanged: {
                if (pressed) {
                    switch (styleData.value) {
                        case packageCol.title:
                            plasmoid.configuration.sortByName = true
                            break
                        case repoCol.title:
                            plasmoid.configuration.sortByName = false
                            break
                        default:
                            return
                    }
                }
            }
        }

        rowDelegate: Rectangle {
            radius: 6
            color: styleData.selected ? Kirigami.Theme.focusColor : "transparent"
            height: fontHeight
        }

        TableViewColumn {
            id: packageCol
            title: "Package"
            role: "name"
            width: table.width * 0.35

            delegate: Text {
                text: styleData.value
                elide: styleData.elideMode
                color: styleData.selected ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor

                font {
                    pixelSize: fontSize
                    family: fontFamily
                    bold: fontBold
                }

                verticalAlignment: Text.AlignVCenter
                anchors {
                    right: parent.right
                    left: parent.left
                    rightMargin: 0
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        TableViewColumn {
            id: repoCol
            title: "Repository"
            role: "repo"
            width: table.width * 0.15

            delegate: Text {
                text: styleData.value
                elide: styleData.elideMode
                color: styleData.selected ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor

                font {
                    pixelSize: fontSize
                    family: fontFamily
                    bold: fontBold
                }

                verticalAlignment: Text.AlignVCenter
                anchors {
                    right: parent.right
                    left: parent.left
                    rightMargin: 0
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        TableViewColumn {
            title: "Current"
            role: "current"
            width: table.width * 0.25

            delegate: Text {
                text: styleData.value
                elide: styleData.elideMode
                color: styleData.selected ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor

                font {
                    pixelSize: fontSize
                    family: fontFamily
                    bold: fontBold
                }

                verticalAlignment: Text.AlignVCenter
                anchors {
                    right: parent.right
                    left: parent.left
                    rightMargin: 0
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        TableViewColumn {
            title: "New"
            role: "newVer"
            width: table.width * 0.25

            delegate: Text {
                text: styleData.value
                elide: styleData.elideMode
                color: styleData.selected ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor

                font {
                    pixelSize: fontSize
                    family: fontFamily
                    bold: fontBold
                }

                verticalAlignment: Text.AlignVCenter
                anchors {
                    right: parent.right
                    left: parent.left
                    rightMargin: 0
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
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

            // PlasmaComponents.ToolButton {
            //     icon.name: columns >= 0 && columns < 3 ? 'hide_table_column' : 'show_table_column'
            //     visible: footer.visible &&
            //              !error &&
            //              !busy &&
            //              count > 0 &&
            //              plasmoid.configuration.showColsBtn

            //     PlasmaComponents.ToolTip {
            //         text: ['Hide repository',
            //                'Hide current version',
            //                'Hide new version',
            //                'Show repository',
            //                'Show new version', 
            //                'Show current version']
            //               [columns]
            //     }

            //     onClicked: {
            //         plasmoid.configuration.columns = columns >= 0 && columns < 5 ? columns + 1 : 0
            //     }
            // }

            // PlasmaComponents.ToolButton {
            //     icon.name: 'sort-name'
            //     visible: footer.visible &&
            //              !error &&
            //              !busy &&
            //              count > 1 &&
            //              plasmoid.configuration.showSortBtn

            //     PlasmaComponents.ToolTip {
            //         text: plasmoid.configuration.sortByName ? 'Sorting by repository' : 'Sorting by name'
            //     }

            //     onClicked: {
            //         plasmoid.configuration.sortByName = !plasmoid.configuration.sortByName
            //         plasmoid.configuration.sortByRepo = !plasmoid.configuration.sortByRepo
            //         JS.applySort()
            //     }
            // }

            PlasmaComponents.ToolButton {
                icon.name: 'repository'
                visible: footer.visible &&
                         !busy &&
                         !error &&
                         !plasmoid.configuration.checkupdates &&
                         plasmoid.configuration.showDownloadBtn

                PlasmaComponents.ToolTip {
                    text: 'Download databases'
                }

                onClicked: JS.refreshDatabase()
            }

            PlasmaComponents.ToolButton {
                icon.name: 'akonadiconsole'
                visible: footer.visible &&
                         !busy &&
                         count > 1 &&
                         plasmoid.configuration.showUpgradeBtn

                PlasmaComponents.ToolTip {
                    text: 'Upgrade system'
                }

                onClicked: JS.upgradeSystem()
            }

            PlasmaComponents.ToolButton {
                icon.name: 'view-refresh-symbolic'
                visible: footer.visible &&
                         plasmoid.configuration.showCheckBtn

                PlasmaComponents.ToolTip {
                    text: 'Check updates'
                }

                onClicked: JS.checkUpdates()
            }

            PlasmaComponents.ToolButton {
                icon.name: 'exifinfo'
                visible: footer.visible
                onClicked: {
                    console.log(plasmoid.configuration.selectedWrapper)
                    console.log(plasmoid.configuration.selectedTerminal)
                    console.log(plasmoid.configuration.selectedFont)
                    console.log(plasmoid.configuration)
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
            running: true
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
