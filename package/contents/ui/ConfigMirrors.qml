import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.kcmutils

SimpleKCM {
    id: root

    property var countryList: []
    property string cfg_dynamicUrl: plasmoid.configuration.dynamicUrl
    property alias cfg_mirrorCount: mirrorCount.value

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

    Component.onCompleted: {
        if(cfg_dynamicUrl) {
            var urlParams = plasmoid.configuration.dynamicUrl.split("?")[1].split("&")

            for (var i = 0; i < urlParams.length; i++) {
                var param = urlParams[i]
                if (param.includes("use_mirror_status=on")) mirrorstatus.checked = true
                if (param.includes("protocol=http")) http.checked = true
                if (param.includes("protocol=https")) https.checked = true
                if (param.includes("ip_version=4")) ipv4.checked = true
                if (param.includes("ip_version=6")) ipv6.checked = true
            }
        }
    }

    Kirigami.FormLayout {
        id: page

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
            Kirigami.FormData.label: i18n("Protocol:")
            id: http
            text: "http"
            onClicked: updateUrl()
            
        }

        CheckBox {
            id: https
            text: "https"
            onClicked: updateUrl()
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            Kirigami.FormData.label: i18n("IP version:")
            id: ipv4
            text: "IPv4"
            onClicked: updateUrl()
        }

        CheckBox {
            id: ipv6
            text: "IPv6"
            onClicked: updateUrl()
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Mirror status:")
            id: mirrorstatus
            text: "Use mirror status"
            onClicked: updateUrl()
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
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        Label {
            Kirigami.FormData.label: i18n("Country:")

            text: {
                var matchResult = cfg_dynamicUrl.match(/country=([A-Z]+)/g)
                if (matchResult !== null) {
                    var countries = matchResult.map(str => str.split("=")[1]).join(", ")
                    return countries
                } else {
                    return "<font color='red'>No one selected</font>";
                }
            }
        }

        ScrollView {
            height: 120

            Column {
                Repeater {
                    id: repeater
                    model: ListModel {
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

                    delegate: CheckBox {
                        text: model.text
                        checked: model.checked

                        onClicked: {
                            model.checked = checked
                            checked ? countryList.push(model.code) : countryList.splice(countryList.indexOf(model.code), 1)
                            updateUrl()
                        }

                        Component.onCompleted: {
                            if (cfg_dynamicUrl) {
                                var urlParams = cfg_dynamicUrl
                                var urlParams = urlParams.split("?")[1].split("&")

                                for (var i = 0; i < urlParams.length; i++) {
                                    var param = urlParams[i]
                                    if (param.includes("country=")) {
                                        var country = decodeURIComponent(param.split("=")[1])
                                        if (model.code === country) {
                                            model.checked = true
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
