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
import "../components" as DataSource


ColumnLayout {
    ListModel {
        id: rulesModel
        Component.onCompleted: {
            sh.exec(JS.readFile(JS.rulesFile), (cmd, out, err, code) => {
                if (!out) return
                JSON.parse(out).forEach(el => rulesModel.append({type: el.type, value: el.value, icon: el.icon, excluded: el.excluded}))
            })
        }
    }

    ListModel {
        id: typesModel
        Component.onCompleted: {
            let types = [
                {name: i18n("Default"), type: "default", tip: i18n("default for all")},
                {name: i18n("Repository"), type: "repo", tip: i18n("Exact repository")},
                {name: i18n("Group"), type: "group", tip: i18n("Includes in groups")},
                {name: i18n("Includes"), type: "match", tip: i18n("Includes in names")},
                {name: i18n("Name"), type: "name", tip: i18n("Exact name")}
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
        text: i18n("Here you can override the default package icons and exclude them from the list. Each rule overwrites the previous one, so the list of rules should be in this order: ")+i18n("Default")+", "+i18n("Repository")+", "+i18n("Group")+", "+i18n("Includes")+", "+i18n("Name")
        visible: plasmoid.configuration.rulesMsg

        actions: [
            Kirigami.Action {
                text: i18n("Dismiss")
                icon.name: "dialog-close"
                onTriggered: plasmoid.configuration.rulesMsg = false
            }
        ]
    }

    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        id: rulesList
        model: rulesModel
        delegate: rule
        ScrollBar.vertical: ScrollBar { active: true }
    }

    Component {
        id: rule
        ItemDelegate {
            width: rulesList.width - Kirigami.Units.largeSpacing * 2
            contentItem: RowLayout {
                ComboBox {
                    Layout.fillWidth: true
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
                    icon.name: model.icon
                    onClicked: iconDialog.open()

                    IconDialog {
                        id: iconDialog
                        onIconNameChanged: model.icon = iconName
                    }

                    ToolTip {text: model.icon }
                }

                ToolButton {
                    icon.name: model.excluded ? "gnumeric-visible" : "gnumeric-row-hide"
                    onClicked: model.excluded = !model.excluded
                    ToolTip {text: i18n("Exclude from the list") }
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
                    icon.name: 'delete'
                    onClicked: rulesList.model.remove(index)
                }
            }
        }
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
                    if (rulesModel.get(i).type !== "default" && rulesModel.get(i).value.trim() === "") rulesModel.remove(i, 1);
                }
                for (var i = 0; i < rulesModel.count; i++) {
                    array.push(rulesModel.get(i))
                }
                var rules = JSON.stringify(array)
                plasmoid.configuration.rules = rules
                sh.exec(JS.writeFile(JS.formatJson(rules), JS.rulesFile))
            }
        }
    }

    DataSource.Shell {
        id: sh
    }
}
