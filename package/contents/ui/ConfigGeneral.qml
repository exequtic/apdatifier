/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kcmutils
import org.kde.kirigami as Kirigami

import "../tools/tools.js" as JS

Kirigami.FormLayout {
    id: generalPage

    property alias cfg_interval: interval.checked
    property alias cfg_time: time.value

    property alias cfg_aur: aur.checked
    property alias cfg_flatpak: flatpak.checked

    property string cfg_selectedWrapper: plasmoid.configuration.selectedWrapper

    property alias cfg_wrapperUpgrade: wrapperUpgrade.checked
    property alias cfg_upgradeFlags: upgradeFlags.checked
    property alias cfg_upgradeFlagsText: upgradeFlagsText.text
    property string cfg_selectedTerminal: plasmoid.configuration.selectedTerminal

    property alias cfg_notifications: notifications.checked
    property alias cfg_withSound: withSound.checked
    property alias cfg_notifyStartup: notifyStartup.checked

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

        spacing: Kirigami.Units.gridUnit

        QQC2.CheckBox {
            id: aur
            text: i18n("AUR")
            enabled: wrappers
        }

        Kirigami.UrlButton {
            url: "https://github.com/exequtic/apdatifier#supported-pacman-wrappers"
            text: instTip.text
            font.pointSize: tip.font.pointSize
            color: instTip.color
            visible: !wrappers
        }

        QQC2.Label {
            font.pointSize: tip.font.pointSize
            color: Kirigami.Theme.positiveTextColor
            text: i18n("found: %1", cfg_selectedWrapper)
            visible: aur.checked && wrappers.length == 1
        }
    }

    RowLayout {
        spacing: Kirigami.Units.gridUnit

        QQC2.CheckBox {
            id: flatpak
            text: i18n("Flatpak")
            enabled: packages[3]

            Component.onCompleted: {
                if (checked && !packages[3]) {
                    checked = false
                    plasmoid.configuration.flatpak = checked
                }
            }
        }

        Kirigami.UrlButton {
            id: instTip
            url: "https://flathub.org/setup"
            text: i18n("Not installed")
            font.pointSize: tip.font.pointSize
            color: Kirigami.Theme.neutralTextColor
            visible: !packages[3]
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Wrapper:")

        QQC2.ComboBox {
            model: wrappers
            textRole: "name"
            enabled: wrappers
            implicitWidth: 150

            onCurrentIndexChanged: {
                cfg_selectedWrapper = model[currentIndex]["value"]
            }

            Component.onCompleted: {
                if (wrappers) {
                    currentIndex = JS.setIndex(plasmoid.configuration.selectedWrapper, wrappers)
                }
            }
        }

        visible: aur.checked && wrappers.length > 1
    }

    Kirigami.Separator {
        Layout.fillWidth: true
        visible: !packages[2]
    }

    RowLayout {
        visible: !packages[2]
        QQC2.Label {
            id: tip
            Layout.maximumWidth: 250
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: Kirigami.Theme.neutralTextColor
            text: i18n("Package 'pacman-contrib' not installed! Highly recommended to install it for getting the latest updates without the need to download fresh package databases.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
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

                    if (!plasmoid.configuration.selectedTerminal) {
                        plasmoid.configuration.selectedTerminal = model[0]["value"]
                    }
                }
            }
        }

        Kirigami.UrlButton {
            url: "https://github.com/exequtic/apdatifier#supported-terminals"
            text: instTip.text
            font.pointSize: tip.font.pointSize
            color: instTip.color
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
            font.pointSize: tip.font.pointSize
            text: i18n("To further configure, click the button below -> Application-specific settings -> Apdatifier")
            wrapMode: Text.WordWrap
        }
    }

    QQC2.Button {
        anchors.horizontalCenter: notifyTip.horizontalCenter
        enabled: notifications.checked
        icon.name: "settings-configure"
        text: i18n("Configure...")
        onClicked: KCMLauncher.openSystemSettings("kcm_notifications")
    }

    Item {
        Kirigami.FormData.isSection: true
    }
}
