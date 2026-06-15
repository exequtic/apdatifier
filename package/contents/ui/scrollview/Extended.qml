import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.ksvg
import org.kde.plasma.extras
import org.kde.kirigami as Kirigami

import "../../tools/tools.js" as JS
import "../components"

Item {
    id: view

    property bool compactMode: listCompactMode
    clip: true

    ListView {
        id: listView

        ScrollBar.vertical: Scroll {
            policy: !sts.count ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded
        }

        anchors.fill: parent
        model: modelList
        boundsBehavior: Flickable.StopAtBounds
        spacing: view.compactMode ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing

        delegate: Item {
            width: listView.width
            height: delegateItem.height
        
            Rectangle {
                id: delegateItem

                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Kirigami.Units.largeSpacing
                    rightMargin: Kirigami.Units.largeSpacing
                }

                height: mainColumn.implicitHeight
                clip: true
                color: "transparent"

                property bool expanded: false
                property bool hovered: false
                property var pkg: []

                Behavior on height {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutBack
                        easing.overshoot: 0.8
                    }
                }

                HoverHandler {
                    id: hoverHandler
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: delegateItem.hovered = hovered
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: delegateItem.expanded = !delegateItem.expanded
                }

                Rectangle {
                    property color hColor: Kirigami.Theme.highlightColor
                    property bool highlighted: (delegateItem.hovered && !listView.moving) || delegateItem.expanded

                    anchors.fill: parent
                    radius: Kirigami.Units.cornerRadius
                    color: highlighted ? Qt.rgba(hColor.r, hColor.g, hColor.b, 0.4) : "transparent"
                    border.width: highlighted ? 1 : 0
                    border.color: Qt.darker(Qt.rgba(hColor.r, hColor.g, hColor.b, 0.8), 2)

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                ColumnLayout {
                    id: mainColumn
                    width: parent.width
                    spacing: 0

                    RowLayout {
                        id: mainRow
                        spacing: Kirigami.Units.largeSpacing

                        Kirigami.Icon {
                            id: pkgIcon
                            Layout.preferredWidth: view.compactMode ? Kirigami.Units.iconSizes.small : Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: view.compactMode ? Kirigami.Units.iconSizes.small : Kirigami.Units.iconSizes.medium
                            Layout.alignment: Qt.AlignVCenter
                            Layout.leftMargin: Kirigami.Units.largeSpacing
                            source: model.IC
                            isMask: false
                        }

                        // Extended
                        RowLayout {
                            visible: !view.compactMode
                            spacing: Kirigami.Units.smallSpacing
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            Layout.topMargin: Kirigami.Units.smallSpacing
                            Layout.bottomMargin: Kirigami.Units.smallSpacing

                            ColumnLayout {
                                Label {
                                    Layout.fillWidth: true
                                    text: model.NM
                                    color: model.IM ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                                    elide: Text.ElideRight
                                    font.weight: Font.DemiBold
                                }

                                Loader {
                                    Layout.fillWidth: true
                                    sourceComponent: versionDiffLabel
                                    onLoaded: {
                                        item.oldVer = model.VO
                                        item.newVer = model.VN
                                    }
                                }
                            }

                            ColumnLayout {
                                Loader {
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    Layout.rightMargin: Kirigami.Units.largeSpacing
                                    sourceComponent: infoChip
                                    active: cfg.extendedShowRepository !== false
                                    visible: active
                                    onLoaded: item.text = model.RE
                                }

                                Loader {
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    Layout.rightMargin: Kirigami.Units.largeSpacing
                                    sourceComponent: infoChip
                                    active: model.RN && cfg.extendedShowInstallReason !== false
                                    visible: active
                                    onLoaded: {
                                        item.text = model.RN
                                        item.reason = model.RN || ""
                                    }
                                }
                            }
                        }

                        // Compact
                        RowLayout {
                            visible: view.compactMode
                            spacing: Kirigami.Units.smallSpacing
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Label {
                                Layout.fillWidth: true
                                text: model.NM
                                color: model.IM ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                                elide: Text.ElideRight
                                font.weight: Font.DemiBold
                            }

                            Loader {
                                Layout.alignment: Qt.AlignRight
                                Layout.rightMargin: Kirigami.Units.largeSpacing
                                sourceComponent: infoChip
                                active: (cfg.compactInfo || "repository") === "repository"
                                visible: active
                                onLoaded: item.text = model.RE
                            }

                            Loader {
                                Layout.alignment: Qt.AlignRight
                                Layout.rightMargin: Kirigami.Units.largeSpacing
                                sourceComponent: infoChip
                                active: model.RN && (cfg.compactInfo || "repository") === "installReason"
                                visible: active
                                onLoaded: {
                                    item.text = model.RN
                                    item.reason = model.RN || ""
                                }
                            }

                            Loader {
                                Layout.alignment: Qt.AlignRight
                                Layout.rightMargin: Kirigami.Units.largeSpacing
                                Layout.fillWidth: true
                                sourceComponent: versionDiffLabel
                                active: (cfg.compactInfo || "repository") === "versionDiff"
                                visible: active
                                onLoaded: {
                                    item.oldVer = model.VO
                                    item.newVer = model.VN
                                    item.hAlign = Text.AlignRight
                                }
                            }
                        }
                    }

                    Loader {
                        id: detailsLoader
                        Layout.fillWidth: true
                        active: delegateItem.expanded
                        visible: active

                        sourceComponent: ColumnLayout {
                            spacing: 0

                            Item {
                                Layout.topMargin: Kirigami.Units.largeSpacing
                            }

                            GridLayout {
                                id: details
                                width: parent.width
                                columns: 2
                                rowSpacing: Kirigami.Units.smallSpacing / 4
                                columnSpacing: 40
                                Layout.leftMargin: Kirigami.Units.largeSpacing
                                Layout.rightMargin: Kirigami.Units.largeSpacing

                                Repeater {
                                    id: repeater
                                    model: delegateItem.pkg.length

                                    delegate: Label {
                                        property bool header: !(index % 2)
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignTop
                                        horizontalAlignment: Text.AlignLeft
                                        font: Kirigami.Theme.smallFont
                                        opacity: header ? 0.6 : 1
                                        text: {
                                            if (header)
                                                return "<b>" + delegateItem.pkg[index] + ":</b>"
                                            if (delegateItem.pkg[index].indexOf("://") !== -1)
                                                return "<a href=\"" + delegateItem.pkg[index] + "\">" + delegateItem.pkg[index] + "</a>"
                                            return delegateItem.pkg[index]
                                        }
                                        textFormat: header ? Text.StyledText : delegateItem.pkg[index].indexOf("://") !== -1 ? Text.StyledText : Text.PlainText
                                        wrapMode: header ? Text.NoWrap : Text.WordWrap
                                        onLinkActivated: Qt.openUrlExternally(link)
                                    }
                                }
                            }

                            Item {
                                Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
                            }

                            ToolButton {
                                id: upgradeButton
                                // Layout.alignment: Qt.AlignHCenter
                                Layout.alignment: Qt.AlignRight
                                Layout.rightMargin: Kirigami.Units.largeSpacing
                                visible: (model.ID || model.CN) && cfg.terminal
                                icon.name: "edit-download"
                                text: i18n("Upgrade package")
                                onClicked: JS.upgradePackage(model.NM, model.ID, model.CN)
                            }

                            Item {
                                Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
                                visible: upgradeButton.visible
                            }

                            Component.onCompleted: {
                                const F = [
                                    ["TP", i18n("Package type")],
                                    ["DE", i18n("Description")],
                                    ["AU", i18n("Author")],
                                    ["RE", i18n("Repository")],
                                    ["LN", "URL"],
                                    ["ID", i18n("App ID")],
                                    ["BR", i18n("Branch")],
                                    ["CM", i18n("Commit")],
                                    ["RT", i18n("Runtime")],
                                    ["GR", i18n("Groups")],
                                    ["PR", i18n("Provides")],
                                    ["DP", i18n("Depends on")],
                                    ["RQ", i18n("Required by")],
                                    ["CF", i18n("Conflicts with")],
                                    ["RP", i18n("Replaces")],
                                    ["IS", i18n("Installed size")],
                                    ["DS", i18n("Download size")],
                                    ["DT", i18n("Install date")],
                                    ["RN", i18n("Install reason")]
                                ]
                                const details = []
                                for (const [k, l] of F) model[k] && details.push(l, model[k])
                                delegateItem.pkg = details
                            }
                        }
                    }
                }
            }
        }

        Loader {
            anchors.centerIn: parent
            width: parent.width - (Kirigami.Units.largeSpacing * 4)

            active: !sts.count
            sourceComponent: Kirigami.PlaceholderMessage {
                width: parent.width - (Kirigami.Units.largeSpacing * 4)
                icon.name: "checkmark"
                text: i18n("System updated")
            }
        }
    }

    Component {
        id: infoChip

        Rectangle {
            property alias text: label.text
            property string reason: ""
            readonly property color bgColor: {
                if (reason) {
                    if (!cfg.coloredInstallReason)
                        return Kirigami.Theme.highlightColor
                    else if (reason === "explicit")
                        return Kirigami.Theme.positiveBackgroundColor
                    else if (reason === "dependency")
                        return Kirigami.Theme.neutralBackgroundColor
                    else
                        return Kirigami.Theme.negativeBackgroundColor
                }

                return Kirigami.Theme.highlightColor
            }

            radius: 10
            color: Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.3)
            implicitWidth: label.contentWidth + 16
            implicitHeight: label.contentHeight

            border.width: 1
            border.color: Qt.lighter(Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.5), 1.2)

            Label {
                id: label
                anchors.centerIn: parent
                font: Kirigami.Theme.smallFont
                color: Qt.lighter(bgColor, 3)
            }
        }
    }

    Component {
        id: versionDiffLabel

        Label {
            property string oldVer: ""
            property string newVer: ""
            property int hAlign: Text.AlignLeft

            horizontalAlignment: hAlign
            text: cfg.coloredVersionDiff ? versionDiff(oldVer, newVer) : `${oldVer} → ${newVer}`
            font: Kirigami.Theme.smallFont
            textFormat: Text.StyledText
            elide: Text.ElideRight
            opacity: 0.7

            function versionDiff(oldVer, newVer) {
                if (oldVer === newVer) return oldVer

                let i = 0

                while (i < oldVer.length &&
                    i < newVer.length &&
                    oldVer[i] === newVer[i]) {
                    ++i
                }

                const prefix = oldVer.slice(0, i)
                const oldDiff = oldVer.slice(i)
                const newDiff = newVer.slice(i)

                return `${prefix}<font color="${Kirigami.Theme.negativeTextColor}">${oldDiff}</font> → ${prefix}<font color="${Kirigami.Theme.positiveTextColor}">${newDiff}</font>`
            }
        }
    }
}
