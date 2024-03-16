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
    property alias cfg_wrapperUpgrade: wrapperUpgrade.checked
    property alias cfg_upgradeFlags: upgradeFlags.checked
    property alias cfg_upgradeFlagsText: upgradeFlagsText.text
    property string cfg_terminal: plasmoid.configuration.terminal
    property alias cfg_mirrors: mirrors.checked

    property alias cfg_mirrorCount: mirrorCount.value
    property var countryList: []
    property string cfg_dynamicUrl: plasmoid.configuration.dynamicUrl

    property var pkg: plasmoid.configuration.packages
    property var terminals: plasmoid.configuration.terminals

    Kirigami.FormLayout {
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
                    if (cfg_terminal.split("/").pop() === "yakuake") {
                        mirrors.checked = false
                    }
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

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            id: wrapperUpgrade
            text: i18n("Upgrade using wrapper")
            enabled: terminals && plasmoid.configuration.wrappers
            visible: pkg.pacman
        }


        CheckBox {
            id: upgradeFlags
            text: i18n("Additional flags")
            enabled: terminals
            visible: pkg.pacman
        }

        TextField {
            id: upgradeFlagsText
            placeholderText: i18n(" only flags, without -Syu")
            placeholderTextColor: "grey"
            visible: pkg.pacman && upgradeFlags.checked
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Pacman Mirrorlist Generator")
            Kirigami.FormData.isSection: true
        }

        Kirigami.UrlButton {
            horizontalAlignment: Text.AlignHCenter
            url: "https://archlinux.org/mirrorlist"
            text: "archlinux.org"
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: Kirigami.Theme.positiveTextColor
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Generator:")
            id: mirrors
            text: i18n("Refresh on upgrade")
            enabled: pkg.checkupdates && cfg_terminal.split("/").pop() !== "yakuake"
            visible: pkg.pacman
        }

        Item {
            Kirigami.FormData.isSection: true
        }   

        CheckBox {
            Kirigami.FormData.label: i18n("Protocol:")
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

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            Kirigami.FormData.label: i18n("IP version:")
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

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Mirror status:")
            id: mirrorstatus
            text: "Use mirror status"
            onClicked: updateUrl()
            enabled: mirrors.checked
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Number output:")
            id: mirrorCount
            from: 1
            to: 10
            stepSize: 1
            value: mirrorCount
            enabled: mirrors.checked
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        Label {
            Kirigami.FormData.label: i18n("Country:")
            textFormat: Text.RichText
            text: {
                var matchResult = cfg_dynamicUrl.match(/country=([A-Z]+)/g)
                if (matchResult !== null) {
                    var countries = matchResult.map(str => str.split("=")[1]).join(", ")
                    return countries
                } else {
                    return '<a style="color: ' + Kirigami.Theme.negativeTextColor + '">Select at least one!</a>'
                }
            }
        }

        ScrollView {
            enabled: mirrors.checked
            Column {
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

    property ListModel countryListModel: ListModel {
        ListElement { text: "Australia"; code: "AU"; checked: false }
        ListElement { text: "Austria"; code: "AT"; checked: false }
        ListElement { text: "Azerbaijan"; code: "AZ"; checked: false }
        ListElement { text: "Bangladesh"; code: "BD"; checked: false }
        ListElement { text: "Belarus"; code: "BY"; checked: false }
        ListElement { text: "Belgium"; code: "BE"; checked: false }
        ListElement { text: "Bosnia and Herzegovina"; code: "BA"; checked: false }
        ListElement { text: "Brazil"; code: "BR"; checked: false }
        ListElement { text: "Bulgaria"; code: "BG"; checked: false }
        ListElement { text: "Cambodia"; code: "KH"; checked: false }
        ListElement { text: "Canada"; code: "CA"; checked: false }
        ListElement { text: "Chile"; code: "CL"; checked: false }
        ListElement { text: "China"; code: "CN"; checked: false }
        ListElement { text: "Colombia"; code: "CO"; checked: false }
        ListElement { text: "Croatia"; code: "HR"; checked: false }
        ListElement { text: "Czech Republic"; code: "CZ"; checked: false }
        ListElement { text: "Denmark"; code: "DK"; checked: false }
        ListElement { text: "Ecuador"; code: "EC"; checked: false }
        ListElement { text: "Estonia"; code: "EE"; checked: false }
        ListElement { text: "Finland"; code: "FI"; checked: false }
        ListElement { text: "France"; code: "FR"; checked: false }
        ListElement { text: "Georgia"; code: "GE"; checked: false }
        ListElement { text: "Germany"; code: "DE"; checked: false }
        ListElement { text: "Greece"; code: "GR"; checked: false }
        ListElement { text: "Hong Kong"; code: "HK"; checked: false }
        ListElement { text: "Hungary"; code: "HU"; checked: false }
        ListElement { text: "Iceland"; code: "IS"; checked: false }
        ListElement { text: "India"; code: "IN"; checked: false }
        ListElement { text: "Indonesia"; code: "ID"; checked: false }
        ListElement { text: "Iran"; code: "IR"; checked: false }
        ListElement { text: "Israel"; code: "IL"; checked: false }
        ListElement { text: "Italy"; code: "IT"; checked: false }
        ListElement { text: "Japan"; code: "JP"; checked: false }
        ListElement { text: "Kazakhstan"; code: "KZ"; checked: false }
        ListElement { text: "Kenya"; code: "KE"; checked: false }
        ListElement { text: "Latvia"; code: "LV"; checked: false }
        ListElement { text: "Lithuania"; code: "LT"; checked: false }
        ListElement { text: "Luxembourg"; code: "LU"; checked: false }
        ListElement { text: "Mauritius"; code: "MU"; checked: false }
        ListElement { text: "Mexico"; code: "MX"; checked: false }
        ListElement { text: "Moldova"; code: "MD"; checked: false }
        ListElement { text: "Monaco"; code: "MC"; checked: false }
        ListElement { text: "Netherlands"; code: "NL"; checked: false }
        ListElement { text: "New Caledonia"; code: "NC"; checked: false }
        ListElement { text: "New Zealand"; code: "NZ"; checked: false }
        ListElement { text: "North Macedonia"; code: "MK"; checked: false }
        ListElement { text: "Norway"; code: "NO"; checked: false }
        ListElement { text: "Paraguay"; code: "PY"; checked: false }
        ListElement { text: "Poland"; code: "PL"; checked: false }
        ListElement { text: "Portugal"; code: "PT"; checked: false }
        ListElement { text: "Romania"; code: "RO"; checked: false }
        ListElement { text: "Russia"; code: "RU"; checked: false }
        ListElement { text: "Réunion"; code: "RE"; checked: false }
        ListElement { text: "Serbia"; code: "RS"; checked: false }
        ListElement { text: "Singapore"; code: "SG"; checked: false }
        ListElement { text: "Slovakia"; code: "SK"; checked: false }
        ListElement { text: "Slovenia"; code: "SI"; checked: false }
        ListElement { text: "South Africa"; code: "ZA"; checked: false }
        ListElement { text: "South Korea"; code: "KR"; checked: false }
        ListElement { text: "Spain"; code: "ES"; checked: false }
        ListElement { text: "Sweden"; code: "SE"; checked: false }
        ListElement { text: "Switzerland"; code: "CH"; checked: false }
        ListElement { text: "Taiwan"; code: "TW"; checked: false }
        ListElement { text: "Thailand"; code: "TH"; checked: false }
        ListElement { text: "Turkey"; code: "TR"; checked: false }
        ListElement { text: "Ukraine"; code: "UA"; checked: false }
        ListElement { text: "United Kingdom"; code: "GB"; checked: false }
        ListElement { text: "United States"; code: "US"; checked: false }
        ListElement { text: "Uzbekistan"; code: "UZ"; checked: false }
        ListElement { text: "Vietnam"; code: "VN"; checked: false }
    }
}
