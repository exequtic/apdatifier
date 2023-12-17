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
            opacity: 0.8
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        id: bgBadge
        height: labelBadge.height
        width: labelBadge.width + 3 * PlasmaCore.Units.devicePixelRatio
        radius: width * 0.40
        color: PlasmaCore.ColorScope.backgroundColor
        opacity: 0.6
        visible: !busy && count > 0 || error

        PlasmaComponents.Label {
            anchors.centerIn: parent
            id: labelBadge
            text: count ? count
                    : error ? '✖'
                    : ' '

            font.pixelSize: PlasmaCore.Theme.smallestFont.pixelSize
            font.bold: true
        }

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 0
            radius: 1
            samples: 1 + radius * 2
            color: Qt.rgba(0, 0, 0, 0.3)
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
