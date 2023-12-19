import QtQuick 2.6
import QtQuick.Controls 1.4
import QtGraphicalEffects 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import "../tools/tools.js" as JS

Item {
    PlasmaCore.IconItem {
        id: icon
        anchors.fill: parent
        source: JS.setIcon(plasmoid.icon)
        active: mouseArea.containsMouse

        BusyIndicator {
            anchors.fill: icon
            running: busy
            visible: running
        }

        Rectangle {
            id: frame

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            width: JS.indicatorFrameWidth()
            height: width
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

            width: frame.width / 3.3
            height: width
            radius: width / 2
            color: plasmoid.configuration.indicatorColor ? plasmoid.configuration.indicatorColor : PlasmaCore.ColorScope.highlightColor
            visible: frame.visible && plasmoid.configuration.indicatorCircle
        }

        Rectangle {
            id: counterFrame

            anchors.top: JS.indicatorAnchors("top")
            anchors.bottom: JS.indicatorAnchors("bottom")
            anchors.right: JS.indicatorAnchors("right")
            anchors.left: JS.indicatorAnchors("left")

            width: counter.width + (frame.width / 10) * PlasmaCore.Units.devicePixelRatio
            height: plasmoid.configuration.indicatorScale ? frame.width / 3 : counter.height
            radius: width * 0.30
            color: PlasmaCore.ColorScope.backgroundColor
            opacity: 0.7
            visible: frame.visible && plasmoid.configuration.indicatorCounter

            PlasmaComponents.Label {
                id: counter

                anchors.centerIn: parent

                text: count ? count : error ? "✖" : " "
                font.pixelSize: plasmoid.configuration.indicatorScale ? frame.width / 3 : PlasmaCore.Theme.smallestFont.pixelSize
                font.bold: true
                renderType: Text.NativeRendering
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        id: mouseArea
        hoverEnabled: true
        property bool wasExpanded: false
        onPressed: wasExpanded = plasmoid.expanded
        onClicked: plasmoid.expanded = !wasExpanded
    }
}
