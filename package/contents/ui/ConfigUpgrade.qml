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
    property alias cfg_upgradeFlags: upgradeFlags.checked
    property alias cfg_upgradeFlagsText: upgradeFlagsText.text
    property alias cfg_refreshShell: refreshShell.checked
    property string cfg_terminal: plasmoid.configuration.terminal
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
            Kirigami.FormData.label: i18n("Terminal:")

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
            Kirigami.FormData.label: i18n("Additional flags:")
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

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Widgets:")

            CheckBox {
                id: refreshShell
                text: i18n("Restart plasmashell")
            }

            ContextualHelpButton {
                toolTipText: i18n("<p>After upgrading widget, the old version will still remain in memory until you restart plasmashell. To avoid doing this manually, enable this option. It will restart plasmashell.service. The terminal may be closed automatically as Apdatifier will also be restarted.<br><br>If plasmashell is only terminating and not starting itself, then execute the command: kstart plasmashell.</p>")
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Pacman Mirrorlist Generator")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Generator:")

            CheckBox {
                id: mirrors
                text: i18n("Suggest refresh on upgrade")
                enabled: pkg.pacman
            }

            ContextualHelpButton {
                toolTipText: i18n("<p>To use this feature, the following installed utilities are required:<br><b>curl, pacman-contrib.</b></p><br><p>Also see https://archlinux.org/mirrorlist (click button to open link)</p>")
                onClicked: {
                    Qt.openUrlExternally("https://archlinux.org/mirrorlist")
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Protocol:")

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
            Kirigami.FormData.label: i18n("IP version:")

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
            Kirigami.FormData.label: i18n("Mirror status:")
            id: mirrorstatus
            text: i18n("Enable")
            onClicked: updateUrl()
            enabled: mirrors.checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Number output:")

            SpinBox {
                id: mirrorCount
                from: 0
                to: 10
                stepSize: 1
                value: mirrorCount
                enabled: mirrors.checked
            }

            ContextualHelpButton {
                toolTipText: i18n("<p>Number of servers to write to mirrorlist file, 0 for all</p>")
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Country:")

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
                toolTipText: i18n("<p>You must select at least one country, otherwise all will be chosen by default.<br><br><b>The more countries you select, the longer it will take to generate the mirrors!</b><br><br>It is optimal to choose <b>1-2</b> countries closest to you.</p>")
            }
        }

        ColumnLayout {
            Layout.maximumWidth: upgradePage.width / 2
            Layout.maximumHeight: 150
            enabled: mirrors.checked

            ScrollView {
                Layout.preferredWidth: upgradePage.width / 2
                Layout.preferredHeight: 150

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
            let countries = [
                {text: "Australia", code: "AU"},
                {text: "Austria", code: "AT"},
                {text: "Azerbaijan", code: "AZ"},
                {text: "Bangladesh", code: "BD"},
                {text: "Belarus", code: "BY"},
                {text: "Belgium", code: "BE"},
                {text: "Bosnia and Herzegovina", code: "BA"},
                {text: "Brazil", code: "BR"},
                {text: "Bulgaria", code: "BG"},
                {text: "Cambodia", code: "KH"},
                {text: "Canada", code: "CA"},
                {text: "Chile", code: "CL"},
                {text: "China", code: "CN"},
                {text: "Colombia", code: "CO"},
                {text: "Croatia", code: "HR"},
                {text: "Czech Republic", code: "CZ"},
                {text: "Denmark", code: "DK"},
                {text: "Ecuador", code: "EC"},
                {text: "Estonia", code: "EE"},
                {text: "Finland", code: "FI"},
                {text: "France", code: "FR"},
                {text: "Georgia", code: "GE"},
                {text: "Germany", code: "DE"},
                {text: "Greece", code: "GR"},
                {text: "Hong Kong", code: "HK"},
                {text: "Hungary", code: "HU"},
                {text: "Iceland", code: "IS"},
                {text: "India", code: "IN"},
                {text: "Indonesia", code: "ID"},
                {text: "Iran", code: "IR"},
                {text: "Israel", code: "IL"},
                {text: "Italy", code: "IT"},
                {text: "Japan", code: "JP"},
                {text: "Kazakhstan", code: "KZ"},
                {text: "Kenya", code: "KE"},
                {text: "Latvia", code: "LV"},
                {text: "Lithuania", code: "LT"},
                {text: "Luxembourg", code: "LU"},
                {text: "Mauritius", code: "MU"},
                {text: "Mexico", code: "MX"},
                {text: "Moldova", code: "MD"},
                {text: "Monaco", code: "MC"},
                {text: "Netherlands", code: "NL"},
                {text: "New Caledonia", code: "NC"},
                {text: "New Zealand", code: "NZ"},
                {text: "North Macedonia", code: "MK"},
                {text: "Norway", code: "NO"},
                {text: "Paraguay", code: "PY"},
                {text: "Poland", code: "PL"},
                {text: "Portugal", code: "PT"},
                {text: "Romania", code: "RO"},
                {text: "Russia", code: "RU"},
                {text: "Réunion", code: "RE"},
                {text: "Serbia", code: "RS"},
                {text: "Singapore", code: "SG"},
                {text: "Slovakia", code: "SK"},
                {text: "Slovenia", code: "SI"},
                {text: "South Africa", code: "ZA"},
                {text: "South Korea", code: "KR"},
                {text: "Spain", code: "ES"},
                {text: "Sweden", code: "SE"},
                {text: "Switzerland", code: "CH"},
                {text: "Taiwan", code: "TW"},
                {text: "Thailand", code: "TH"},
                {text: "Turkey", code: "TR"},
                {text: "Ukraine", code: "UA"},
                {text: "United Kingdom", code: "GB"},
                {text: "United States", code: "US"},
                {text: "Uzbekistan", code: "UZ"},
                {text: "Vietnam", code: "VN"}
            ]

            for (var i = 0; i < countries.length; ++i) {
                countryListModel.append({text: countries[i].text, code: countries[i].code, checked: false})
            }
        }

        Component.onCompleted: createCountryList()
    }
}
