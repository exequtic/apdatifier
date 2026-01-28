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

    readonly property bool horizontal: plasmoid.location === PlasmaCore.Types.TopEdge || plasmoid.location === PlasmaCore.Types.BottomEdge

    readonly property real trayIconSize: horizontal ? height : width

    readonly property bool counterOverlay: inTray || !horizontal
    readonly property bool counterRow: !inTray && horizontal

    readonly property bool counterEnabled: plasmoid.configuration.counterPosition !== "disabled"
    readonly property bool counterCenter: plasmoid.configuration.counterPosition === "center"
    readonly property bool pauseBadgeEnabled: plasmoid.configuration.pauseBadgePosition !== "disabled"
    readonly property bool updatedBadgeEnabled: plasmoid.configuration.updatedBadgePosition !== "disabled"

    function darkColor(color) {
        return Kirigami.ColorUtils.brightnessForColor(color) === Kirigami.ColorUtils.Dark
    }
    readonly property bool isDarkText: darkColor(Kirigami.Theme.textColor)
    readonly property color lightText: isDarkText ? Kirigami.Theme.backgroundColor : Kirigami.Theme.textColor
    readonly property color darkText: isDarkText ? Kirigami.Theme.textColor : Kirigami.Theme.backgroundColor

    readonly property string errorIcon: cfg.ownIconsUI ? "status_error" : "error"
    readonly property string updatedIcon: cfg.ownIconsUI ? "status_updated" : "checkmark"
    readonly property string pausedIcon: cfg.ownIconsUI ? "toolbar_pause" : "media-playback-paused"

    Layout.preferredWidth: counterOverlay ? trayIconSize : (viewLoader.item ? viewLoader.item.implicitWidth : trayIconSize)

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

    Loader {
        id: viewLoader
        anchors.fill: parent
        sourceComponent: counterRow ? panelRow : overlay
    }

    Component {
        id: panelRow

        RowLayout {
            id: panelRow
            layoutDirection: cfg.counterOnLeft ? Qt.RightToLeft : Qt.LeftToRight
            spacing: 0
            anchors.centerIn: parent

            Item { Layout.preferredWidth: Kirigami.Units.smallSpacing + cfg.counterMargins }

            Item {
                Layout.preferredHeight: mouseArea.height
                Layout.preferredWidth: mouseArea.height

                Kirigami.Icon {
                    id: panelIcon
                    width: parent.width
                    height: parent.height
                    source: JS.setIcon(plasmoid.icon)
                    active: mouseArea.containsMouse

                    layer.enabled: sts.error
                    layer.effect: sts.error ? errorShadowEffect : null

                    Loader {
                        anchors.fill: parent
                        sourceComponent: badgesLayer
                        active: sts.init
                    }
                }
            }

            Item {
                Layout.preferredWidth: cfg.counterSpacing
                visible: counterText.visible
            }

            Label {
                id: counterText
                visible: mouseArea.counterEnabled && !sts.busy && sts.count
                font.family: plasmoid.configuration.counterFontFamily || Kirigami.Theme.defaultFont.family
                font.pixelSize: mouseArea.height * (cfg.counterFontSize / 10)
                font.bold: cfg.counterFontBold
                fontSizeMode: Text.FixedSize
                antialiasing: true
                text: sts.count
            }

            Item { Layout.preferredWidth: Kirigami.Units.smallSpacing + cfg.counterMargins }
        }
    }

    Component {
        id: overlay

        Item {
            anchors.fill: parent

            Kirigami.Icon {
                id: trayIcon
                anchors.fill: parent
                source: JS.setIcon(plasmoid.icon)
                active: mouseArea.containsMouse

                layer.enabled: sts.error
                layer.effect: sts.error ? errorShadowEffect : null
            }

            Rectangle {
                id: frame
                anchors.centerIn: trayIcon
                width: mouseArea.trayIconSize
                height: mouseArea.trayIconSize
                opacity: 0
            }

            Rectangle {
                id: counterFrame
                width: mouseArea.counterCenter ? frame.width : counter.width + 2
                height: mouseArea.counterCenter ? frame.height : counter.height
                radius: cfg.counterRadius
                opacity: cfg.counterOpacity / 10
                color: cfg.counterColor ? cfg.counterColor : Kirigami.Theme.backgroundColor
                visible: mouseArea.counterEnabled && !sts.busy && sts.count

                layer.enabled: cfg.counterShadow
                layer.effect: cfg.counterShadow ? counterShadowEffect : null

                state: cfg.counterPosition

                states: [
                    State { name: "topLeft";     AnchorChanges { target: counterFrame; anchors.top: frame.top; anchors.left: frame.left } },
                    State { name: "topRight";    AnchorChanges { target: counterFrame; anchors.top: frame.top; anchors.right: frame.right } },
                    State { name: "bottomLeft";  AnchorChanges { target: counterFrame; anchors.bottom: frame.bottom; anchors.left: frame.left } },
                    State { name: "bottomRight"; AnchorChanges { target: counterFrame; anchors.bottom: frame.bottom; anchors.right: frame.right } }
                ]

                anchors {
                    topMargin:    state.includes("top") ? cfg.counterOffsetX : 0
                    leftMargin:   state.includes("Left") ? cfg.counterOffsetY : 0
                    rightMargin:  state.includes("Right") ? cfg.counterOffsetY : 0
                    bottomMargin: state.includes("bottom") ? cfg.counterOffsetX : 0
                }

                transitions: Transition { AnchorAnimation { duration: 120 } }
            }

            Label {
                id: counter
                anchors.centerIn: counterFrame
                text: sts.count
                font.family: plasmoid.configuration.counterFontFamily || Kirigami.Theme.defaultFont.family
                font.pixelSize: Math.max(trayIcon.height / 4, Kirigami.Theme.smallFont.pixelSize + cfg.counterSize)
                font.bold: cfg.counterFontBold
                color: cfg.counterColor
                    ? (mouseArea.darkColor(counterFrame.color) ? mouseArea.lightText : mouseArea.darkText)
                    : Kirigami.Theme.textColor
                antialiasing: true
                visible: counterFrame.visible
            }

            Loader {
                anchors.fill: parent
                sourceComponent: badgesLayer
                active: sts.init
            }
        }
    }

    Component {
        id: badgesLayer

        Item {
            anchors.fill: parent

            QQC.Badge {
                iconName: updatedIcon
                iconColor: Kirigami.Theme.positiveTextColor
                visible: !sts.busy && !sts.count && updatedBadgeEnabled
            }
            QQC.Badge {
                iconName: pausedIcon
                iconColor: Kirigami.Theme.neutralTextColor
                visible: sts.paused && pauseBadgeEnabled
            }
        }
    }

    Component {
        id: counterShadowEffect
        DropShadow {
            horizontalOffset: 0
            verticalOffset: 0
            radius: 2
            samples: radius * 2
            color: Qt.rgba(0, 0, 0, 0.5)
        }
    }

    Component {
        id: errorShadowEffect
        DropShadow {
            horizontalOffset: 0
            verticalOffset: 0
            radius: 8
            samples: 16
            color: "red"
            spread: 0.35
            // transparentBorder: true
        }
    }
}
