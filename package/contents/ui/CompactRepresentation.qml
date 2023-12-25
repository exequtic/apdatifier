import QtQuick 2.15
import QtQuick.Controls 2.5 as QQC2
import org.kde.kirigami 2.15 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import "../tools/tools.js" as JS

Item {
    PlasmaCore.IconItem {
        id: icon
        anchors.fill: parent
        source: JS.setIcon(plasmoid.icon)
        active: mouseArea.containsMouse

        Rectangle {
            id: frame
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: JS.indicatorFrameSize()
            height: width * 0.9
            opacity: 0
            visible: !plasmoid.configuration.indicatorDisable
                        && plasmoid.location !== PlasmaCore.Types.Floating
                        && (!busy && count > 0 || error)
        }

        Rectangle {
            id: circle
            anchors.top: JS.indicatorAnchors("top")
            anchors.bottom: JS.indicatorAnchors("bottom")
            anchors.right: JS.indicatorAnchors("right")
            anchors.left: JS.indicatorAnchors("left")
            width: frame.width / 3.7
            height: width
            radius: width / 2
            color: error ? Kirigami.Theme.negativeTextColor
                            : plasmoid.configuration.indicatorColor
                                ? plasmoid.configuration.indicatorColor
                                    : PlasmaCore.ColorScope.highlightColor
            visible: frame.visible && plasmoid.configuration.indicatorCircle
        }

        Rectangle {
            id: counterFrame
            anchors.top: JS.indicatorAnchors("top")
            anchors.bottom: JS.indicatorAnchors("bottom")
            anchors.right: JS.indicatorAnchors("right")
            anchors.left: JS.indicatorAnchors("left")
            width: counter.width + (frame.width / 15) * PlasmaCore.Units.devicePixelRatio
            height: plasmoid.configuration.indicatorScale ? (frame.width / 3) : counter.height
            radius: width * 0.15
            color: Kirigami.Theme.backgroundColor
            opacity: 0.9
            visible: frame.visible && plasmoid.configuration.indicatorCounter

            QQC2.Label {
                id: counter
                anchors.centerIn: parent
                text: count ? count : error ? "✖" : " "
                font.pixelSize: plasmoid.configuration.indicatorScale ? frame.width / 3 : PlasmaCore.Theme.smallestFont.pixelSize
                renderType: Text.NativeRendering
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        property bool wasExpanded: false
        onPressed: wasExpanded = plasmoid.expanded
        onClicked: plasmoid.expanded = !wasExpanded
    }
}
