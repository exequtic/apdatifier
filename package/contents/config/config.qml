/*
    SPDX-FileCopyrightText: 2023 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick 2.6
import org.kde.plasma.configuration 2.0

ConfigModel {
	ConfigCategory {
		name: i18n("General")
		icon: "preferences-desktop"
		source: "ConfigGeneral.qml"
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
