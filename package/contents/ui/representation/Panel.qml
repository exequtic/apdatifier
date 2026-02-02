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

    readonly property bool counterSide: !inTray && horizontal && plasmoid.configuration.counterMode === "side"
    readonly property bool counterEnabled: plasmoid.configuration.counterMode !== "disabled"
    readonly property bool counterCenter: plasmoid.configuration.counterBadgePosition === "center"
    readonly property bool pauseBadgeEnabled: plasmoid.configuration.pauseBadgePosition !== "disabled"
    readonly property bool updatedBadgeEnabled: plasmoid.configuration.updatedBadgePosition !== "disabled"

    readonly property bool onDesktop: plasmoid.location === PlasmaCore.Types.Floating
    readonly property bool pulseActive: (plasmoid.configuration.busyIndicator === "pulse") && sts.busy && !onDesktop

    function darkColor(color) {
        return Kirigami.ColorUtils.brightnessForColor(color) === Kirigami.ColorUtils.Dark
    }
    readonly property bool isDarkText: darkColor(Kirigami.Theme.textColor)
    readonly property color lightText: isDarkText ? Kirigami.Theme.backgroundColor : Kirigami.Theme.textColor
    readonly property color darkText: isDarkText ? Kirigami.Theme.textColor : Kirigami.Theme.backgroundColor

    readonly property string errorIcon: cfg.ownIconsUI ? "status_error" : "error"
    readonly property string updatedIcon: cfg.ownIconsUI ? "status_updated" : "checkmark"
    readonly property string pausedIcon: cfg.ownIconsUI ? "toolbar_pause" : "media-playback-paused"

    readonly property real panelIconSize: horizontal ? parent.height : parent.width
    readonly property real iconSize: inTray ? Math.min(parent.width, parent.height) : panelIconSize
    readonly property real counterPixelSize: Math.max(iconSize / 4, iconSize * (cfg.counterFontSize / 10))

    implicitHeight: iconSize
    implicitWidth: viewLoader.item ? viewLoader.item.implicitWidth : iconSize

    Layout.preferredHeight: implicitHeight
    Layout.minimumHeight: implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.minimumWidth: implicitWidth

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
        sourceComponent: counterSide ? iconWithCounterSide : iconWithCounterBadge
    }

    Component {
        id: iconWithCounterSide

        RowLayout {
            implicitHeight: mouseArea.iconSize
            layoutDirection: cfg.counterSidePosition === "left" ? Qt.RightToLeft : Qt.LeftToRight
            spacing: 0
            anchors.centerIn: parent

            Item { Layout.preferredWidth: Kirigami.Units.smallSpacing + cfg.counterGapsOuter }

            Item {
                Layout.preferredHeight: mouseArea.iconSize
                Layout.preferredWidth: mouseArea.iconSize

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

                QQC.Pulse {
                    target: panelIcon
                    running: mouseArea.pulseActive
                }
            }

            Item {
                Layout.preferredWidth: cfg.counterGapsInner
                visible: counterText.visible
            }

            Label {
                id: counterText
                visible: mouseArea.counterEnabled && !sts.busy && sts.count
                font.family: plasmoid.configuration.counterFontFamily || Kirigami.Theme.defaultFont.family
                font.pixelSize: Math.round(mouseArea.counterPixelSize)
                font.bold: cfg.counterFontBold
                fontSizeMode: Text.FixedSize
                text: sts.count
            }

            Item { Layout.preferredWidth: Kirigami.Units.smallSpacing + cfg.counterGapsOuter }
        }
    }

    Component {
        id: iconWithCounterBadge

        Item {
            implicitWidth: mouseArea.iconSize
            implicitHeight: mouseArea.iconSize

            Item {
                width: mouseArea.iconSize
                height: mouseArea.iconSize
                anchors.centerIn: parent

                Kirigami.Icon {
                    id: trayIcon
                    anchors.fill: parent
                    source: JS.setIcon(plasmoid.icon)
                    active: mouseArea.containsMouse

                    layer.enabled: sts.error
                    layer.effect: sts.error ? errorShadowEffect : null
                }

                QQC.Pulse {
                    target: trayIcon
                    running: mouseArea.pulseActive
                }

                Rectangle {
                    id: frame
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    opacity: 0
                }

                Rectangle {
                    id: counterFrame
                    width: mouseArea.counterCenter ? frame.width : counter.implicitWidth + 2
                    height: mouseArea.counterCenter ? frame.height : counter.implicitHeight
                    radius: cfg.counterRadius
                    opacity: cfg.counterOpacity / 10
                    color: cfg.counterColor ? cfg.counterColor : Kirigami.Theme.backgroundColor
                    visible: mouseArea.counterEnabled && !sts.busy && sts.count

                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 0
                        radius: 2
                        samples: radius * 2
                        color: Qt.rgba(0, 0, 0, 0.5)
                    }

                    state: cfg.counterBadgePosition
            
                    states: [
                        State { name: "center";      AnchorChanges { target: counterFrame; anchors.horizontalCenter: frame.horizontalCenter; anchors.verticalCenter: frame.verticalCenter } },
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
                    font.pixelSize: Math.round(mouseArea.counterPixelSize)
                    font.bold: cfg.counterFontBold
                    color: cfg.counterColor ? (mouseArea.darkColor(counterFrame.color) ? mouseArea.lightText : mouseArea.darkText) : Kirigami.Theme.textColor
                    visible: counterFrame.visible
                }

                Loader {
                    anchors.fill: parent
                    sourceComponent: badgesLayer
                    active: sts.init
                }
            }
        }
    }

    Component {
        id: badgesLayer

        Item {
            anchors.fill: parent

            QQC.Badge {
                iconName: updatedIcon
                position: cfg.updatedBadgePosition
                iconColor: Kirigami.Theme.positiveTextColor
                visible: !sts.busy && !sts.count && updatedBadgeEnabled
            }
            QQC.Badge {
                iconName: pausedIcon
                position: cfg.pauseBadgePosition
                iconColor: Kirigami.Theme.neutralTextColor
                visible: sts.paused && pauseBadgeEnabled
            }
        }
    }

    Component {
        id: errorShadowEffect
        DropShadow {
            horizontalOffset: 0
            verticalOffset: 0
            radius: 6
            samples: 16
            color: "red"
            spread: 0.35
            // transparentBorder: true
        }
    }
}
