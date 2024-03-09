/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Controls as QQC2

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents

import "../tools/tools.js" as JS

Item {
    Kirigami.Icon {
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
                                    : Kirigami.Theme.highlightColor
            visible: frame.visible && plasmoid.configuration.indicatorCircle
        }

        Rectangle {
            id: counterFrame
            anchors.top: JS.indicatorAnchors("top")
            anchors.bottom: JS.indicatorAnchors("bottom")
            anchors.right: JS.indicatorAnchors("right")
            anchors.left: JS.indicatorAnchors("left")
            width: counter.width + (frame.width / 10)
            height: plasmoid.configuration.indicatorScale ? (frame.width / 3) : counter.height
            radius: width * 0.30
            color: Kirigami.Theme.backgroundColor
            opacity: 0.9
            visible: frame.visible && plasmoid.configuration.indicatorCounter

            QQC2.Label {
                id: counter
                anchors.centerIn: parent
                text: count ? count : error ? "✖" : " "
                font.bold: true
                font.pointSize: plasmoid.configuration.indicatorScale ? frame.width / 5 :  Kirigami.Theme.smallFont.pointSize
                renderType: Text.NativeRendering
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        property bool wasExpanded: false
        onPressed: wasExpanded = expanded
        onClicked: expanded = !wasExpanded
        onHoveredChanged: {
            lastCheck = JS.getLastCheck()
        }
    }
}
