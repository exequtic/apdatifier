/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

import "../../tools/tools.js" as JS

RowLayout {
    property alias labelText: label.text

    ComboBox {
        id: comboBox
        implicitWidth: 250
        textRole: "name"
        model: [
            {"name": i18n("None"), "value": ""},
            {"name": i18n("Check updates"), "value": "checkUpdates"},
            {"name": i18n("Upgrade system"), "value": "upgradeSystem"},
            {"name": i18n("Switch interval"), "value": "switchInterval"},
            {"name": i18n("Management"), "value": "management"}
        ]

        onCurrentIndexChanged: {
            var action = model[currentIndex]["value"]
            switch (type) {
                case "middle": cfg_middleAction = action; break;
                case "right": cfg_rightAction = action; break;
                case "scrollUp": cfg_scrollUpAction = action; break;
                case "scrollDown": cfg_scrollDownAction = action; break;
            }
        }

        Component.onCompleted: {
            currentIndex = JS.setIndex(plasmoid.configuration[type + "Action"], model)
        }
    }

    Label {
        id: label
        text: ""
    }

    property string type: ""
}
