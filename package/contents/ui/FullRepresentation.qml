/*
    SPDX-FileCopyrightText: 2023 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 1.4 as QQC1

import org.kde.kirigami 2.15 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents

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

    QQC1.TableView {
        id: table
        model: listModel

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.bottom: separator.top

        visible: !busy && !error && count > 0

        backgroundVisible: false
        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff

        headerDelegate: Rectangle {
            height: plasmoid.configuration.showHeaders
                        ? PlasmaCore.Units.smallSpacing + fontHeight
                        : PlasmaCore.Units.smallSpacing
            color: Kirigami.Theme.backgroundColor
            radius: 6
            visible: plasmoid.configuration.showHeaders

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: styleData.column == 0 ? 10 : 0
                color: Kirigami.Theme.backgroundColor
            }

            Rectangle {
                width: 1
                height: parent.height * 0.8
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: Kirigami.Theme.alternateBackgroundColor
            }

            Text {
                id: textItem
                text: setText(styleData.value)
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                color: Kirigami.Theme.textColor

                font {
                    bold: plasmoid.configuration.customHeaders ? fontBold : true
                    pixelSize: plasmoid.configuration.customHeaders ? fontSize : Kirigami.Theme.defaultFont.pixelSize
                    family: plasmoid.configuration.customHeaders ? fontFamily : Kirigami.Theme.defaultFont
                }

                anchors {
                    right: parent.right
                    left: parent.left
                    rightMargin: 0
                    leftMargin: PlasmaCore.Units.smallSpacing
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

        QQC1.TableViewColumn {
            id: packageCol
            title: i18n("Package")
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
                    leftMargin: PlasmaCore.Units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        QQC1.TableViewColumn {
            id: repoCol
            title: i18n("Repository")
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
                    leftMargin: PlasmaCore.Units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        QQC1.TableViewColumn {
            title: i18n("Current")
            role: "curr"
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
                    leftMargin: PlasmaCore.Units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        QQC1.TableViewColumn {
            title: i18n("New")
            role: "newv"
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
                    leftMargin: PlasmaCore.Units.smallSpacing
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

            PlasmaComponents.ToolButton {
                icon.name: "repository"
                visible: (footer.visible && !busy && plasmoid.configuration.showDownloadBtn)
                            && ((plasmoid.configuration.checkupdates
                                && plasmoid.configuration.checkupdatesAUR)
                                    || (plasmoid.configuration.pacman)
                                    || (plasmoid.configuration.wrapper))

                PlasmaComponents.ToolTip {
                    text: i18n("Download database")
                }

                onClicked: JS.downloadDatabase()
            }

            PlasmaComponents.ToolButton {
                icon.name: "akonadiconsole"
                visible: footer.visible
                            && !busy
                            && !error
                            && count > 0
                            && plasmoid.configuration.showUpgradeBtn
                            && plasmoid.configuration.selectedTerminal

                PlasmaComponents.ToolTip {
                    text: i18n("Upgrade system")
                }

                onClicked: JS.upgradeSystem()
            }

            PlasmaComponents.ToolButton {
                icon.name: "view-refresh-symbolic"
                visible: footer.visible
                            && plasmoid.configuration.showCheckBtn
                            && !upgrading
                            && !downloading

                PlasmaComponents.ToolTip {
                    text: i18n("Check updates")
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
        enabled: busy && plasmoid.location !== PlasmaCore.Types.Floating
        visible: enabled
        asynchronous: true
        sourceComponent: QQC1.BusyIndicator {
            width: 128
            height: 128
            opacity: 0.3
            running: true
        }
    }

    Loader {
        anchors.centerIn: parent
        width: parent.width - (PlasmaCore.Units.largeSpacing * 4)
        enabled: !busy && !error && count == 0
        visible: enabled
        asynchronous: true
        sourceComponent: PlasmaExtras.PlaceholderMessage {
            width: parent.width
            iconName: "checkmark"
            text: i18n("System updated")
        }
    }

    Loader {
        anchors.centerIn: parent
        width: parent.width - (PlasmaCore.Units.largeSpacing * 4)
        enabled: !busy && error
        visible: enabled
        asynchronous: true
        sourceComponent: PlasmaExtras.PlaceholderMessage {
            width: parent.width
            iconName: "error"
            text: error
        }
    }
}
