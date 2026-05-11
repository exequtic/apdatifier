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
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Qt.openUrlExternally("https://nowpayments.io/donation/exequtic")
            }

            Label {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: "https://nowpayments.io"
                font.bold: true
                visible: handlerDonate.hovered
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
                text: "https://github.com"
            }
        }
    }
}
