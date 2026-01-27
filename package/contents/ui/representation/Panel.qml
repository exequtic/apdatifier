/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import Qt5Compat.GraphicalEffects

import "../components" as QQC
import "../../tools/tools.js" as JS

MouseArea {
    id: mouseArea

    property bool wasExpanded: false
    property bool horizontal: plasmoid.location === 3 || plasmoid.location === 4
    property int trayIconSize: horizontal ? trayIcon.width : trayIcon.height
    property bool counterOverlay: inTray || !horizontal
    property bool counterRow: !inTray && horizontal

    property bool counterEnabled: plasmoid.configuration.counterPosition !== "disabled"
    property bool counterCenter: plasmoid.configuration.counterPosition === "center"
    property bool pauseBadgeEnabled: plasmoid.configuration.pauseBadgePosition !== "disabled"
    property bool updatedBadgeEnabled: plasmoid.configuration.updatedBadgePosition !== "disabled"

    function darkColor(color) {
        return Kirigami.ColorUtils.brightnessForColor(color) === Kirigami.ColorUtils.Dark
    }
    property var isDarkText: darkColor(Kirigami.Theme.textColor)
    property var lightText: isDarkText ? Kirigami.Theme.backgroundColor : Kirigami.Theme.textColor
    property var darkText: isDarkText ? Kirigami.Theme.textColor : Kirigami.Theme.backgroundColor

    property var errorIcon: cfg.ownIconsUI ? "status_error" : "error"
    property var updatedIcon: cfg.ownIconsUI ? "status_updated" : "checkmark"
    property var pausedIcon: cfg.ownIconsUI ? "toolbar_pause" : "media-playback-paused"

    Layout.preferredWidth: counterOverlay ? trayIcon.width : panelRow.width

    hoverEnabled: true
    acceptedButtons: cfg.rightAction ? Qt.AllButtons : Qt.LeftButton | Qt.MiddleButton

    onEntered: sts.checktime = JS.getCheckTime()

    onPressed: mouse => {
        wasExpanded = expanded
        if (!cfg.rightAction && mouse.button == Qt.RightButton) mouse.accepted = false
    }

    onClicked: mouse => {
        if (mouse.button == Qt.LeftButton) expanded = !wasExpanded
        if (mouse.button == Qt.MiddleButton && cfg.middleAction) JS[cfg.middleAction]()
        if (mouse.button == Qt.RightButton && cfg.rightAction) JS[cfg.rightAction]()
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            if (scrollTimer.running) return
            scrollTimer.start()
            var action = event.angleDelta.y > 0 ? cfg.scrollUpAction : cfg.scrollDownAction
            if (!action) return
            JS[action]()
        }
    }

    Timer {
        id: scrollTimer
        interval: 500
    }

    RowLayout {
        id: panelRow

        layoutDirection: cfg.counterOnLeft ? Qt.RightToLeft : Qt.LeftToRight
        visible: counterRow
        spacing: 0
        anchors.centerIn: mouseArea

        Item {
            Layout.preferredWidth: Kirigami.Units.smallSpacing + cfg.counterMargins
        }

        Item {
            Layout.preferredHeight: mouseArea.height
            Layout.preferredWidth: mouseArea.height

            Kirigami.Icon {
                id: panelIcon
                width: parent.width
                height: parent.height
                source: JS.setIcon(plasmoid.icon)
                active: mouseArea.containsMouse

                QQC.Badge {
                    iconName: errorIcon
                    iconColor: Kirigami.Theme.negativeTextColor
                    visible: sts.error
                }
                QQC.Badge {
                    iconName: updatedIcon
                    iconColor: Kirigami.Theme.positiveTextColor
                    visible: sts.updated && updatedBadgeEnabled
                }
                QQC.Badge {
                    iconName: pausedIcon
                    iconColor: Kirigami.Theme.neutralTextColor
                    visible: sts.paused && cfg.checkMode !== "manual" && pauseBadgeEnabled
                }
            }
        }
        Item {
            Layout.preferredWidth: cfg.counterSpacing
            visible: counterText.visible
        }
        Label {
            id: counterText
            visible: counterEnabled && sts.pending
            font.family: plasmoid.configuration.counterFontFamily || Kirigami.Theme.defaultFont
            font.pixelSize: mouseArea.height * (cfg.counterFontSize / 10)
            font.bold: cfg.counterFontBold
            fontSizeMode: Text.FixedSize
            smooth: true
            text: sts.count
        }

        Item {
            Layout.preferredWidth: Kirigami.Units.smallSpacing + cfg.counterMargins
        }
    }

    Kirigami.Icon {
        id: trayIcon
        anchors.fill: parent
        source: JS.setIcon(plasmoid.icon)
        active: mouseArea.containsMouse
        visible: counterOverlay
    }

    Rectangle {
        id: frame
        anchors.centerIn: trayIcon
        width: trayIconSize + cfg.counterOffsetX
        height: trayIconSize + cfg.counterOffsetY
        opacity: 0
        visible: counterOverlay
    }

    Rectangle {
        id: counterFrame
        width: counterCenter ? frame.width : counter.width + 2
        height: counterCenter ? frame.height : counter.height
        radius: cfg.counterRadius
        opacity: cfg.counterOpacity / 10
        color: cfg.counterColor ? cfg.counterColor : Kirigami.Theme.backgroundColor
        visible: counterOverlay && counterEnabled && sts.pending

        layer.enabled: cfg.counterShadow
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 0
            radius: 2
            samples: radius * 2
            color: Qt.rgba(0, 0, 0, 0.5)
        }

        states: [
            State {
                when: cfg.counterPosition === "topLeft"
                AnchorChanges { target: counterFrame; anchors.top: frame.top; anchors.left: frame.left }
            },
            State {
                when: cfg.counterPosition === "topRight"
                AnchorChanges { target: counterFrame; anchors.top: frame.top; anchors.right: frame.right }
            },
            State {
                when: cfg.counterPosition === "bottomLeft"
                AnchorChanges { target: counterFrame; anchors.bottom: frame.bottom; anchors.left: frame.left }
            },
            State {
                when: cfg.counterPosition === "bottomRight"
                AnchorChanges { target: counterFrame; anchors.bottom: frame.bottom; anchors.right: frame.right }
            }
        ]

        transitions: Transition {
            AnchorAnimation { duration: 120 }
        }
    }

    Label {
        id: counter
        anchors.centerIn: counterFrame
        text: sts.count
        font.family: plasmoid.configuration.counterFontFamily || Kirigami.Theme.defaultFont
        font.pixelSize: Math.max(trayIcon.height / 4, Kirigami.Theme.smallFont.pixelSize + cfg.counterSize)
        font.bold: cfg.counterFontBold
        color: cfg.counterColor ? darkColor(counterFrame.color) ? lightText : darkText : Kirigami.Theme.textColor
        smooth: true
        visible: counterFrame.visible
    }

    QQC.Badge {
        iconName: errorIcon
        iconColor: Kirigami.Theme.negativeTextColor
        visible: counterOverlay && sts.error
    }
    QQC.Badge {
        iconName: updatedIcon
        iconColor: Kirigami.Theme.positiveTextColor
        visible: counterOverlay && sts.updated && updatedBadgeEnabled
    }
    QQC.Badge {
        iconName: pausedIcon
        iconColor: Kirigami.Theme.neutralTextColor
        visible: counterOverlay && sts.paused && cfg.checkMode !== "manual" && pauseBadgeEnabled
    }
}
