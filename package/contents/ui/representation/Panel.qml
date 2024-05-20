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

import "../../tools/tools.js" as JS

Item {
    property bool horizontal: plasmoid.location === 3 || plasmoid.location === 4
    property int frameWidth: (horizontal ? icon.width : icon.height) + cfg.counterOffsetX
    property int frameHeight: (horizontal ? icon.width : icon.height) + cfg.counterOffsetY

    Kirigami.Icon {
        id: icon
        anchors.fill: parent
        source: JS.setIcon(plasmoid.icon)
        active: mouseArea.containsMouse

        Rectangle {
            id: frame
            anchors.centerIn: parent
            width: frameWidth
            height: frameHeight
            opacity: 0
            visible: !busy && plasmoid.location !== PlasmaCore.Types.Floating
        }

        Rectangle {
            id: counterFrame
            width: cfg.counterCenter ? frameWidth : counter.width + 2
            height: cfg.counterCenter ? frameHeight : counter.height
            radius: cfg.counterRadius
            opacity: cfg.counterOpacity / 10
            color: cfg.counterColor ? cfg.counterColor : Kirigami.Theme.backgroundColor
            visible: frame.visible && cfg.counterEnabled

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 0
                radius: 2
                samples: radius * 2
                color: Qt.rgba(0, 0, 0, 0.5)
            }

            anchors {
                centerIn: JS.setAnchor("parent")
                top: JS.setAnchor("top")
                bottom: JS.setAnchor("bottom")
                right: JS.setAnchor("right")
                left: JS.setAnchor("left")
            }
        }

        Label {
            id: counter
            anchors.centerIn: counterFrame
            text: error ? "🛇" : (count || "✔")
            renderType: Text.NativeRendering
            font.bold: cfg.counterBold
            font.pixelSize: Math.max(icon.height / 4, Kirigami.Theme.smallFont.pixelSize + cfg.counterSize)
            color: Kirigami.ColorUtils.brightnessForColor(counterFrame.color) === Kirigami.ColorUtils.Dark ? "white" : "black"
            visible: counterFrame.visible
        }

        Rectangle {
            id: stopFrame
            width: stop.width + 2
            height: stop.height
            radius: width / 2
            color: counterFrame.color
            opacity: 0.8
            visible: frame.visible && !cfg.interval && cfg.indicatorStop

            anchors {
                top: JS.setAnchor("top", 1)
                bottom: JS.setAnchor("bottom", 1)
                right: JS.setAnchor("right", 1)
                left: JS.setAnchor("left", 1)
            }
        }

        Label {
            id: stop
            anchors.centerIn: stopFrame
            text: "⏸"
            renderType: Text.NativeRendering
            font.pixelSize: Math.max(icon.height / 4, Kirigami.Theme.smallFont.pixelSize - 2)
            color: Kirigami.Theme.neutralTextColor
            visible: stopFrame.visible
        }
    }

    MouseArea {
        property bool wasExpanded: false
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: cfg.rightAction ? Qt.AllButtons : Qt.LeftButton | Qt.MiddleButton

        onEntered: {
            lastCheck = JS.getLastCheckTime()
        }

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
            running: false
            repeat: false
        }
    }
}
