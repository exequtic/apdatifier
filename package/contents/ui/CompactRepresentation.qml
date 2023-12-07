import QtQuick 2.6
import QtQuick.Controls 1.4
import QtGraphicalEffects 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

Item {
    AppletIcon {
        anchors.fill: parent
        id: icon
        source: 'apdatifier-plasmoid-none'
        active: mouseArea.containsMouse

        BusyIndicator {
            anchors.fill: icon
            running: busy
            visible: running
            opacity: 0.6
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
        visible: count > 0 || error

        PlasmaComponents.Label {
            anchors.centerIn: parent
            id: labelBadge
            text: error ? '✖' : count
            font.pixelSize: PlasmaCore.Theme.smallestFont.pixelSize
            font.bold: true
            visible: bgBadge.visible
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
