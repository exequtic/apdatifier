/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

import org.kde.kcmutils
import org.kde.kirigami as Kirigami

import "../components" as QQC
import "../../tools/tools.js" as JS

SimpleKCM {
    property string cfg_checkMode: plasmoid.configuration.checkMode
    property alias cfg_intervalMinutes: intervalMinutes.value
    property alias cfg_dailyHour: dailyHour.value
    property alias cfg_dailyMinute: dailyMinute.value
    property alias cfg_weeklyDay: weeklyDay.currentIndex
    property alias cfg_weeklyHour: weeklyHour.value
    property alias cfg_weeklyMinute: weeklyMinute.value

    property alias cfg_arch: arch.checked
    property alias cfg_aur: aur.checked
    property alias cfg_flatpak: flatpak.checked
    property alias cfg_fwupd: fwupd.checked
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
    property alias cfg_notifyUpdatesAction: notifyUpdatesAction.checked
    property alias cfg_notifyEveryBump: notifyEveryBump.checked
    property alias cfg_notifyNews: notifyNews.checked
    property alias cfg_notifyNewsAction: notifyNewsAction.checked
    property alias cfg_notifyErrors: notifyErrors.checked
    property alias cfg_notifySound: notifySound.checked
    property alias cfg_notifyPersistent: notifyPersistent.checked

    property var cfg: plasmoid.configuration
    property var pkg: plasmoid.configuration.packages
    property var terminals: plasmoid.configuration.terminals
    property alias cfg_dbPath: dbPath.text

    property int installButton
    property var dialogTitles: {
        "0": i18n("Install Development version"),
        "1": i18n("Install Stable version"),
        "2": i18n("Uninstall widget")
    }
    property var dialogSubtitles: {
        "0": i18n("Note: version with the latest commits may be unstable."),
        "1": i18n("Note: if you haven't installed the Devel version before, there's no need to install the Stable version."),
        "2": i18n("Removal of the widget and all related files, including the directory with its configuration.")
    }

    property int currentTab
    signal tabChanged(currentTab: int)
    onCurrentTabChanged: tabChanged(currentTab)

    Component.onCompleted: {
        JS.checkDependencies()
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

        Kirigami.FormLayout {
            id: searchTab
            visible: currentTab === 0

            Item {
                Kirigami.FormData.isSection: true
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Check mode") + ":"

                ComboBox {
                    id: checkMode
                    textRole: "name"
                    model: [
                        { name: i18n("Manual"), value: "manual" },
                        { name: i18n("Interval"), value: "interval" },
                        { name: i18n("Daily"), value: "daily" },
                        { name: i18n("Weekly"), value: "weekly" }]
                    currentIndex: JS.setIndex(cfg_checkMode, model)
                    onCurrentIndexChanged: cfg_checkMode = model[currentIndex].value
                }

                Kirigami.ContextualHelpButton {
                    toolTipText: i18n("Choose how automatic checks are scheduled: manual, periodic interval (minutes, max 43200 - 30 days), daily at specific time or weekly at specific day/time.")
                }
            }

            RowLayout {
                visible: cfg_checkMode === "interval"
                Kirigami.FormData.label: i18n("Interval") + ":"

                SpinBox {
                    id: intervalMinutes
                    from: 30
                    to: 43200
                    stepSize: 5
                    value: intervalMinutes.value
                    onValueChanged: cfg_intervalMinutes = value
                }

                Label { text: i18n("minutes") }
            }

            RowLayout {
                visible: cfg_checkMode === "daily"
                Kirigami.FormData.label: i18n("Daily time") + ":"

                SpinBox {
                    id: dailyHour
                    from: 0
                    to: 23
                    stepSize: 1
                    value: dailyHour.value
                    onValueChanged: cfg_dailyHour = value
                    Layout.preferredWidth: 50
                }

                Label { text: ":" }

                SpinBox {
                    id: dailyMinute
                    from: 0
                    to: 59
                    stepSize: 1
                    value: dailyMinute.value
                    onValueChanged: cfg_dailyMinute = value
                    Layout.preferredWidth: 50
                }
            }

            RowLayout {
                visible: cfg_checkMode === "weekly"
                Kirigami.FormData.label: i18n("Weekly schedule") + ":"

                ComboBox {
                    id: weeklyDay
                    textRole: "name"
                    model: [
                        { name: i18n("Sunday"), value: 0 },
                        { name: i18n("Monday"), value: 1 },
                        { name: i18n("Tuesday"), value: 2 },
                        { name: i18n("Wednesday"), value: 3 },
                        { name: i18n("Thursday"), value: 4 },
                        { name: i18n("Friday"), value: 5 },
                        { name: i18n("Saturday"), value: 6 }
                    ]
                    currentIndex: JS.setIndex(plasmoid.configuration.weeklyDay, model)
                    onCurrentIndexChanged: plasmoid.configuration.weeklyDay = model[currentIndex].value
                }

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    SpinBox {
                        id: weeklyHour
                        from: 0
                        to: 23
                        stepSize: 1
                        value: weeklyHour.value
                        onValueChanged: cfg_weeklyHour = value
                        Layout.preferredWidth: 50
                    }

                    Label {
                        text: ":"
                        verticalAlignment: Text.AlignVCenter
                    }

                    SpinBox {
                        id: weeklyMinute
                        from: 0
                        to: 59
                        stepSize: 1
                        value: weeklyMinute.value
                        onValueChanged: cfg_weeklyMinute = value
                        Layout.preferredWidth: 50
                    }
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
                }
            }

            RowLayout {
                spacing: Kirigami.Units.gridUnit
                visible: pkg.pacman

                CheckBox {
                    id: aur
                    text: i18n("Arch User Repository") + " (AUR)"
                    enabled: pkg.paru || pkg.yay || pkg.pikaur
                }

                Kirigami.UrlButton {
                    url: "https://github.com/exequtic/apdatifier#supported-pacman-wrappers"
                    text: instTip.text
                    font.pointSize: instTip.font.pointSize
                    color: instTip.color
                    visible: !aur.enabled
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
                    enabled: pkg.jq
                }

                Kirigami.ContextualHelpButton {
                    toolTipText: i18n("Required installed") + " jq." + i18n("<br><br>For widget developers:<br>Don't forget to update the metadata.json and specify the name of the applet and its version <b>exactly</b> as they appear on the KDE Store.")
                }
            }

            RowLayout {
                spacing: Kirigami.Units.gridUnit

                CheckBox {
                    id: fwupd
                    text: i18n("Firmware")
                    enabled: pkg.fwupdmgr
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
                    enabled: pkg.jq
                }
            }

            CheckBox {
                id: newsKDE
                text: "KDE Announcements"
                enabled: pkg.jq
            }

            CheckBox {
                id: newsTWIK
                text: "This Week in KDE"
                enabled: pkg.jq
            }

            CheckBox {
                id: newsTWIKA
                text: "This Week in KDE Apps"
                enabled: pkg.jq
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
                    id: notifyUpdatesAction
                    text: i18n("Action button")
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

            RowLayout {
                spacing: Kirigami.Units.largeSpacing * 2

                CheckBox {
                    id: notifyNews
                    text: i18n("For news")
                }

                CheckBox {
                    id: notifyNewsAction
                    text: i18n("Action button")
                    enabled: notifyNews.checked
                }
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
                enabled: notifyUpdates.checked || notifyNews.checked || notifyErrors.checked
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

            Item {
                Kirigami.FormData.isSection: true
            }

            RowLayout {
                Layout.preferredWidth: miscTab.width - Kirigami.Units.largeSpacing * 10
                Button {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 500
                    icon.name: "folder-git-symbolic"
                    text: i18n("Install Development version")
                    onClicked: {
                        installButton = 0
                        installDialog.open()
                    }
                }
            }
            RowLayout {
                Layout.preferredWidth: miscTab.width - Kirigami.Units.largeSpacing * 10
                Button {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 500
                    icon.name: "run-build"
                    text: i18n("Install Stable version")
                    onClicked: {
                        installButton = 1
                        installDialog.open()
                    }
                }
            }
            RowLayout {
                Layout.preferredWidth: miscTab.width - Kirigami.Units.largeSpacing * 10
                Button {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 500
                    icon.name: "delete"
                    text: i18n("Uninstall widget")
                    onClicked: {
                        installButton = 2
                        installDialog.open()
                    }
                }
            }

            Item {
                Kirigami.FormData.isSection: true
            }

            RowLayout {
                Layout.preferredWidth: miscTab.width - Kirigami.Units.largeSpacing * 10
                Label {
                    text: "pacman DBPath:"
                }
                TextArea {
                    id: dbPath
                    Layout.fillWidth: true
                    Layout.maximumWidth: 320
                    readOnly: true
                    Component.onCompleted: dbPath.text = plasmoid.configuration.dbPath
                }
                Button {
                    icon.name: "document-open"
                    onClicked: folderDialog.open()
                }
                Button {
                    icon.name: "edit-reset"
                    ToolTip.delay: 0
                    ToolTip.visible: hovered
                    ToolTip.text: i18n("Reset to default. By default, the path is the same as for checkupdates.")
                    onClicked: {
                        dbPath.text = plasmoid.configuration.dbPathDefault
                        pathError.visible = false
                    }
                }
                FolderDialog {
                    id: folderDialog
                    onAccepted: {
                        const path = selectedFolder.toString().substring(7)
                        if (path.includes(' ')) {
                            pathError.visible = true
                        } else {
                            dbPath.text = path
                            pathError.visible = false
                        }
                    }
                }
            }

            Label {
                id: pathError
                text: i18n("Path must not contain spaces")
                color: Kirigami.Theme.negativeTextColor
                visible: false
            }

            Kirigami.PromptDialog {
                id: installDialog
                title: dialogTitles[installButton]
                subtitle: dialogSubtitles[installButton]
                standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
                onAccepted: {
                    if (installButton === 0) {
                        JS.execute(JS.runInTerminal("utils", "installDev"))
                    } else if (installButton === 1) {
                        JS.execute(JS.runInTerminal("utils", "installStable"))
                    } else {
                        JS.execute(JS.runInTerminal("utils", "uninstall"))
                    }
                }
            }
        }
    }
}
