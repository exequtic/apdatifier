/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.plasma.components
import org.kde.kirigami as Kirigami

import "../../tools/tools.js" as JS
import "../components"

ScrollView {
    id: view
    ScrollBar.vertical.policy: (sts.count === 0 || sts.busy || sts.err) ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded
    ListView {
        model: modelList
        delegate: GridLayout {
            visible: sts.pending
            property var heightItem: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.5)
            property var column: view.width / 2
            height: heightItem + cfg.spacing
            Rectangle {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                height: heightItem
                width: height
                color: "transparent"
                Kirigami.Icon {
                    anchors.centerIn: parent
                    height: heightItem
                    width: height
                    source: !hoverIcon.containsMouse ? model.IC : "edit-download"
                }
                MouseArea {
                    id: hoverIcon
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: JS.upgradePackage(model.NM, model.ID, model.CN)
                }
            }
            Label {
                Layout.minimumWidth: column
                Layout.maximumWidth: column
                text: model.NM
                elide: Text.ElideRight
            }
            Label {
                Layout.minimumWidth: column
                Layout.maximumWidth: column
                text: model.RE + " → " + model.VN
                elide: Text.ElideRight
            }
        }

        Placeholder {
            anchors.fill: parent
        }
    }
}
