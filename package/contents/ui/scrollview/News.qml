import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

import org.kde.plasma.components
import org.kde.kirigami as Kirigami

import "../../tools/tools.js" as JS

ScrollView {
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ListView {
        model: newsModel
        spacing: Kirigami.Units.largeSpacing * 2
        topMargin: spacing
        rightMargin: spacing
        leftMargin: spacing
        bottomMargin: spacing

        delegate: Kirigami.AbstractCard {
            contentItem: Item {
                implicitWidth: delegateLayout.implicitWidth
                implicitHeight: delegateLayout.implicitHeight
                GridLayout {
                    id: delegateLayout
                    anchors {
                        left: parent.left
                        top: parent.top
                        right: parent.right
                    }
                    rowSpacing: Kirigami.Units.largeSpacing
                    columnSpacing: Kirigami.Units.largeSpacing
                    columns: width > Kirigami.Units.gridUnit * 20 ? 4 : 2
                    opacity: model.removed ? 0.5 : 1.0
                    Kirigami.Icon {
                        Layout.fillHeight: true
                        Layout.maximumHeight: Kirigami.Units.iconSizes.huge
                        Layout.preferredWidth: height
                        source: model.title.includes("Arch")        ? "apdatifier-plasmoid" :
                                model.title.includes("Plasma")      ? "note-symbolic" :
                                model.title.includes("Apps")        ? "applications-all-symbolic" :
                                model.title.includes("Community")   ? "start-here-kde-plasma-symbolic"
                                                                    : "news-subscribe"
                    }

                    RowLayout {
                        ColumnLayout {
                            Controls.Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: model.title
                                font.bold: true
                            }
                            Controls.Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: Qt.locale(Qt.locale().name).toString(
                                    new Date(model.timestamp * 1000),
                                    "dd MMMM yyyy, HH:mm"
                                )
                                opacity: 0.6
                            }
                            Kirigami.Separator {
                                Layout.fillWidth: true
                            }
                            Controls.Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: model.article
                            }
                        }

                        ColumnLayout {
                            Controls.Button {
                                ToolTip { id: tip; text: i18n("Read article") }
                                icon.name: "internet-web-browser-symbolic"
                                onClicked: {
                                    tip.hide()
                                    Qt.openUrlExternally(model.link)
                                    JS.removeNewsItem(index)
                                }
                            }
                            Controls.Button {
                                visible: !model.removed
                                ToolTip { text: i18n("Mark as read") }
                                icon.name: model.removed ? "backup" : "delete"
                                onClicked: JS.removeNewsItem(index)
                            }
                        }
                    }
                }
            }
        }

        Loader {
            width: parent.width
            active: sts.busy && (sts.statusIco === "status_news" || sts.statusIco === "news-subscribe")
            sourceComponent: ProgressBar { from: 0; to: 100; indeterminate: true }
        }
        Loader {
            anchors.centerIn: parent
            active: newsModel.count === 0
            sourceComponent: Kirigami.PlaceholderMessage {
                icon.name: "news-subscribe"
                text: i18n("No unread news")
            }
        }

        add: Transition { animations: [ NumberAnimation { properties: popin ? "opacity,scale" : "opacity"; from: 0; to: 1; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.12 } ] }
        addDisplaced: Transition { animations: [
            NumberAnimation { property: "y"; duration: 340; easing.type: Easing.OutCubic },
            NumberAnimation { properties: popin ? "opacity,scale" : "opacity"; to: 1; duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.08 }
        ] }
        displaced: Transition { animations: [
            NumberAnimation { property: "y"; duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.05 },
            NumberAnimation { properties: "opacity,scale"; to: 1; duration: 260; easing.type: Easing.OutQuad }
        ] }
        move: Transition { animations: [
            NumberAnimation { property: "y"; duration: 360; easing.type: Easing.OutBack; easing.overshoot: 1.06 },
            NumberAnimation { properties: "opacity,scale"; to: 1; duration: 260; easing.type: Easing.OutQuad }
        ] }
        moveDisplaced: Transition { animations: [
            NumberAnimation { property: "y"; duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.04 },
            NumberAnimation { properties: "opacity,scale"; to: 1; duration: 260; easing.type: Easing.OutQuad }
        ] }
        remove: Transition { animations: [
            NumberAnimation { property: "x"; to: width + 120; duration: 300; easing.type: Easing.InBack; easing.overshoot: 1.15 },
            NumberAnimation { property: "opacity"; to: 0; duration: 240; easing.type: Easing.InQuad },
            NumberAnimation { property: "scale"; to: 0.92; duration: 300; easing.type: Easing.InBack }
        ] }
        removeDisplaced: Transition { animations: [
            NumberAnimation { property: "y"; duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.03 },
            NumberAnimation { properties: "opacity,scale"; to: 1; duration: 260; easing.type: Easing.OutQuad }
        ] }
    }
}
