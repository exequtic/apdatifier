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

import "../../tools/tools.js" as JS

SimpleKCM {
    property string cfg_terminal: plasmoid.configuration.terminal
    property alias cfg_termFont: termFont.checked

    property string cfg_wrapper: plasmoid.configuration.wrapper
    property alias cfg_upgradeFlags: upgradeFlags.checked
    property alias cfg_upgradeFlagsText: upgradeFlagsText.text
    property alias cfg_sudoBin: sudoBin.text
    property alias cfg_rebootSystem: rebootSystem.checked
    property alias cfg_mirrors: mirrors.checked
    property alias cfg_mirrorCount: mirrorCount.value
    property var countryList: []
    property string cfg_dynamicUrl: plasmoid.configuration.dynamicUrl

    property alias cfg_flatpakRemoveUnused: flatpakRemoveUnused.checked
    property string cfg_flatpakFlags: plasmoid.configuration.flatpakFlags

    property alias cfg_widgetConfirmation: widgetConfirmation.checked
    property alias cfg_restartShell: restartShell.checked
    property alias cfg_restartCommand: restartCommand.text

    property var pkg: plasmoid.configuration.packages
    property var terminals: plasmoid.configuration.terminals
    property alias cfg_preExec: preExec.text
    property alias cfg_postExec: postExec.text

    property int currentTab
    signal tabChanged(currentTab: int)
    onCurrentTabChanged: tabChanged(currentTab)
 
    header: Kirigami.NavigationTabBar {
        actions: [
            Kirigami.Action {
                icon.name: "akonadiconsole"
                text: i18n("General")
                checked: currentTab === 0
                onTriggered: currentTab = 0
            },
            Kirigami.Action {
                icon.name: "apdatifier-package"
                text: "Arch"
                checked: currentTab === 1
                onTriggered: currentTab = 1
            },
            Kirigami.Action {
                icon.name: "apdatifier-flatpak"
                text: "Flatpak"
                checked: currentTab === 2
                onTriggered: currentTab = 2
            },
            Kirigami.Action {
                icon.name: "start-here-kde-plasma-symbolic"
                text: i18n("Widgets")
                checked: currentTab === 3
                onTriggered: currentTab = 3
            }
        ]
    }

    Kirigami.FormLayout {
        id: terminalTab
        visible: currentTab === 0

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Terminal") + ":"

            ComboBox {
                model: terminals
                textRole: "name"
                enabled: terminals

                onCurrentIndexChanged: cfg_terminal = model[currentIndex]["value"]

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
                text: i18n("Not installed")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                color: Kirigami.Theme.neutralTextColor
                visible: !terminals
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            CheckBox {
                id: termFont
                text: i18n("Use NerdFont icons")
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("If your terminal utilizes any <b>Nerd Font</b>, icons from that font will be used.")
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Pre/post upgrade scripts")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Pre-exec") + ":"

            TextField {
                id: preExec
                placeholderText: i18n("Command or script path")
                placeholderTextColor: "grey"
            }

            Button {
                icon.name: "document-open"
                onClicked: fileDialogPreExec.open()
            }

            FileDialog {
                id: fileDialogPreExec
                fileMode: FileDialog.OpenFile
                onAccepted: preExec.text = selectedFile.toString().substring(7)
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Running your command or script BEFORE the upgrade.<br>For example, you can specify your command to update the mirrorlist if you have unofficial repositories.")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Post-exec") + ":"

            TextField {
                id: postExec
                placeholderText: i18n("Command or script path")
                placeholderTextColor: "grey"
            }

            Button {
                icon.name: "document-open"
                onClicked: fileDialogPostExec.open()
            }

            FileDialog {
                id: fileDialogPostExec
                fileMode: FileDialog.OpenFile
                onAccepted: postExec.text = selectedFile.toString().substring(7)
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Running your command or script AFTER the upgrade.<br>For example, you can specify your command to upgrade something else.")
            }
        }
    }

    Kirigami.FormLayout {
        id: archTab
        visible: currentTab === 1

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            enabled: plasmoid.configuration.aur
            Kirigami.FormData.label: i18n("Wrapper") + ":"
            spacing: Kirigami.Units.largeSpacing * 2

            ButtonGroup {
                id: wrappersGroup
            }

            RadioButton {
                ButtonGroup.group: wrappersGroup
                text: "paru"
                enabled: pkg.paru
                onCheckedChanged: cfg_wrapper = checked ? "paru" : "yay"
                Component.onCompleted: checked = plasmoid.configuration.wrapper === text
            }

            RadioButton {
                ButtonGroup.group: wrappersGroup
                text: "yay"
                enabled: pkg.yay
                Component.onCompleted: checked = plasmoid.configuration.wrapper === text
            }
        }

        RowLayout {
            visible: !plasmoid.configuration.aur
            Label {
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.bold: true
                color: Kirigami.Theme.negativeTextColor
                text: i18n("AUR disabled in search settings")
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Upgrade options") + ":"
            CheckBox {
                id: upgradeFlags
                text: i18n("Enable")
                enabled: terminals
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Options") + ":"
            spacing: 0
            visible: pkg.pacman

            TextField {
                id: upgradeFlagsText
                placeholderText: "--noconfirm"
                placeholderTextColor: "grey"
                enabled: pkg.pacman && upgradeFlags.checked

                onTextChanged: {
                    var allow = /^[a-z\- ]*$/
                    if (!allow.test(upgradeFlagsText.text))
                        upgradeFlagsText.text = upgradeFlagsText.text.replace(/[^a-z\- ]/g, "")
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: "sudobin:"
            spacing: 0
            enabled: pkg.pacman

            TextField {
                id: sudoBin
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Reboot system") + ":"

            CheckBox {
                id: rebootSystem
                text: i18n("Suggest after upgrading")
            }

            Kirigami.ContextualHelpButton {
                toolTipText: "This option suggests restarting the system after upgrading critical packages.<br><br><b>Note that not all critical packages require a full system restart; some may only need a session restart or no action at all, such as when an updated package is not currently running (e.g., an alternative kernel) or not in use (e.g., an alternative driver).</b>"
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Pacman Mirrorlist Generator")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Label {
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.bold: true
                color: Kirigami.Theme.negativeTextColor
                text: i18n("Only for official repositories")
            }
        }

        Item {
            Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Generator") + ":"

            CheckBox {
                id: mirrors
                text: i18n("Suggest before upgrading")
                enabled: pkg.pacman && pkg.checkupdates && pkg.curl
                Component.onCompleted: if (checked && !enabled) checked = plasmoid.configuration.mirrors = false
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("To use this feature, the following installed utilities are required:<br><b>curl, pacman-contrib.</b> <br><br>Also see https://archlinux.org/mirrorlist (click button to open link)")
                onClicked: Qt.openUrlExternally("https://archlinux.org/mirrorlist")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Protocol") + ":"

            CheckBox {
                
                id: http
                text: "http"
                onClicked: updateUrl()
                enabled: mirrors.checked
            }

            CheckBox {
                id: https
                text: "https"
                onClicked: updateUrl()
                enabled: mirrors.checked
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("IP version") + ":"

            CheckBox {
                id: ipv4
                text: "IPv4"
                onClicked: updateUrl()
                enabled: mirrors.checked
            }

            CheckBox {
                id: ipv6
                text: "IPv6"
                onClicked: updateUrl()
                enabled: mirrors.checked
            }
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Mirror status") + ":"
            id: mirrorstatus
            text: i18n("Enable")
            onClicked: updateUrl()
            enabled: mirrors.checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Number output") + ":"

            SpinBox {
                id: mirrorCount
                from: 0
                to: 10
                stepSize: 1
                value: mirrorCount
                enabled: mirrors.checked
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Number of servers to write to mirrorlist file. 0 for all.")
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Country") + ":"

            Label {
                textFormat: Text.RichText
                text: {
                    var matchResult = cfg_dynamicUrl.match(/country=([A-Z]+)/g)
                    if (matchResult !== null) {
                        var countries = matchResult.map(str => str.split("=")[1]).join(", ")
                        return countries
                    } else {
                        return '<a style="color: ' + Kirigami.Theme.negativeTextColor + '">' + i18n("Select at least one!") + '</a>'
                    }
                }
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("You must select at least one country, otherwise all will be chosen by default. <br><br><b>The more countries you select, the longer it will take to generate the mirrors!</b> <br><br>It is optimal to choose <b>1-2</b> countries closest to you.")
            }
        }

        ColumnLayout {
            Layout.maximumWidth: archTab.width / 2.5
            Layout.maximumHeight: 200
            enabled: mirrors.checked

            ScrollView {
                Layout.preferredWidth: archTab.width / 2.5
                Layout.preferredHeight: 200

                GridLayout {
                    columns: 1
                
                    Repeater {
                        model: countryListModel
                        delegate: CheckBox {
                            text: model.text
                            checked: model.checked
                            onClicked: {
                                model.checked = checked
                                checked ? countryList.push(model.code) : countryList.splice(countryList.indexOf(model.code), 1)
                                updateUrl()
                            }
                        }
                    }
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }
    }

    Kirigami.FormLayout {
        id: flatpakTab
        visible: currentTab === 2

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Uninstall unused") + ":"

            CheckBox {
                id: flatpakRemoveUnused
                text: i18n("Enable")
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        ButtonGroup {
            id: flatpakFlags
        }

        RowLayout{
            Kirigami.FormData.label: i18n("Upgrade options") + ":"

            RadioButton {
                ButtonGroup.group: flatpakFlags
                text: i18n("Normal")
                checked: plasmoid.configuration.flatpakFlags === ""
                onCheckedChanged: {
                    if (checked) cfg_flatpakFlags = ""
                }
            }
        }

        RadioButton {
            ButtonGroup.group: flatpakFlags
            text: i18n("Normal, skip questions")
            checked: plasmoid.configuration.flatpakFlags === "--assumeyes"
            onCheckedChanged: {
                if (checked) cfg_flatpakFlags = "--assumeyes"
            }
        }

        RadioButton {
            ButtonGroup.group: flatpakFlags
            text: i18n("Non interactive, skip questions")
            checked: plasmoid.configuration.flatpakFlags === "--noninteractive"
            onCheckedChanged: {
                if (checked) cfg_flatpakFlags = "--noninteractive"
            }
        }

        RadioButton {
            ButtonGroup.group: flatpakFlags
            text: i18n("Verbose")
            checked: plasmoid.configuration.flatpakFlags === "--verbose"
            onCheckedChanged: {
                if (checked) cfg_flatpakFlags = "--verbose"
            }
        }
    }

    Kirigami.FormLayout {
        id: widgetsTab
        visible: currentTab === 3

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Upgrade confirmation") + ":"

            CheckBox {
                id: widgetConfirmation
                text: i18n("Enable")
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Restart plasmashell") + ":"

            CheckBox {
                id: restartShell
                text: i18n("Suggest after upgrading")
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("After upgrading widget, the old version will still remain in memory until you restart plasmashell. To avoid doing this manually, enable this option.")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Command") + ":"

            TextField {
                id: restartCommand
                enabled: restartShell.checked
            }
        }
    }

    Component.onCompleted: {
        if(cfg_dynamicUrl) {
            var urlParams = plasmoid.configuration.dynamicUrl.split("?")[1].split("&")

            for (var i = 0; i < urlParams.length; i++) {
                var param = urlParams[i]
                if (param.includes("use_mirror_status=on")) mirrorstatus.checked = true
                if (/protocol=http\b/.test(param)) http.checked = true
                if (param.includes("protocol=https")) https.checked = true
                if (param.includes("ip_version=4")) ipv4.checked = true
                if (param.includes("ip_version=6")) ipv6.checked = true
                if (param.includes("country=")) {
                    var country = decodeURIComponent(param.split("=")[1])
                    countryList.push(country)
                    for (var j = 0; j < countryListModel.count; ++j) {
                        if (countryListModel.get(j).code === country) {
                            countryListModel.get(j).checked = true
                        }
                    }
                }
            }
        }
    }

    function updateUrl() {
        var params = ""
        if (http.checked) params += "&protocol=http"
        if (https.checked) params += "&protocol=https"
        if (ipv4.checked) params += "&ip_version=4"
        if (ipv6.checked) params += "&ip_version=6"
        if (mirrorstatus.checked) params += "&use_mirror_status=on"

        for (var i = 0; i < countryList.length; i++) {
            params += "&country=" + countryList[i]
        }

        var baseUrl = "https://archlinux.org/mirrorlist/?"
        cfg_dynamicUrl = baseUrl + params.substring(1)
    }

    ListModel {
        id: countryListModel

        function createCountryList() {
            let countries = 
                "Australia:AU, Austria:AT, Azerbaijan:AZ, Bangladesh:BD, Belarus:BY, Belgium:BE, " +
                "Bosnia and Herzegovina:BA, Brazil:BR, Bulgaria:BG, Cambodia:KH, Canada:CA, Chile:CL, " +
                "China:CN, Colombia:CO, Croatia:HR, Czech Republic:CZ, Denmark:DK, Ecuador:EC, " +
                "Estonia:EE, Finland:FI, France:FR, Georgia:GE, Germany:DE, Greece:GR, Hong Kong:HK, " +
                "Hungary:HU, Iceland:IS, India:IN, Indonesia:ID, Iran:IR, Israel:IL, Italy:IT, Japan:JP, " +
                "Kazakhstan:KZ, Kenya:KE, Latvia:LV, Lithuania:LT, Luxembourg:LU, Mauritius:MU, Mexico:MX, " +
                "Moldova:MD, Monaco:MC, Netherlands:NL, New Caledonia:NC, New Zealand:NZ, North Macedonia:MK, " +
                "Norway:NO, Paraguay:PY, Poland:PL, Portugal:PT, Romania:RO, Russia:RU, Réunion:RE, " +
                "Serbia:RS, Singapore:SG, Slovakia:SK, Slovenia:SI, South Africa:ZA, South Korea:KR, Spain:ES, " +
                "Sweden:SE, Switzerland:CH, Taiwan:TW, Thailand:TH, Turkey:TR, Ukraine:UA, United Kingdom:GB, " +
                "United States:US, Uzbekistan:UZ, Vietnam:VN"

            countries.split(", ").map(item => {
                let [country, code] = item.split(":")
                countryListModel.append({text: country, code: code, checked: false})
            })
        }

        Component.onCompleted: createCountryList()
    }
}
