import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.extras
import org.kde.plasma.components
import org.kde.kirigami as Kirigami

ColumnLayout {
    Loader {
        Layout.maximumWidth: parent.width - (Kirigami.Units.largeSpacing * 4)
        anchors.centerIn: parent
        active: sts.updated
        sourceComponent: Kirigami.PlaceholderMessage {
            width: parent.width - (Kirigami.Units.largeSpacing * 4)
            icon.name: "checkmark"
            text: i18n("System updated")
        }
    }

    Loader {
        Layout.maximumWidth: parent.width - (Kirigami.Units.largeSpacing * 4)
        anchors.centerIn: parent
        active: !sts.busy && sts.err
        sourceComponent: Kirigami.PlaceholderMessage {
            icon.name: "error"
            text: sts.statusMsg
            explanation: sts.errMsg
        }
    }

    Loader {
        Layout.maximumWidth: parent.width - (Kirigami.Units.largeSpacing * 4)
        anchors.centerIn: parent
        active: sts.busy
        sourceComponent: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing * 4

            BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 128
                Layout.preferredHeight: 128
                opacity: 0.6
                running: true
            }

            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                visible: !cfg.showStatusText

                ToolButton {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    hoverEnabled: false
                    highlighted: false
                    enabled: false
                    Kirigami.Icon {
                        height: parent.height
                        width: parent.height
                        anchors.centerIn: parent
                        source: cfg.ownIconsUI ? svg(statusIcon) : statusIcon
                        color: Kirigami.Theme.colorSet
                        scale: cfg.ownIconsUI ? 0.7 : 0.9
                        isMask: cfg.ownIconsUI
                        smooth: true
                    }
                }

                DescriptiveLabel {
                    text: sts.statusMsg
                    font.bold: true
                }
            }
        }
    }
}
