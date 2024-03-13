/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Controls as QQC2

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

import "../tools/tools.js" as JS

Item {
    Kirigami.Icon {
        id: icon
        anchors.fill: parent
        source: JS.setIcon(plasmoid.icon)
        active: mouseArea.containsMouse

        Rectangle {
            id: frame
            anchors.centerIn: parent
            width: JS.setFrameSize()
            height: width * 0.9
            opacity: 0
            visible: cfg.indicatorUpdates && !busy && plasmoid.location !== PlasmaCore.Types.Floating
        }

        Rectangle {
            id: circle
            width: frame.width / 3.7
            height: width
            radius: width / 2
            visible: frame.visible && cfg.indicatorCircle && (error || count)
            color: error ? Kirigami.Theme.negativeTextColor
                 : cfg.indicatorColor ? cfg.indicatorColor
                 : Kirigami.Theme.highlightColor

            anchors {
                top: JS.setAnchor("top")
                bottom: JS.setAnchor("bottom")
                right: JS.setAnchor("right")
                left: JS.setAnchor("left")
            }
        }

        Rectangle {
            id: counterFrame
            width: counter.width + frame.width / 10
            height: cfg.indicatorScale ? frame.width / 3 : counter.height
            radius: width * 0.35
            color: Kirigami.Theme.backgroundColor
            opacity: 0.9
            visible: frame.visible && cfg.indicatorCounter

            QQC2.Label {
                id: counter
                anchors.centerIn: parent
                text: error ? "🛇" : (count || "✔")
                renderType: Text.NativeRendering
                font.bold: true
                font.pointSize: cfg.indicatorScale ? frame.width / 5 : Kirigami.Theme.smallFont.pointSize
                color: error ? Kirigami.Theme.negativeTextColor
                     : !count ? Kirigami.Theme.positiveTextColor
                     : Kirigami.Theme.textColor
            }

            anchors {
                top: JS.setAnchor("top")
                bottom: JS.setAnchor("bottom")
                right: JS.setAnchor("right")
                left: JS.setAnchor("left")
            }
        }

        Rectangle {
            id: intervalStopped
            anchors.centerIn: parent
            height: stop.height
            width: height
            radius: width / 2
            color: counterFrame.color
            opacity: counterFrame.opacity
            visible: !cfg.interval && cfg.indicatorStop

            QQC2.Label {
                id: stop
                anchors.centerIn: parent
                text: "⏸"
                renderType: Text.NativeRendering
                font.pointSize: cfg.indicatorScale ? frame.width / 5 : Kirigami.Theme.smallFont.pointSize
                color: Kirigami.Theme.neutralTextColor
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: cfg.rightClick ? Qt.AllButtons : Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true
        property bool wasExpanded: false
        onPressed: wasExpanded = expanded
        onClicked: (mouse) => {
            if (mouse.button == Qt.LeftButton) expanded = !wasExpanded
            if (mouse.button == Qt.MiddleButton && cfg.middleClick) JS[cfg.middleClick]()
            if (mouse.button == Qt.RightButton && cfg.rightClick) JS[cfg.rightClick]()
        }
        onEntered: {
            lastCheck = JS.getLastCheck()
        }
    }
}
