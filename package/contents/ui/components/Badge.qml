/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    property var iconName: ""
    property var iconColor: ""
    property bool pauseBadge: iconName === pausedIcon

    function setAnchor(anchor) {
        if (counterRow) {
            var topLeft = { top: parent.top, bottom: undefined, left: parent.left, right: undefined }
            var topRight = { top: parent.top, bottom: undefined, left: undefined, right: parent.right }
            var positions = pauseBadge ? topLeft : topRight
        } else {
            var normal = {
                top:    (cfg.counterTop && !cfg.counterBottom) ? parent.top : undefined,
                bottom: (cfg.counterBottom && !cfg.counterTop) ? parent.bottom : undefined,
                left:   (cfg.counterLeft && !cfg.counterRight) ? parent.left : undefined,
                right:  (cfg.counterRight && !cfg.counterLeft) ? parent.right : undefined            
            }
            var reverse = {
                top:    (cfg.counterBottom && !cfg.counterTop) ? parent.top : undefined,
                bottom: (cfg.counterTop && !cfg.counterBottom) ? parent.bottom : undefined,
                left:   (cfg.counterRight && !cfg.counterLeft) ? parent.left : undefined,
                right:  (cfg.counterLeft && !cfg.counterRight) ? parent.right : undefined
            }
            var positions = pauseBadge ? reverse : normal
        }

        return positions[anchor]
    }


    width: (counterOverlay ? trayIconSize : parent.width) / 3
    height: width
    radius: width / 2
    color: cfg.counterColor ? cfg.counterColor : Kirigami.Theme.backgroundColor

    anchors {
        top:    setAnchor("top")
        bottom: setAnchor("bottom")
        left:   setAnchor("left")
        right:  setAnchor("right")

        topMargin:    counterOverlay ? 0 : 5
        bottomMargin: counterOverlay ? 0 : 0
        leftMargin:   counterOverlay ? 0 : -1
        rightMargin:  counterOverlay ? 0 : -1
    }

    Kirigami.Icon {
        anchors.fill: parent
        source: cfg.ownIconsUI ? Qt.resolvedUrl("../assets/icons/" + iconName + ".svg") : iconName
        color: iconColor
        isMask: cfg.ownIconsUI
    }
}
