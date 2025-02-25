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
    property alias cfg_flatpak: flatpak.checked
    property alias cfg_widgets: widgets.checked

    property alias cfg_newsArch: newsArch.checked
    property alias cfg_newsKDE: newsKDE.checked
    property alias cfg_newsTWIK: newsTWIK.checked
    property alias cfg_newsTWIKA: newsTWIKA.checked
    property alias cfg_newsKeep: newsKeep.value

    property string cfg_middleAction: plasmoid.configuration.middleAction
    property string cfg_rightAction: plasmoid.configuration.rightAction
    property string cfg_scrollUpAction: plasmoid.configuration.scrollUpAction
    property string cfg_scrollDownAction: plasmoid.configuration.scrollDownAction

    property alias cfg_notifyUpdates: notifyUpdates.checked
    property alias cfg_notifyAction: notifyAction.checked
    property alias cfg_notifyEveryBump: notifyEveryBump.checked
    property alias cfg_notifyNews: notifyNews.checked
    property alias cfg_notifyErrors: notifyErrors.checked
    property alias cfg_notifySound: notifySound.checked
    property alias cfg_notifyPersistent: notifyPersistent.checked

    property var cfg: plasmoid.configuration
    property var pkg: plasmoid.configuration.packages
    property var terminals: plasmoid.configuration.terminals
    property var packageLink: "https://archlinux.org/packages/extra/x86_64/pacman-contrib"

    property int currentTab
    signal tabChanged(currentTab: int)
    onCurrentTabChanged: tabChanged(currentTab)

    property bool widgetsAvail: pkg.curl && pkg.jq && pkg.unzip && pkg.tar
    property bool newsAvail: pkg.curl && pkg.jq
    Component.onCompleted: {
        JS.checkDependencies()
        if (arch.checked && !pkg.pacman) arch.checked = plasmoid.configuration.arch = false
        if (aur.checked && (!pkg.pacman || (!pkg.yay && !pkg.paru))) aur.checked = plasmoid.configuration.aur = false
        if (flatpak.checked && !pkg.flatpak) flatpak.checked = plasmoid.configuration.flatpak = false
        if (widgets.checked && !widgetsAvail) widgets.checked = plasmoid.configuration.widgets = false
        if (newsArch.checked && !newsAvail) newsArch.checked = plasmoid.configuration.newsArch = false
        if (newsKDE.checked && !newsAvail) newsKDE.checked = plasmoid.configuration.newsKDE = false
        if (newsTWIK.checked && !newsAvail) newsTWIK.checked = plasmoid.configuration.newsTWIK = false
        if (newsTWIKA.checked && !newsAvail) newsTWIKA.checked = plasmoid.configuration.newsTWIKA = false
    }
 
    header: Kirigami.NavigationTabBar {
        actions: [
            Kirigami.Action {
                icon.name: "search"
                text: i18n("Search")
                checked: currentTab === 0
                onTriggered: currentTab = 0
            },
            Kirigami.Action {
                icon.name: "notification-active"
                text: i18n("Notifications")
                checked: currentTab === 1
                onTriggered: currentTab = 1
            },
            Kirigami.Action {
                icon.name: "followmouse-symbolic"
                text: i18n("Mouse actions")
                checked: currentTab === 2
                onTriggered: currentTab = 2
            },
            Kirigami.Action {
                icon.name: "documentinfo"
                text: i18n("Misc")
                checked: currentTab === 3
                onTriggered: currentTab = 3
            }
        ]
    }

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
                    text: "OK"
                    icon.name: "checkmark"
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
            id: searchTab
            visible: currentTab === 0

            Item {
                Kirigami.FormData.isSection: true
            }

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

                Kirigami.ContextualHelpButton {
                    toolTipText: i18n("The current timer is reset when either of these settings is changed.")
                }
            }

            RowLayout {
                CheckBox {
                    id: checkOnStartup
                    text: i18n("Check on start up")
                    enabled: interval.checked
                }

                Kirigami.ContextualHelpButton {
                    toolTipText: i18n("If the option is <b>enabled</b>, update checking will begin immediately upon widget startup.<br><br>If the option is <b>disabled</b>, update checking will be initiated after a specified time interval has passed since the widget was started. <b>Recommended.</b>")
                }
            }

            Item {
                Kirigami.FormData.isSection: true
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Updates") + ":"

                CheckBox {
                    id: arch
                    text: i18n("Arch Official Repositories")
                    enabled: pkg.pacman
                    onCheckedChanged: if (!checked) aur.checked = false
                }
            }

            RowLayout {
                spacing: Kirigami.Units.gridUnit
                visible: pkg.pacman

                CheckBox {
                    id: aur
                    text: i18n("Arch User Repository") + " (AUR)"
                    enabled: arch.checked && (pkg.paru || pkg.yay)
                }

                Kirigami.UrlButton {
                    url: "https://github.com/exequtic/apdatifier#supported-pacman-wrappers"
                    text: instTip.text
                    font.pointSize: instTip.font.pointSize
                    color: instTip.color
                    visible: !pkg.paru && !pkg.yay
                }
            }

            RowLayout {
                spacing: Kirigami.Units.gridUnit

                CheckBox {
                    id: flatpak
                    text: i18n("Flatpak applications")
                    enabled: pkg.flatpak
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
                    enabled: widgetsAvail
                }

                Kirigami.ContextualHelpButton {
                    toolTipText: i18n("To use this feature, the following installed utilities are required:<br><b>curl, jq, unzip, tar</b>.<br><br>For widget developers:<br>Don't forget to update the metadata.json and specify the name of the applet and its version <b>exactly</b> as they appear on the KDE Store.")
                }
            }

            Item {
                Kirigami.FormData.isSection: true
            }

            RowLayout {
                Kirigami.FormData.label: i18n("News") + ":"

                CheckBox {
                    id: newsArch
                    text: i18n("Arch Linux News")
                    enabled: newsAvail
                }
            }

            CheckBox {
                id: newsKDE
                text: "\"KDE Announcements\""
                enabled: newsAvail
            }

            CheckBox {
                id: newsTWIK
                text: "\"This Week in KDE\""
                enabled: newsAvail
            }

            CheckBox {
                id: newsTWIKA
                text: "\"This Week in KDE Apps\""
                enabled: newsAvail
            }

            RowLayout {
                Label {
                    text: i18n("Keep")
                }

                SpinBox {
                    id: newsKeep
                    from: 1
                    to: 10
                    stepSize: 1
                    value: newsKeep
                    enabled: newsArch.checked || newsKDE.checked || newsTWIK.checked || newsTWIKA.checked
                }

                Label {
                    text: i18np("news item from the feed", "news items from the feed", newsKeep.value)
                }
            }
        }

        Kirigami.FormLayout {
            id: notificationsTab
            visible: currentTab === 1

            Item {
                Kirigami.FormData.isSection: true
            }

            RowLayout {
                spacing: Kirigami.Units.largeSpacing * 2
                CheckBox {
                    Kirigami.FormData.label: i18n("Notifications") + ":"
                    id: notifyUpdates
                    text: i18n("For new updates")
                }
                CheckBox {
                    id: notifyAction
                    text: i18n("Upgrade button")
                    enabled: notifyUpdates.checked
                }
            }

            RowLayout {
                CheckBox {
                    id: notifyEveryBump
                    text: i18n("For every version bump")
                    enabled: notifyUpdates.checked
                }

                Kirigami.ContextualHelpButton {
                    toolTipText: i18n("If the option is <b>enabled</b>, notifications will be sent when a new version of the package is bumped, even if the package is already on the list. <b>More notifications.</b> <br><br>If the option is <b>disabled</b>, notifications will only be sent for packages that are not yet on the list. <b>Less notifications.</b>")
                }
            }

            CheckBox {
                id: notifyNews
                text: i18n("For news")
            }

            CheckBox {
                id: notifyErrors
                text: i18n("For errors")
            }

            CheckBox {
                id: notifySound
                text: i18n("With sound")
                enabled: notifyUpdates.checked || notifyNews.checked || notifyErrors.checked
            }

            CheckBox {
                id: notifyPersistent
                text: i18n("Persistent")
                enabled: notifyUpdates.checked || notifyNews.checked || notifyErrors.checked
            }

            Item {
                Kirigami.FormData.isSection: true
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
                    text: i18n("To further configure, click the button below -> Application Settings -> Apdatifier")
                    wrapMode: Text.WordWrap
                }
            }

            Item {
                Kirigami.FormData.isSection: true
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

        Kirigami.FormLayout {
            id: mouseActionsTab
            visible: currentTab === 2

            Item {
                Kirigami.FormData.isSection: true
            }

            QQC.ComboBox {
                Kirigami.FormData.label: i18n("Middle click") + ":"
                type: "middle"
            }

            QQC.ComboBox {
                Kirigami.FormData.label: i18n("Right click") + ":"
                type: "right"
                Kirigami.ContextualHelpButton {
                    toolTipText: i18n("Do not enable this option if the widget is not used in the system tray; otherwise, you will not be able to open the settings by right-clicking.")
                }
            }

            QQC.ComboBox {
                Kirigami.FormData.label: i18n("Scroll up") + ":"
                type: "scrollUp"
            }

            QQC.ComboBox {
                Kirigami.FormData.label: i18n("Scroll down") + ":"
                type: "scrollDown"
            }

            Item {
                Kirigami.FormData.isSection: true
            }
        }

        Kirigami.FormLayout {
            id: miscTab
            visible: currentTab === 3

            Item {
                Kirigami.FormData.isSection: true
            }

            RowLayout {
                Layout.preferredWidth: miscTab.width - Kirigami.Units.largeSpacing * 10
                Button {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 500
                    icon.name: "backup"
                    text: i18n("Restore hidden tooltips")
                    onClicked: {
                        plasmoid.configuration.configMsg = true
                        plasmoid.configuration.rulesMsg = true
                        plasmoid.configuration.newsMsg = true
                        plasmoid.configuration.version = "v0"
                    }
                }
            }

            RowLayout {
                Layout.preferredWidth: miscTab.width - Kirigami.Units.largeSpacing * 10
                Button {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 500

                    icon.name: "install"
                    icon.color: Kirigami.Theme.negativeTextColor
                    text: i18n("Install development version")
                    onClicked: {
                        JS.execute(JS.runInTerminal("utils", "install"))
                    }
                }
            }
        }
    }
}
