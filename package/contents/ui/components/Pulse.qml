import QtQuick

Item {
    id: root

    required property Item target
    required property bool running

    property real scaleTo: 1.20
    property real opacityTo: 0.60
    property int duration: 400

    onRunningChanged: {
        if (!running && target) {
            target.scale = 1
            target.opacity = 1
        }
    }

    SequentialAnimation {
        id: scaleAnimation
        running: root.running
        loops: Animation.Infinite

        NumberAnimation {
            target: root.target
            property: "scale"
            to: root.scaleTo
            duration: root.duration
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root.target
            property: "scale"
            to: 1.00
            duration: root.duration
            easing.type: Easing.InOutQuad
        }
    }

    SequentialAnimation {
        id: opacityAnimation
        running: root.running
        loops: Animation.Infinite

        NumberAnimation {
            target: root.target
            property: "opacity"
            to: root.opacityTo
            duration: root.duration
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root.target
            property: "opacity"
            to: 1.00
            duration: root.duration
            easing.type: Easing.InOutQuad
        }
    }
}
