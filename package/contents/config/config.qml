import QtQuick 2.6
import org.kde.plasma.configuration 2.0

ConfigModel {
	ConfigCategory {
		name: "General"
		icon: "preferences-desktop"
		source: "ConfigGeneral.qml"
	}

    ConfigCategory {
         name: "Appearance"
         icon: "preferences-desktop-display-color"
         source: "ConfigAppearance.qml"
    }
}
