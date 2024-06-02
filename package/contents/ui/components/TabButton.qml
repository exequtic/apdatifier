/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components
import org.kde.kirigami as Kirigami

TabButton {
    id: root

    contentItem: RowLayout {
        Kirigami.Theme.inherit: true

        Item { Layout.fillWidth: true }
        Kirigami.Icon {
            Layout.preferredHeight: height
            height: Kirigami.Units.iconSizes.small
            source: cfg.ownIconsUI ? Qt.resolvedUrl("../assets/icons/" + root.icon.source + ".svg") : root.icon.source
            color: Kirigami.Theme.colorSet
            isMask: cfg.ownIconsUI
            smooth: true
        }
        Item { Layout.fillWidth: true }
    }
}
