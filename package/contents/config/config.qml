/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop"
        source: "configuration/General.qml"
    }

    ConfigCategory {
         name: i18n("Upgrade")
         icon: "preferences-system-startup"
         source: "configuration/Upgrade.qml"
    }

    ConfigCategory {
         name: i18n("Appearance")
         icon: "preferences-desktop-display-color"
         source: "configuration/Appearance.qml"
    }

    ConfigCategory {
         name: i18n("Rules")
         icon: "preferences-system-windows-behavior"
         source: "configuration/Rules.qml"
    }

    ConfigCategory {
         name: i18n("Support me")
         icon: "starred-symbolic"
         source: "configuration/Support.qml"
    }
}
