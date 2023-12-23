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

    Kirigami.UrlButton {
        id: link
        url: "https://buymeacoffee.com/evgk"
        visible: false
    }

    Image {
        anchors.centerIn: parent
        // anchors.verticalCenterOffset: Kirigami.Units.gridUnit
        width: Math.min (parent.width, Kirigami.Units.gridUnit * 15)
        fillMode: Image.PreserveAspectFit
        mipmap: true
        source: "../assets/apdatifier-support.png"

        HoverHandler {
            id: hoverhandler
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: Qt.openUrlExternally(link.url)
        }

        QQC2.ToolTip {
            visible: hoverhandler.hovered
            text: i18n("Visit %1", link.url)
        }
    }
}
