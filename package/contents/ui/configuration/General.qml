/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.kcmutils
import org.kde.kirigami as Kirigami

import "../components" as QQC
import "../../tools/tools.js" as JS

SimpleKCM {
    property alias cfg_interval: interval.checked
    property alias cfg_time: time.value
    property alias cfg_checkOnStartup: checkOnStartup.checked

    property alias cfg_arch: arch.checked
    property alias cfg_aur: aur.checked
    property alias cfg_archNews: archNews.checked
    property alias cfg_flatpak: flatpak.checked
    property alias cfg_widgets: widgets.checked
    property string cfg_wrapper: plasmoid.configuration.wrapper

    property string cfg_middleAction: plasmoid.configuration.middleAction
    property string cfg_rightAction: plasmoid.configuration.rightAction
    property string cfg_scrollUpAction: plasmoid.configuration.scrollUpAction
    property string cfg_scrollDownAction: plasmoid.configuration.scrollDownAction

    property alias cfg_notifyUpdates: notifyUpdates.checked
    property alias cfg_notifyErrors: notifyErrors.checked
    property alias cfg_notifySound: notifySound.checked
    property alias cfg_notifyEveryBump: notifyEveryBump.checked
    property alias cfg_notifyPersistent: notifyPersistent.checked

    property var pkg: plasmoid.configuration.packages
    property var wrappers: plasmoid.configuration.wrappers
    property var terminals: plasmoid.configuration.terminals
    property var packageLink: "https://archlinux.org/packages/extra/x86_64/pacman-contrib"

    ColumnLayout {
        Kirigami.InlineMessage {
            id: configMsg
            Layout.fillWidth: true
            icon.source: "document-save"
            text: "<b>" + i18n("Configuration is automatically saved in a config file and loaded at every startup, ensuring you never lose your settings. The config file is stored in ") + "~/.config/apdatifier" + "</b>"
            type: Kirigami.MessageType.Positive
            visible: plasmoid.configuration.configMsg

            actions: [
                Kirigami.Action {
                    text: i18n("Dismiss")
                    icon.name: "dialog-close"
                    onTriggered: plasmoid.configuration.configMsg = false
                }
            ]
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            icon.source: "apdatifier-package"
            text: "<b>" + "<a href=\"" + packageLink + "\">checkupdates</a>" + i18n(" not installed! Highly recommended to install it for getting the latest updates without the need to download fresh package databases.") + "</b>"
            type: Kirigami.MessageType.Error
            onLinkActivated: Qt.openUrlExternally(packageLink)
            visible: !pkg.checkupdates
        }

        Kirigami.FormLayout {
            id: generalPage

            RowLayout {
                Kirigami.FormData.label: i18n("Interval") + ":"

                CheckBox {
                    id: interval
                }

                SpinBox {
                    id: time
                    from: 15
                    to: 1440
                    stepSize: 5
                    value: time
                    enabled: interval.checked
                }

                Label {
                    text: i18n("minutes")
                }

                ContextualHelpButton {
                    toolTipText: i18n("The current timer is reset when either of these settings is changed.")
                }
            }

            RowLayout {
                CheckBox {
                    id: checkOnStartup
                    text: i18n("Check on start up")
                    enabled: interval.checked
                }

                ContextualHelpButton {
                    toolTipText: i18n("If the option is <b>enabled</b>, update checking will begin immediately upon widget startup.<br><br>If the option is <b>disabled</b>, update checking will be initiated after a specified time interval has passed since the widget was started. <b>Recommended.</b>")
                }
            }

            Item {
                Kirigami.FormData.isSection: true
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Search") + ":"

                CheckBox {
                    id: arch
                    text: i18n("Arch Official Repositories")
                    enabled: pkg.pacman

                    Component.onCompleted: {
                        if (checked && !pkg.pacman) {
                            checked = false
                            cfg_arch = checked
                        }
                    }
                }
            }

            RowLayout {
                spacing: Kirigami.Units.gridUnit
                visible: pkg.pacman

                CheckBox {
                    id: aur
                    text: i18n("Arch User Repository")
                    enabled: arch.checked && pkg.pacman && wrappers

                    Component.onCompleted: {
                        if (checked && !wrappers) {
                            checked = false
                            cfg_aur = checked
                        }
                    }
                }

                Kirigami.UrlButton {
                    url: "https://github.com/exequtic/apdatifier#supported-pacman-wrappers"
                    text: instTip.text
                    font.pointSize: instTip.font.pointSize
                    color: instTip.color
                    visible: pkg.pacman && !wrappers
                }
            }

            RowLayout {
                visible: pkg.pacman

                CheckBox {
                    id: archNews
                    text: i18n("Arch Linux News")
                    enabled: pkg.pacman && wrappers
                }

                ContextualHelpButton {
                    toolTipText: i18n("It is necessary to have paru or yay installed.")
                }
            }

            RowLayout {
                spacing: Kirigami.Units.gridUnit

                CheckBox {
                    id: flatpak
                    text: i18n("Flatpak applications")
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
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: Kirigami.Theme.neutralTextColor
                    visible: !pkg.flatpak
                }
            }

            RowLayout {
                CheckBox {
                    id: widgets
                    text: i18n("Plasma Widgets")
                }

                ContextualHelpButton {
                    toolTipText: i18n("To use this feature, the following installed utilities are required:<br><b>curl, jq, xmlstarlet, unzip, tar</b>.<br><br>For widget developers:<br>Don't forget to update the metadata.json and specify the name of the applet and its version <b>exactly</b> as they appear on the KDE Store.")
                }
            }

            Item {
                Kirigami.FormData.isSection: true
                visible: aur.checked
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Wrapper") + ":"
                visible: aur.checked

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
                        } else {
                            plasmoid.configuration.wrapper = ""
                        }
                    }
                }
            }

            Item {
                Kirigami.FormData.isSection: true
            }

            QQC.ComboBox {
                Kirigami.FormData.label: i18n("Mouse actions") + ":"
                type: "middle"
                labelText: i18n("middle click")
            }
            QQC.ComboBox {
                type: "right"
                labelText: i18n("right click")
            }
            QQC.ComboBox {
                type: "scrollUp"
                labelText: i18n("scroll up")
            }
            QQC.ComboBox {
                type: "scrollDown"
                labelText: i18n("scroll down")
            }

            Item {
                Kirigami.FormData.isSection: true
            }

            CheckBox {
                Kirigami.FormData.label: i18n("Notifications") + ":"
                id: notifyUpdates
                text: i18n("For new updates and news")
            }

            RowLayout {
                CheckBox {
                    id: notifyEveryBump
                    text: i18n("For every version bump")
                    enabled: notifyUpdates.checked
                }

                ContextualHelpButton {
                    toolTipText: i18n("If the option is <b>enabled</b>, notifications will be sent when a new version of the package is bumped, even if the package is already on the list. <b>More notifications.</b> <br><br>If the option is <b>disabled</b>, notifications will only be sent for packages that are not yet on the list. <b>Less notifications.</b>")
                }
            }

            CheckBox {
                id: notifyErrors
                text: i18n("For errors")
            }

            CheckBox {
                id: notifySound
                text: i18n("With sound")
                enabled: notifyUpdates.checked || notifyErrors.checked
            }

            CheckBox {
                id: notifyPersistent
                text: i18n("Persistent")
                enabled: notifyUpdates.checked || notifyErrors.checked
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            RowLayout {
                id: notifyTip

                Label {
                    horizontalAlignment: Text.AlignHCenter
                    Layout.maximumWidth: 250
                    font.pointSize: instTip.font.pointSize
                    text: i18n("To further configure, click the button below -> Application-specific settings -> Apdatifier")
                    wrapMode: Text.WordWrap
                }
            }

            Button {
                anchors.horizontalCenter: notifyTip.horizontalCenter
                enabled: notifyUpdates.checked || notifyErrors.checked
                icon.name: "settings-configure"
                text: i18n("Configure...")
                onClicked: KCMLauncher.openSystemSettings("kcm_notifications")
            }

            Item {
                Kirigami.FormData.isSection: true
            }
        }
    }
}
