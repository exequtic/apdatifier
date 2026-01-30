import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components

ToolButton {
    property string tooltipText: ""
    property string iconSource: ""
    property color iconColor: Kirigami.Theme.colorSet
    property alias buttonTooltip: tooltip

    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
    hoverEnabled: enabled
    highlighted: enabled

    ToolTip {
        id: tooltip
        text: tooltipText
    }

    Kirigami.Icon {
        height: parent.height
        width: parent.height
        anchors.centerIn: parent
        source: iconSource
        color: iconColor
        scale: cfg.ownIconsUI ? 0.7 : 0.9
        isMask: cfg.ownIconsUI
        smooth: true
    }
}
