/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Controls

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import Qt5Compat.GraphicalEffects

import "../components" as QQC
import "../../tools/tools.js" as JS

Item {
    property bool horizontal: plasmoid.location === 3 || plasmoid.location === 4
    property int badgeSize: (horizontal ? icon.width : icon.height) / 3
    property int frameWidth: (horizontal ? icon.width : icon.height) + cfg.counterOffsetX
    property int frameHeight: (horizontal ? icon.width : icon.height) + cfg.counterOffsetY

    Kirigami.Icon {
        id: icon
        anchors.fill: parent
        source: JS.setIcon(plasmoid.icon)
        active: mouseArea.containsMouse
    }

    Rectangle {
        id: frame
        anchors.centerIn: icon
        width: frameWidth
        height: frameHeight
        opacity: 0
    }

    Rectangle {
        id: counterFrame
        width: cfg.counterCenter ? frameWidth : counter.width + 2
        height: cfg.counterCenter ? frameHeight : counter.height
        radius: cfg.counterRadius
        opacity: cfg.counterOpacity / 10
        color: cfg.counterColor ? cfg.counterColor : Kirigami.Theme.backgroundColor
        visible: cfg.counterEnabled && sts.pending && !errorBadge.visible && !checkmarkBadge.visible && plasmoid.location !== PlasmaCore.Types.Floating

        layer.enabled: cfg.counterShadow
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 0
            radius: 2
            samples: radius * 2
            color: Qt.rgba(0, 0, 0, 0.5)
        }

        anchors.centerIn: JS.setAnchor("parent")
        anchors.top: JS.setAnchor("top")
        anchors.bottom: JS.setAnchor("bottom")
        anchors.right: JS.setAnchor("right")
        anchors.left: JS.setAnchor("left")
    }

    function darkColor(color) {
        return Kirigami.ColorUtils.brightnessForColor(color) === Kirigami.ColorUtils.Dark
    }
    property var isDarkText: darkColor(Kirigami.Theme.textColor)
    property var lightText: isDarkText ? Kirigami.Theme.backgroundColor : Kirigami.Theme.textColor
    property var darkText: isDarkText ? Kirigami.Theme.textColor : Kirigami.Theme.backgroundColor

    Label {
        id: counter
        anchors.centerIn: counterFrame
        text: sts.count
        renderType: Text.NativeRendering
        font.bold: cfg.counterBold
        font.pixelSize: Math.max(icon.height / 4, Kirigami.Theme.smallFont.pixelSize + cfg.counterSize)
        color: cfg.counterColor ? darkColor(counterFrame.color) ? lightText : darkText : Kirigami.Theme.textColor
        visible: counterFrame.visible
    }

    QQC.Badge {
        id: errorBadge
        iconName: cfg.ownIconsUI ? "status_error" : "error"
        iconColor: Kirigami.Theme.negativeTextColor
        visible: sts.err
        position: 0
    }

    QQC.Badge {
        id: checkmarkBadge
        iconName: cfg.ownIconsUI ? "status_updated" : "checkmark"
        iconColor: Kirigami.Theme.positiveTextColor
        visible: sts.updated
        position: 0
    }

    QQC.Badge {
        id: stoppedBadge
        iconName: cfg.ownIconsUI ? "toolbar_pause" : "media-playback-paused"
        iconColor: Kirigami.Theme.neutralTextColor
        visible: sts.idle && cfg.indicatorStop && !cfg.interval
        position: 1
    }

    MouseArea {
        property bool wasExpanded: false
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: cfg.rightAction ? Qt.AllButtons : Qt.LeftButton | Qt.MiddleButton

        onEntered: sts.checktime = JS.getLastCheckTime()

        onPressed: mouse => {
            wasExpanded = expanded
            if (!cfg.rightAction && mouse.button == Qt.RightButton) mouse.accepted = false
        }

        onClicked: mouse => {
            if (mouse.button == Qt.LeftButton) expanded = !wasExpanded
            if (mouse.button == Qt.MiddleButton && cfg.middleAction) JS[cfg.middleAction]()
            if (mouse.button == Qt.RightButton && cfg.rightAction) JS[cfg.rightAction]()
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (event) => {
                if (srollTimer.running) return
                srollTimer.start()
                var action = event.angleDelta.y > 0 ? cfg.scrollUpAction : cfg.scrollDownAction
                if (!action) return
                JS[action]()
            }
        }

        Timer {
            id: srollTimer
            interval: 500
        }
    }
}
