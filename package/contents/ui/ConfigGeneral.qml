/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.kcmutils
import org.kde.kirigami as Kirigami

import "../tools/tools.js" as JS

SimpleKCM {
    id: root

    property alias cfg_interval: interval.checked
    property alias cfg_time: time.value
    property alias cfg_checkOnStartup: checkOnStartup.checked

    property alias cfg_aur: aur.checked
    property alias cfg_flatpak: flatpak.checked

    property string cfg_wrapper: plasmoid.configuration.wrapper

    property alias cfg_notifications: notifications.checked
    property alias cfg_withSound: withSound.checked

    property string cfg_middleClick: plasmoid.configuration.middleClick
    property string cfg_rightClick: plasmoid.configuration.rightClick

    property var pkg: plasmoid.configuration.packages
    property var wrappers: plasmoid.configuration.wrappers
    property var terminals: plasmoid.configuration.terminals

    Kirigami.FormLayout {
        id: generalPage

        RowLayout {
            Kirigami.FormData.label: i18n("Interval:")

            CheckBox {
                id: interval
            }

            SpinBox {
                id: time
                from: 1
                to: 1440
                stepSize: 5
                value: time
                enabled: interval.checked
            }

            Label {
                text: i18n("minutes")
            }
        }

        CheckBox {
            id: checkOnStartup
            text: "Check on start up"
            enabled: interval.checked
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Search:")

            spacing: Kirigami.Units.gridUnit

            CheckBox {
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

            Label {
                font.pointSize: tip.font.pointSize
                color: Kirigami.Theme.positiveTextColor
                text: i18n("found: %1", cfg_wrapper)
                visible: aur.checked && wrappers.length == 1
            }
        }

        RowLayout {
            spacing: Kirigami.Units.gridUnit

            CheckBox {
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

        Item {
            Kirigami.FormData.isSection: true
            visible: aur.checked && wrappers.length > 1
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Wrapper:")

            ComboBox {
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
            Label {
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
            Kirigami.FormData.label: "Mouse actions:"

            ComboBox {
                implicitWidth: 150
                textRole: "name"
                model: [{"name": "None", "value": ""},
                        {"name": "Check updates", "value": "checkUpdates"},
                        {"name": "Upgrade system", "value": "upgradeSystem"},
                        {"name": "Switch interval", "value": "switchInterval"}]

                onCurrentIndexChanged: {
                    cfg_middleClick = model[currentIndex]["value"]
                }

                Component.onCompleted: {
                    currentIndex = JS.setIndex(plasmoid.configuration.middleClick, model)
                }
            }

            Label {
                text: "for middle button"
            }
        }

        RowLayout {
            ComboBox {
                implicitWidth: 150
                textRole: "name"
                model: [{"name": "Default", "value": ""},
                        {"name": "Check updates", "value": "checkUpdates"},
                        {"name": "Upgrade system", "value": "upgradeSystem"},
                        {"name": "Switch interval", "value": "switchInterval"}]

                onCurrentIndexChanged: {
                    cfg_rightClick = model[currentIndex]["value"]
                }

                Component.onCompleted: {
                    currentIndex = JS.setIndex(plasmoid.configuration.rightClick, model)
                }
            }

            Label {
                text: "for right button"
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Notifications:")

            CheckBox {
                id: notifications
                text: i18n("Popup")
            }
        }

        CheckBox {
            id: withSound
            text: i18n("Sound")
            enabled: notifications.checked
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        RowLayout {
            id: notifyTip

            Label {
                horizontalAlignment: Text.AlignHCenter
                Layout.maximumWidth: 250
                font.pointSize: tip.font.pointSize
                text: i18n("To further configure, click the button below -> Application-specific settings -> Apdatifier")
                wrapMode: Text.WordWrap
            }
        }

        Button {
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
}