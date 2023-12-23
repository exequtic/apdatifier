import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.5 as QQC2
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons
import "../tools/tools.js" as JS

Kirigami.FormLayout {
    id: generalPage

    property alias cfg_interval: interval.checked
    property alias cfg_time: time.value

    property alias cfg_pacman: pacman.checked
    property alias cfg_checkupdates: checkupdates.checked
    property alias cfg_wrapper: wrapper.checked
    property string cfg_selectedWrapper: plasmoid.configuration.selectedWrapper

    property alias cfg_flatpak: flatpak.checked

    property alias cfg_wrapperUpgrade: wrapperUpgrade.checked
    property alias cfg_upgradeFlags: upgradeFlags.checked
    property alias cfg_upgradeFlagsText: upgradeFlagsText.text
    property string cfg_selectedTerminal: plasmoid.configuration.selectedTerminal

    property alias cfg_notifications: notifications.checked
    property alias cfg_withSound: withSound.checked
    property alias cfg_notifyStartup: notifyStartup.checked

    property alias cfg_debugging: debugging.checked

    property var packages: plasmoid.configuration.packages
    property var wrappers: plasmoid.configuration.wrappers
    property var terminals: plasmoid.configuration.terminals

    RowLayout {
        Kirigami.FormData.label: i18n("Interval:")

        QQC2.CheckBox {
            id: interval
        }

        QQC2.SpinBox {
            id: time
            from: 10
            to: 1440
            stepSize: 5
            value: time
            enabled: interval.checked
        }

        QQC2.Label {
            text: i18n("minutes")
        }
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Search:")

        spacing: 10

        QQC2.CheckBox {
            id: flatpak
            text: i18n("Enable Flatpak support")
            enabled: packages[3]

            Component.onCompleted: {
                if (checked && !packages[3]) {
                    checked = false
                    plasmoid.configuration.flatpak = checked
                }
            }
        }

        QQC2.Label {
            font.pixelSize: tip.font.pixelSize
            text: "<a href=\"https://flathub.org/setup\" style=\"color: " + Kirigami.Theme.neutralTextColor + "\">" + notInst.text + "</a>"
            textFormat: Text.RichText
            onLinkActivated: Qt.openUrlExternally(link)
            enabled: visible
            visible: !packages[3]
        }
    }

    RowLayout {
        QQC2.ButtonGroup { id: searchGroup }

        QQC2.RadioButton {
            id: pacman
            text: "pacman"
            checked: true
            QQC2.ButtonGroup.group: searchGroup
        }

        visible: packages[1]
    }

    RowLayout {
        spacing: 10

        QQC2.RadioButton {
            id: checkupdates
            text: "checkupdates"
            enabled: packages[2]
            QQC2.ButtonGroup.group: searchGroup
        }

        QQC2.Label {
            id: tip
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize - 4
            text: "<a href=\"https://archlinux.org/packages/extra/x86_64/pacman-contrib\" style=\"color: " + Kirigami.Theme.neutralTextColor + "\">" + notInst.text + "</a>"
            textFormat: Text.RichText
            onLinkActivated: Qt.openUrlExternally(link)
            enabled: visible
            visible: !packages[2]
        }

        visible: packages[1]
    }

    RowLayout {
        spacing: 10

        QQC2.RadioButton {
            id: wrapper
            text: i18n("pacman wrapper")
            enabled: !wrappers ? false : true
            QQC2.ButtonGroup.group: searchGroup
        }

        QQC2.Label {
            font.pixelSize: tip.font.pixelSize
            text: "<a href=\"https://wiki.archlinux.org/title/AUR_helpers#Pacman_wrappers\" style=\"color: " + Kirigami.Theme.neutralTextColor + "\">" + notInst.text + "</a>"
            textFormat: Text.RichText
            onLinkActivated: Qt.openUrlExternally(link)
            visible: !wrappers
            enabled: visible
        }

        QQC2.Label {
            font.pixelSize: tip.font.pixelSize
            color: Kirigami.Theme.positiveTextColor
            text: i18n("found: %1", cfg_selectedWrapper)
            visible: wrapper.checked && wrappers.length == 1
            enabled: visible
        }

        visible: packages[1]
    }

    QQC2.ComboBox {
        model: wrappers
        textRole: "name"
        enabled: wrappers
        implicitWidth: 150
        visible: wrappers && wrappers.length > 1

        onCurrentIndexChanged: {
            cfg_selectedWrapper = model[currentIndex]["value"]
        }

        Component.onCompleted: {
            if (wrappers) {
                currentIndex = JS.setIndex(plasmoid.configuration.selectedWrapper, wrappers)
            }
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
        visible: packages[1]
    }

    RowLayout {
        QQC2.Label {
            Layout.maximumWidth: 250
            font.pixelSize: tip.font.pixelSize
            text: i18n("If you rarely update local repository databases and don't need AUR support, it is highly recommended to use checkupdates.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        visible: packages[1]
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Upgrade:")

        QQC2.ComboBox {
            model: terminals
            textRole: "name"
            enabled: terminals
            implicitWidth: 150

            onCurrentIndexChanged: {
                cfg_selectedTerminal = model[currentIndex]["value"]
            }

            Component.onCompleted: {
                if (terminals) {
                    currentIndex = JS.setIndex(plasmoid.configuration.selectedTerminal, terminals)
                }

                if (!plasmoid.configuration.selectedTerminal) {
                    plasmoid.configuration.selectedTerminal = model[0]["value"]
                }
            }
        }

        QQC2.Label {
            id: notInst
            font.pixelSize: tip.font.pixelSize
            color: Kirigami.Theme.neutralTextColor
            text: "Not installed"
            enabled: visible
            visible: !terminals
        }
    }

    QQC2.CheckBox {
        id: wrapperUpgrade
        text: i18n("Use wrapper instead of pacman")
        enabled: terminals &&
                 wrappers &&
                 cfg_selectedWrapper
        visible: packages[1]
    }

    QQC2.CheckBox {
        id: upgradeFlags
        text: i18n("Additional flags")
        enabled: terminals
        visible: packages[1]
    }

    QQC2.TextField {
        id: upgradeFlagsText
        placeholderText: i18n(" only flags, without -Syu")
        placeholderTextColor: "grey"
        visible: packages[1] && upgradeFlags.checked
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Notifications:")

        QQC2.CheckBox {
            id: notifications
            text: i18n("Popup")
        }
    }

    QQC2.CheckBox {
        id: withSound
        text: i18n("Sound")
        enabled: notifications.checked
    }

    QQC2.CheckBox {
        id: notifyStartup
        text: i18n("Notify on startup")
        enabled: notifications.checked
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    RowLayout {
        id: notifyTip

        QQC2.Label {
            horizontalAlignment: Text.AlignHCenter
            Layout.maximumWidth: 250
            font.pixelSize: tip.font.pixelSize
            text: i18n("To further configure, click the button below -> Application-specific settings -> Apdatifier")
            wrapMode: Text.WordWrap
        }
    }

    QQC2.Button {
        anchors.horizontalCenter: notifyTip.horizontalCenter
        enabled: notifications.checked
        icon.name: "settings-configure"
        text: i18n("Configure...")
        onClicked: KQuickAddons.KCMShell.openSystemSettings("kcm_notifications")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        Kirigami.FormData.label: i18n("Debug mode:")
        id: debugging
        text: i18n("Print debug info in console")
    }

    Item {
        Kirigami.FormData.isSection: true
    }
}
