/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: badge

    property var iconName: ""
    property var iconColor: ""

    property string position: {
        if (iconName === pausedIcon)   return cfg.pauseBadgePosition
        if (iconName === updatedIcon)  return cfg.updatedBadgePosition
        if (iconName === errorIcon)    return cfg.updatedBadgePosition
        return "topRight"
    }

    width: (counterOverlay ? trayIconSize : parent.width) / 3
    height: width
    radius: width / 2
    color: cfg.counterColor ? cfg.counterColor : Kirigami.Theme.backgroundColor

    anchors {
        topMargin:    state.includes("top") ? cfg.badgeOffsetX : 0
        leftMargin:   state.includes("Left") ? cfg.badgeOffsetY : 0
        rightMargin:  state.includes("Right") ? cfg.badgeOffsetY : 0
        bottomMargin: state.includes("bottom") ? cfg.badgeOffsetX : 0
    }

    state: position

    states: [
        State {
            name: "topLeft"
            AnchorChanges { target: badge; anchors.top: parent.top; anchors.left: parent.left }
        },
        State {
            name: "topRight"
            AnchorChanges { target: badge; anchors.top: parent.top; anchors.right: parent.right }
        },
        State {
            name: "bottomLeft"
            AnchorChanges { target: badge; anchors.bottom: parent.bottom; anchors.left: parent.left }
        },
        State {
            name: "bottomRight"
            AnchorChanges { target: badge; anchors.bottom: parent.bottom; anchors.right: parent.right }
        }
    ]

    transitions: Transition { AnchorAnimation { duration: 120 } }

    Kirigami.Icon {
        anchors.fill: parent
        source: cfg.ownIconsUI ? Qt.resolvedUrl("../assets/icons/" + iconName + ".svg") : iconName
        color: iconColor
        isMask: cfg.ownIconsUI
    }
}
