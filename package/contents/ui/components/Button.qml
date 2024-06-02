/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.ksvg
import org.kde.kirigami as Kirigami

Button {
    id: customButton

    property alias iconName: icon.source
    property alias tooltipText: tooltip.text
    property alias iconSize: icon.width
    property alias frameSize: customButton.implicitWidth

    implicitWidth: iconSize * 2
    implicitHeight: implicitWidth
    hoverEnabled: true

    Kirigami.Icon {
        id: icon
        anchors.centerIn: parent
        height: width
    }

    ToolTip {
        id: tooltip
        text: ""
        delay: Kirigami.Units.toolTipDelay
        visible: customButton.hovered
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
