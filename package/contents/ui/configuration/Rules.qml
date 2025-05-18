/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.iconthemes
import org.kde.kirigami as Kirigami

import "../../tools/tools.js" as JS


ColumnLayout {
    ListModel {
        id: rulesModel
        Component.onCompleted: {
            JS.execute(JS.readFile(JS.rulesFile), (cmd, out, err, code) => {
                if (JS.Error(code, err)) return
                if (out && JS.validJSON(out, JS.rulesFile)) {
                    JSON.parse(out).forEach(el => rulesModel.append({type: el.type, value: el.value, icon: el.icon, excluded: el.excluded}))
                }
            })
        }
    }

    ListModel {
        id: typesModel
        Component.onCompleted: {
            let types = [
                {name: i18n("Unimportant"), type: "all", tip: "---"},
                {name: i18n("Repository"), type: "repo", tip: i18n("Exact repository match")},
                {name: i18n("Group"), type: "group", tip: i18n("Substring group match")},
                {name: i18n("Substring"), type: "match", tip: i18n("Substring name match")},
                {name: i18n("Name"), type: "name", tip: i18n("Exact name match")}
            ]

            for (var i = 0; i < types.length; ++i) {
                typesModel.append({name: types[i].name, type: types[i].type, tip: types[i].tip})
            }
        }
    }

    Kirigami.InlineMessage {
        id: rulesMsg
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing * 2
        Layout.rightMargin: Kirigami.Units.smallSpacing * 2
        icon.source: "showinfo"
        text: i18n("Here you can override the default package icons and exclude them from the list. Each rule overwrites the previous one, so the list of rules should be in this order: ")+i18n("Unimportant")+", "+i18n("Repository")+", "+i18n("Group")+", "+i18n("Substring")+", "+i18n("Name")
        visible: plasmoid.configuration.rulesMsg

        actions: [
            Kirigami.Action {
                text: "OK"
                icon.name: "checkmark"
                onTriggered: plasmoid.configuration.rulesMsg = false
            }
        ]
    }

    Component {
        id: rule
        ItemDelegate {
            width: rulesList.width - Kirigami.Units.largeSpacing * 2
            contentItem: RowLayout {
                ComboBox {
                    implicitWidth: 200
                    id: type
                    model: typesModel
                    textRole: "name"
                    currentIndex: -1
                    onCurrentIndexChanged: {
                        if (currentIndex === 0) valueField.text = ""
                        rulesList.model.set(index, {"type": model.get(currentIndex).type})
                    }
                    Component.onCompleted: {
                        var currentType = rulesList.model.get(index).type
                        for (var i = 0; i < model.count; ++i) {
                            if (model.get(i).type === currentType) {
                                currentIndex = i
                                break
                            }
                        }
                    }
                }

                TextField {
                    id: valueField
                    Layout.fillWidth: true
                    text: model.value
                    placeholderText: type.model.get(type.currentIndex).tip
                    enabled: type.currentIndex !== 0
                    onTextChanged: {
                        var allow = /^[a-z0-9_\-+.]*$/
                        if (!allow.test(valueField.text)) valueField.text = valueField.text.replace(/[^a-z0-9_\-+.]/g, "")
                        model.value = valueField.text
                    }
                }

                ToolButton {
                    ToolTip { text: model.icon }
                    icon.name: model.icon
                    onClicked: iconDialog.open()

                    IconDialog {
                        id: iconDialog
                        onIconNameChanged: model.icon = iconName
                    }
                }

                ToolButton {
                    ToolTip { text: model.excluded ? i18n("Show in the list") : i18n("Exclude from the list") }
                    icon.name: model.excluded ? "view-visible" : "hint"
                    onClicked: model.excluded = !model.excluded
                }

                ToolButton {
                    icon.name: 'arrow-up'
                    enabled: index > 0
                    onClicked: rulesList.model.move(index, index - 1, 1)
                }

                ToolButton {
                    icon.name: 'arrow-down'
                    enabled: index > -1 && index < rulesList.model.count - 1
                    onClicked: rulesList.model.move(index, index + 1, 1)
                }

                ToolButton {
                    ToolTip { text: i18n("Remove") }
                    icon.name: 'delete'
                    onClicked: rulesList.model.remove(index)
                }
            }
        }
    }

    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        id: rulesList
        model: rulesModel
        delegate: rule
        clip: true

        boundsBehavior: Flickable.StopAtBounds
        add: Transition { NumberAnimation { properties: "x"; from: 100; duration: 300 } }
        moveDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 300 } }
        move: Transition { NumberAnimation { properties: "x,y"; duration: 300 } }
        removeDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 300 } }
        remove: Transition { ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: 300 }
            NumberAnimation { properties: "x"; to: 100; duration: 300 } } }
        ScrollBar.vertical: ScrollBar { active: true }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Button {
            text: i18n("Add rule")
            icon.name: "list-add"
            onClicked: {
                var type = "name"
                var value = ""
                var icon = plasmoid.configuration.ownIconsUI ? "apdatifier-package" : "server-database"
                var excluded = false
                rulesModel.append({type: type, value: value, icon: icon, excluded: excluded})
            }
        }
        Button {
            text: i18n("Apply")
            icon.name: "dialog-ok-apply"
            onClicked: {
                var array = []
                for (var i = rulesModel.count - 1; i >= 0; --i) {
                    if (rulesModel.get(i).type !== "all" && rulesModel.get(i).value.trim() === "") rulesModel.remove(i, 1);
                }
                for (var i = 0; i < rulesModel.count; i++) {
                    array.push(rulesModel.get(i))
                }
                var rules = JS.toFileFormat(array)
                plasmoid.configuration.rules = rules
                JS.execute(JS.writeFile(rules, '>', JS.rulesFile))
            }
        }
    }
}
