import QtQuick 2.6
import QtQuick.Controls 1.4
import QtGraphicalEffects 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.15 as Kirigami
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

            width: JS.indicatorFrameSize()
            height: width * 0.85
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

            width: frame.width / 4
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
            color: PlasmaCore.ColorScope.backgroundColor
            opacity: 0.9
            visible: frame.visible && plasmoid.configuration.indicatorCounter

            PlasmaComponents.Label {
                id: counter

                anchors.centerIn: parent

                text: count ? count : error ? "✖" : " "
                font.pixelSize: plasmoid.configuration.indicatorScale ? frame.width / 3 : PlasmaCore.Theme.smallestFont.pixelSize
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
