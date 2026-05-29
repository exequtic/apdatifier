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
                    JSON.parse(out).forEach(el => {
                        if (el.type !== "name" && el.type !== "regex") return
                        rulesModel.append({
                            type: el.type,
                            value: el.value,
                            icon: el.icon,
                            excluded: el.excluded,
                            ignore: ('ignore' in el) ? el.ignore : false,
                            important: ('important' in el) ? el.important : false
                        })
                    })
                }
            })
        }
    }

    ListModel {
        id: typesModel
        Component.onCompleted: {
            let types = [
                {name: i18n("Name"),  type: "name",  tip: i18n("Exact package name")},
                {name: i18n("Regex"), type: "regex", tip: i18n("See Help")}
            ]

            for (var i = 0; i < types.length; ++i) {
                typesModel.append({name: types[i].name, type: types[i].type, tip: types[i].tip})
            }
        }
    }

    Component {
        id: rule
        Item {
            id: ruleItem
            required property int index
            required property var model
            width: rulesList.width - Kirigami.Units.largeSpacing * 2
            height: swipeListItem.height

            Kirigami.SwipeListItem {
                id: swipeListItem
                down: false
                hoverEnabled: true
                separatorVisible: true

                contentItem: RowLayout {
                Kirigami.ListItemDragHandle {
                    listItem: swipeListItem
                    listView: rulesList
                    onMoveRequested: rulesModel.move(oldIndex, newIndex, 1)
                }
                ComboBox {
                    implicitWidth: 120
                    id: type
                    model: typesModel
                    textRole: "name"
                    currentIndex: -1
                    onCurrentIndexChanged: {
                        rulesList.model.set(index, {
                            "type": model.get(currentIndex).type,
                            "value": "",
                            "ignore": false
                        })
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
                    enabled: true
                    onTextChanged: {
                        if (type.model.get(type.currentIndex).type === "name") {
                            var filtered = valueField.text.replace(/[^a-z0-9_\-+.]/g, "")
                            if (valueField.text !== filtered) {
                                valueField.text = filtered
                                return
                            }
                        }
                        if (model.value !== valueField.text) {
                            model.value = valueField.text
                        }
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
                    ToolTip { text: i18n("Mark as important") }
                    icon.name: model.important ? "flag-red" : "flag"
                    checkable: true
                    checked: model.important
                    onClicked: model.important = !model.important
                }

                ToolButton {
                    ToolTip { text: model.excluded ? i18n("Show in the list") : i18n("Exclude from the list") }
                    icon.name: model.excluded ? "hint" : "view-visible"
                    checkable: true
                    checked: model.excluded
                    onClicked: model.excluded = !model.excluded
                }

                ToolButton {
                    ToolTip { 
                        text: i18n("Ignore a package upgrade. <b>Be careful in skipping packages, since partial upgrades are unsupported.</b>")
                    }
                    icon.name: model.ignore ? "process-stop" : "software-updates-updates"
                    enabled: type.model.get(type.currentIndex).type === "name"
                    checkable: true
                    checked: model.ignore
                    opacity: enabled ? 1 : 0.5
                    onClicked: model.ignore = !model.ignore
                }

                ToolButton {
                    ToolTip { text: i18n("Remove") }
                    icon.name: 'delete'
                    onClicked: rulesList.model.remove(index)
                }
            }
        }
    }
    }

    Kirigami.InlineMessage {
        id: rulesMsg
        Layout.fillWidth: true
        icon.source: "showinfo"
        text: i18n("Rules apply top-to-bottom: later rules override earlier ones.<br><br>Regex examples:<br><b>^nvidia</b> — names starting with nvidia<br><b>wayland$</b> — names ending with wayland<br><b>.*qt.*</b> — names containing qt<br><b>(ttf|font|otf)</b> — any of ttf, font, or otf<br><b>linux(-zen|-lts)?$</b> — linux, linux-zen or linux-lts")
        visible: false
    }

    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        id: rulesList
        model: rulesModel
        delegate: rule
        clip: true

        boundsBehavior: Flickable.StopAtBounds
        reuseItems: true
        headerPositioning: ListView.OverlayHeader
        header: Kirigami.InlineViewHeader {
            width: rulesList.width
            text: i18n("Rules")
            actions: [
                Kirigami.Action {
                    icon.name: "help-about-symbolic"
                    text: i18n("Help")
                    checkable: true
                    id: helpAction
                    onTriggered: rulesMsg.visible = checked
                },
                Kirigami.Action {
                    icon.name: "list-add-symbolic"
                    text: i18n("Add")
                    onTriggered: rulesModel.append({
                        type: "name", value: "",
                        icon: plasmoid.configuration.ownIconsUI ? "apdatifier-package" : "server-database",
                        excluded: false, important: false, ignore: false
                    })
                },
                Kirigami.Action {
                    id: applyAction
                    icon.name: "dialog-ok-apply"
                    text: i18n("Apply")
                    enabled: {
                        var arr = []
                        for (var i = 0; i < rulesModel.count; i++) {
                            var item = rulesModel.get(i)
                            if (item.value.trim() !== "")
                                arr.push({
                                    type: item.type, value: item.value, icon: item.icon,
                                    excluded: item.excluded, important: item.important, ignore: item.ignore
                                })
                        }
                        return JS.toFileFormat(arr) !== plasmoid.configuration.rules
                    }
                    onTriggered: {
                        var array = []
                        for (var i = 0; i < rulesModel.count; i++) {
                            var item = rulesModel.get(i)
                            if (item.value.trim() !== "")
                                array.push({
                                    type: item.type, value: item.value, icon: item.icon,
                                    excluded: item.excluded, important: item.important, ignore: item.ignore
                                })
                        }
                        var rules = JS.toFileFormat(array)
                        plasmoid.configuration.rules = rules
                        JS.execute(JS.writeFile(rules, '>', JS.rulesFile))
                        rulesModel.clear()
                        for (var i = 0; i < array.length; i++)
                            rulesModel.append(array[i])
                    }
                }
            ]
        }
        moveDisplaced: Transition {
            YAnimator { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad }
        }
        ScrollBar.vertical: ScrollBar { active: true }

        Label {
            anchors.centerIn: parent
            visible: rulesModel.count === 0
            text: i18n("No rules yet")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.3
            opacity: 0.6
        }
    }

}
