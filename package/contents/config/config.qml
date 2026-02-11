import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop"
        source: "configuration/General.qml"
    }

    ConfigCategory {
         name: i18n("Upgrade & Management")
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
         icon: "donate"
         source: "configuration/Support.qml"
    }
}
