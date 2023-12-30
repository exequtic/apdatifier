/*
    SPDX-FileCopyrightText: 2023 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.5 as QQC2

import org.kde.kirigami 2.15 as Kirigami

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

            QQC2.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: i18n("Thanks for using my widget! If you appreciate my work, you can support me by starring the GitHub repository or buying me a coffee ;)")
                wrapMode: Text.WordWrap
            }
        }
    }

    RowLayout {
        anchors.centerIn: parent
        Layout.fillWidth: true
        Layout.fillHeight: true

        Kirigami.UrlButton {
            id: buymeacoffee
            url: "https://buymeacoffee.com/evgk"
            visible: false
        }

        Kirigami.UrlButton {
            id: github
            url: "https://github.com/exequtic/apdatifier"
            visible: false
        }

        Image {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            source: "../assets/apdatifier-donate.png"
            sourceSize.width: supportPage.width / 2
            sourceSize.height: supportPage.height

            HoverHandler {
                id: handlerCoffee
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Qt.openUrlExternally(buymeacoffee.url)
            }

            QQC2.ToolTip {
                visible: handlerCoffee.hovered
                text: i18n("Visit %1", buymeacoffee.url)
            }
        }

        Image {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            source: "../assets/apdatifier-githubstar.png"
            sourceSize.width: supportPage.width / 2
            sourceSize.height: supportPage.height

            HoverHandler {
                id: handlerGithub
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Qt.openUrlExternally(github.url)
            }

            QQC2.ToolTip {
                visible: handlerGithub.hovered
                text: i18n("Visit %1", github.url)
            }
        }
    }
}
