import QtQuick
import QtQuick.Controls.Basic
import org.kde.kirigami as Kirigami

ScrollBar {
    id: root

    property bool showByTimer: false

    visible: root.visualSize < 1.0

    Timer {
        id: hideTimer
        interval: 1200
        running: false
        repeat: false
        onTriggered: root.showByTimer = false
    }

    onActiveChanged: {
        if (active) {
            showByTimer = true
            hideTimer.restart()
        }
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: scroll.opacity = hovered ? 1 : 0.5
    }

    opacity: (!cfg.autoHideScrollBar || root.active || root.hovered || root.showByTimer) ? 0.8 : 0
    Behavior on opacity { NumberAnimation { duration: 300 } }

    contentItem: Rectangle {
        id: scroll
        implicitWidth: 5
        radius: width / 2
        color: Kirigami.Theme.highlightColor
        opacity: 0.5
        border.width: 1
        border.color: Qt.darker(Qt.rgba(color.r, color.g, color.b, 0.8), 2)
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }
}
