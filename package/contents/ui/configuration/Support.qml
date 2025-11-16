/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.kirigami as Kirigami

Kirigami.Page {
    id: supportPage

    leftPadding: Kirigami.Units.gridUnit
    rightPadding: Kirigami.Units.gridUnit

    header: Item {
        height: layout.implicitHeight + (Kirigami.Units.gridUnit * 2)

        ColumnLayout {
            id: layout
            width: parent.width - (Kirigami.Units.gridUnit * 2)
            anchors.centerIn: parent

            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: i18n("Thanks for using my widget! If you appreciate my work, you can support me by starring the GitHub repository or buying me a coffee ;)")
                font.bold: true
                wrapMode: Text.WordWrap
            }
        }
    }

    Menu {
        id: menu
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        MenuItem {
            text: i18n("buymeacoffee.com")
            icon.name: "internet-web-browser-symbolic"
            onTriggered: Qt.openUrlExternally("https://buymeacoffee.com/evgk")
        }
        MenuItem {
            text: i18n("nowpayments.io (crypto)")
            icon.name: "internet-web-browser-symbolic"
            onTriggered: Qt.openUrlExternally("https://nowpayments.io/donation/exequtic")
        }
    }

    RowLayout {
        anchors.centerIn: parent
        Layout.fillWidth: true
        Layout.fillHeight: true

        Image {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            source: "../assets/art/apdatifier-donate.png"
            sourceSize.width: supportPage.width / 2
            sourceSize.height: supportPage.height

            HoverHandler {
                id: handlerDonate
                cursorShape: menu.opened ? Qt.ArrowCursor : Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: (event) => menu.opened ? menu.close() : menu.popup(event.position.x, event.position.y)
            }

            Label {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Donate"
                font.bold: true
                visible: handlerDonate.hovered && !menu.opened
            }
        }

        Image {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            source: "../assets/art/apdatifier-githubstar.png"
            sourceSize.width: supportPage.width / 2
            sourceSize.height: supportPage.height

            HoverHandler {
                id: handlerGithub
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Qt.openUrlExternally("https://github.com/exequtic/apdatifier")
            }

            Label {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                font.bold: true
                visible: handlerGithub.hovered
                text: i18n("Visit %1", "github")
            }
        }
    }
}
