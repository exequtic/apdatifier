/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.kirigami as Kirigami
import "../../tools/tools.js" as JS

Rectangle {
    id: root

    property int position: 0
    property var iconName: ""
    property var iconColor: ""

    width: badgeSize
    height: badgeSize
    radius: width / 2
    color: cfg.counterColor ? cfg.counterColor : Kirigami.Theme.backgroundColor

    anchors.top: JS.setAnchor("top", position)
    anchors.bottom: JS.setAnchor("bottom", position)
    anchors.right: JS.setAnchor("right", position)
    anchors.left: JS.setAnchor("left", position)

    Kirigami.Icon {
        id: badgeIcon
        anchors.fill: root
        width: badgeSize
        height: badgeSize
        source: cfg.ownIconsUI ? Qt.resolvedUrl("../assets/icons/" + iconName + ".svg") : iconName
        color: iconColor
        isMask: cfg.ownIconsUI
    }
}
