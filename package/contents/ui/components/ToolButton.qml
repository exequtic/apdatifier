/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components
import org.kde.kirigami as Kirigami

ToolButton {
    id: root

    property alias color: icon.color
    property alias tooltipText: tooltip.text

    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium

    hoverEnabled: enabled
    highlighted: enabled

    Kirigami.Icon {
        id: icon
        height: parent.height
        width: parent.height
        anchors.centerIn: parent
        source: cfg.ownIconsUI ? Qt.resolvedUrl("../assets/icons/" + root.icon.source + ".svg") : root.icon.source
        color: Kirigami.Theme.colorSet
        scale: cfg.ownIconsUI ? 0.7 : 0.9
        isMask: cfg.ownIconsUI
        smooth: true
    }

    ToolTip {
        id: tooltip
        text: ""
    }
}
