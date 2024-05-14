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
        source: cfg.iconsThemeUI ? root.icon.source : Qt.resolvedUrl("../assets/icons/" + root.icon.source + ".svg")
        color: Kirigami.Theme.colorSet
        opacity: cfg.iconsThemeUI ? 1 : (enabled ? 1 : 0.6)
        scale: cfg.iconsThemeUI ? 0.9 : 0.7
        isMask: cfg.iconsThemeUI ? false : true
        smooth: true
    }

    ToolTip {
        id: tooltip
        text: ""
    }
}
