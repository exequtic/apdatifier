/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop"
        source: "ConfigGeneral.qml"
    }

    ConfigCategory {
         name: i18n("Mirrors")
         icon: "ksmserver"
         source: "ConfigMirrors.qml"
    }

    ConfigCategory {
         name: i18n("Appearance")
         icon: "preferences-desktop-display-color"
         source: "ConfigAppearance.qml"
    }

    ConfigCategory {
         name: i18n("Support author")
         icon: "system-help"
         source: "ConfigSupport.qml"
    }
}
