import QtQuick 2.5
import QtGraphicalEffects 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

Item {
    AppletIcon {
        id: icon
        anchors.fill: parent
        source: 'apdatifier-plasmoid-none'
        active: mouseArea.containsMouse
    }

    Rectangle {
        id: circle
        height: label.height
        width: label.width + 4 * PlasmaCore.Units.devicePixelRatio
        radius: width * 0.40
        color: PlasmaCore.ColorScope.backgroundColor
        opacity: 0.6
        visible: root.updatesCount > 0 || root.checkStatus

        anchors {
            right: parent.right
            top: parent.top
        }

        PlasmaComponents.Label {
            id: label
            text: root.checkStatus ? '↻' : root.updatesCount
            font.pixelSize: PlasmaCore.Theme.smallestFont.pixelSize
            font.bold: true
            anchors.centerIn: parent
            visible: circle.visible
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
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        property bool wasExpanded: false
        onPressed: wasExpanded = plasmoid.expanded
        onClicked: plasmoid.expanded = !wasExpanded
    }
}
