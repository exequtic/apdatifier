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

SimpleKCM {
    id: root

    property alias cfg_interval: interval.checked
    property alias cfg_time: time.value

    property alias cfg_aur: aur.checked
    property alias cfg_flatpak: flatpak.checked

    property string cfg_wrapper: plasmoid.configuration.wrapper

    property alias cfg_wrapperUpgrade: wrapperUpgrade.checked
    property alias cfg_upgradeFlags: upgradeFlags.checked
    property alias cfg_upgradeFlagsText: upgradeFlagsText.text
    property string cfg_terminal: plasmoid.configuration.terminal

    property alias cfg_notifications: notifications.checked
    property alias cfg_withSound: withSound.checked

    property string cfg_middleClick: plasmoid.configuration.middleClick

    property var pkg: plasmoid.configuration.packages
    property var wrappers: plasmoid.configuration.wrappers
    property var terminals: plasmoid.configuration.terminals

    Kirigami.FormLayout {
        id: generalPage

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
                enabled: pkg.pacman && wrappers
            }

            Kirigami.UrlButton {
                url: "https://github.com/exequtic/apdatifier#supported-pacman-wrappers"
                text: instTip.text
                font.pointSize: tip.font.pointSize
                color: instTip.color
                visible: pkg.pacman && !wrappers
            }

            QQC2.Label {
                font.pointSize: tip.font.pointSize
                color: Kirigami.Theme.positiveTextColor
                text: i18n("found: %1", cfg_wrapper)
                visible: aur.checked && wrappers.length == 1
            }
        }

        RowLayout {
            spacing: Kirigami.Units.gridUnit

            QQC2.CheckBox {
                id: flatpak
                text: i18n("Flatpak")
                enabled: pkg.flatpak

                Component.onCompleted: {
                    if (checked && !pkg.flatpak) {
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
                visible: !pkg.flatpak
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
                    cfg_wrapper = model[currentIndex]["value"]
                }

                Component.onCompleted: {
                    if (wrappers) {
                        currentIndex = JS.setIndex(plasmoid.configuration.wrapper, wrappers)
                    }
                }
            }

            visible: aur.checked && wrappers.length > 1
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            visible: !pkg.checkupdates
        }

        RowLayout {
            visible: pkg.pacman && !pkg.checkupdates
            QQC2.Label {
                id: tip
                Layout.maximumWidth: 250
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                color: Kirigami.Theme.neutralTextColor
                text: i18n("pacman-contrib not installed! Highly recommended to install it for getting the latest updates without the need to download fresh package databases.")
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
                    cfg_terminal = model[currentIndex]["value"]
                }

                Component.onCompleted: {
                    if (terminals) {
                        currentIndex = JS.setIndex(plasmoid.configuration.terminal, terminals)

                        if (!plasmoid.configuration.terminal) {
                            plasmoid.configuration.terminal = model[0]["value"]
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
            enabled: terminals && wrappers && cfg_wrapper
            visible: pkg.pacman
        }

        QQC2.CheckBox {
            id: upgradeFlags
            text: i18n("Additional flags")
            enabled: terminals
            visible: pkg.pacman
        }

        QQC2.TextField {
            id: upgradeFlagsText
            placeholderText: i18n(" only flags, without -Syu")
            placeholderTextColor: "grey"
            visible: pkg.pacman && upgradeFlags.checked
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

        RowLayout {
            Kirigami.FormData.label: "Middle-button:"

            QQC2.ComboBox {
                implicitWidth: 150
                textRole: "name"
                model: [{"name": "Nothing", "value": ""},
                        {"name": "Check updates", "value": "checkUpdates"},
                        {"name": "Upgrade system", "value": "upgradeSystem"}]

                onCurrentIndexChanged: {
                    cfg_middleClick = model[currentIndex]["value"]
                }

                Component.onCompleted: {
                    currentIndex = JS.setIndex(plasmoid.configuration.middleClick, model)
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }
    }
}