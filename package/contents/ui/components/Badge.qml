/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.kirigami as Kirigami
import "../../tools/tools.js" as JS

Rectangle {
    property var position: 0
    property var iconName: ""
    property var iconColor: ""

    width: (counterOverlay ? trayIconSize : panelIcon.width) / 3
    height: width
    radius: width / 2
    color: cfg.counterColor ? cfg.counterColor : Kirigami.Theme.backgroundColor

    anchors {
        top: counterOverlay ? JS.setAnchor("top", position) : panelIcon.top
        bottom: counterOverlay ? JS.setAnchor("bottom", position) : undefined
        right: counterOverlay ? JS.setAnchor("right", position) : (position === "right" ? panelIcon.right : undefined)
        left: counterOverlay ? JS.setAnchor("left", position) : (position === "left" ? panelIcon.left : undefined)

        topMargin: counterOverlay ? 0 : 5
        bottomMargin: counterOverlay ? 0 : 0
        leftMargin: counterOverlay ? 0 : -1
        rightMargin: counterOverlay ? 0 : -1
    }

    Kirigami.Icon {
        anchors.fill: parent
        source: cfg.ownIconsUI ? Qt.resolvedUrl("../assets/icons/" + iconName + ".svg") : iconName
        color: iconColor
        isMask: cfg.ownIconsUI
    }
}
