/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.kcmutils
import org.kde.kirigami as Kirigami

import "../../tools/tools.js" as JS

SimpleKCM {
    property string cfg_terminal: plasmoid.configuration.terminal
    property alias cfg_termFont: termFont.checked
    property alias cfg_upgradeFlags: upgradeFlags.checked
    property alias cfg_upgradeFlagsText: upgradeFlagsText.text
    property alias cfg_sudoBin: sudoBin.text
    property alias cfg_restartShell: restartShell.checked
    property alias cfg_restartCommand: restartCommand.text

    property alias cfg_mirrors: mirrors.checked
    property alias cfg_mirrorCount: mirrorCount.value
    property var countryList: []
    property string cfg_dynamicUrl: plasmoid.configuration.dynamicUrl

    property var pkg: plasmoid.configuration.packages
    property var terminals: plasmoid.configuration.terminals

    Kirigami.FormLayout {
        id: upgradePage

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Terminal") + ":"

            ComboBox {
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
                text: i18n("Not installed")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                color: Kirigami.Theme.neutralTextColor
                visible: !terminals
            }
        }

        RowLayout {
            CheckBox {
                id: termFont
                text: i18n("Use NerdFont icons")
            }

            ContextualHelpButton {
                toolTipText: i18n("If your terminal utilizes any <b>Nerd Font</b>, icons from that font will be used.")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Options") + ":"
            spacing: 0
            visible: pkg.pacman

            CheckBox {
                id: upgradeFlags
                enabled: terminals
            }

            TextField {
                id: upgradeFlagsText
                placeholderText: "--noconfirm"
                placeholderTextColor: "grey"
                enabled: pkg.pacman && upgradeFlags.checked
            }
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
            Kirigami.FormData.label: i18n("Restart plasmashell") + ":"

            CheckBox {
                id: restartShell
                text: i18n("Suggest after upgrading")
            }

            ContextualHelpButton {
                toolTipText: i18n("After upgrading widget, the old version will still remain in memory until you restart plasmashell. To avoid doing this manually, enable this option.")
            }
        }

        TextField {
            id: restartCommand
            visible: restartShell.checked
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Pacman Mirrorlist Generator")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Generator") + ":"

            CheckBox {
                id: mirrors
                text: i18n("Suggest before upgrading")
                enabled: pkg.pacman
            }

            ContextualHelpButton {
                toolTipText: i18n("To use this feature, the following installed utilities are required:<br><b>curl, pacman-contrib.</b> <br><br>Also see https://archlinux.org/mirrorlist (click button to open link)")
                onClicked: {
                    Qt.openUrlExternally("https://archlinux.org/mirrorlist")
                }
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

            ContextualHelpButton {
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

            ContextualHelpButton {
                toolTipText: i18n("You must select at least one country, otherwise all will be chosen by default. <br><br><b>The more countries you select, the longer it will take to generate the mirrors!</b> <br><br>It is optimal to choose <b>1-2</b> countries closest to you.")
            }
        }

        ColumnLayout {
            Layout.maximumWidth: upgradePage.width / 2
            Layout.maximumHeight: 200
            enabled: mirrors.checked

            ScrollView {
                Layout.preferredWidth: upgradePage.width / 2
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
