import QtQuick 2.6
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.5 as Kirigami
import "../tools/tools.js" as JS

Kirigami.FormLayout {
    id: generalPage

    property alias cfg_interval: interval.checked
    property alias cfg_time: time.value

    property alias cfg_pacman: pacman.checked
    property alias cfg_checkupdates: checkupdates.checked
    property alias cfg_wrapper: wrapper.checked
    property alias cfg_selectedWrapper: generalPage.selectedWrapp

    property alias cfg_flatpak: flatpak.checked

    property alias cfg_wrapperUpgrade: wrapperUpgrade.checked
    property alias cfg_selectedTerminal: generalPage.selectedTerm

    property alias cfg_notifications: notifications.checked
    property alias cfg_withSound: withSound.checked
    property alias cfg_notifyStartup: notifyStartup.checked

    property alias cfg_debugging: debugging.checked
    
    property var dependencies: plasmoid.configuration.dependencies
    property var packages: plasmoid.configuration.packages
    property var wrappers: plasmoid.configuration.wrappers
    property var terminals: plasmoid.configuration.terminals

    property string selectedWrapp
    property string selectedTerm

    RowLayout {
        Kirigami.FormData.label: "Interval:"

        QQC2.CheckBox {
            id: interval
        }

        QQC2.SpinBox {
            id: time
            from: 10
            to: 1440
            stepSize: 5
            value: time
            enabled: interval.checked
        }

        QQC2.Label {
            text: 'minutes'
        }
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    RowLayout {
        Kirigami.FormData.label: "Search:"

        QQC2.ButtonGroup { id: searchGroup }

        QQC2.RadioButton {
            id: pacman
            text: 'pacman'
            checked: true
            QQC2.ButtonGroup.group: searchGroup
        }
    }

    RowLayout {
        spacing: 10

        QQC2.RadioButton {
            id: checkupdates
            text: 'checkupdates'
            enabled: !packages[1] ? false : true
            QQC2.ButtonGroup.group: searchGroup
        }

        QQC2.Label {
            id: tip
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize - 4
            text: '<a href="https://archlinux.org/packages/extra/x86_64/pacman-contrib"
                    style="color: ' + Kirigami.Theme.neutralTextColor + '">
                        Not installed
                    </a>'
            textFormat: Text.RichText
            onLinkActivated: Qt.openUrlExternally(link)
            enabled: visible
            visible: !packages[1]
        }
    }

    RowLayout {
        spacing: 10

        QQC2.RadioButton {
            id: wrapper
            text: 'wrapper'
            enabled: !wrappers ? false : true
            QQC2.ButtonGroup.group: searchGroup
        }

        QQC2.Label {
            font.pixelSize: tip.font.pixelSize
            text: '<a href="https://wiki.archlinux.org/title/AUR_helpers#Pacman_wrappers"
                    style="color: ' + Kirigami.Theme.neutralTextColor + '">
                        Not installed
                    </a>'
            textFormat: Text.RichText
            onLinkActivated: Qt.openUrlExternally(link)
            visible: !wrappers
            enabled: visible
        }

        QQC2.Label {
            font.pixelSize: tip.font.pixelSize
            color: Kirigami.Theme.positiveTextColor
            text: "found: " + selectedWrapp
            visible: wrapper.checked && wrappers.length == 1
            enabled: visible
        }
    }

    QQC2.ComboBox {
        model: wrappers
        textRole: 'name'
        enabled: wrappers
        implicitWidth: 150
        visible: wrappers && wrappers.length > 1

        onCurrentIndexChanged: {
            generalPage.selectedWrapp = model[currentIndex]['value']
        }

        Component.onCompleted: {
            if (wrappers) {
                currentIndex = JS.setIndex(plasmoid.configuration.selectedWrapper, wrappers)

                if (!plasmoid.configuration.selectedWrapper) {
                    plasmoid.configuration.selectedWrapper = model[currentIndex]['value']
                }
            }
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    RowLayout {
        QQC2.Label {
            Layout.maximumWidth: 250
            font.pixelSize: tip.font.pixelSize
            text: "If you rarely update local repository databases and don't need AUR support, it is highly recommended to use checkupdates."
            wrapMode: Text.WordWrap
        }
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    RowLayout {
        spacing: 10
        QQC2.CheckBox {
            id: flatpak
            text: 'Enable Flatpak support'
            enabled: !packages[2] ? false : true

            Component.onCompleted: {
                if (checked && !packages[2]) {
                    checked = false
                    plasmoid.configuration.flatpak = checked
                }
            }
        }

        QQC2.Label {
            font.pixelSize: tip.font.pixelSize
            text: '<a href="https://flathub.org/setup/Arch"
                    style="color: ' + Kirigami.Theme.neutralTextColor + '">
                        Not installed
                    </a>'
            textFormat: Text.RichText
            onLinkActivated: Qt.openUrlExternally(link)
            enabled: visible
            visible: !packages[2]
        }
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        Kirigami.FormData.label: "Upgrade:"

        id: wrapperUpgrade
        text: "Use wrapper instead of pacman"
        enabled: terminals &&
                 wrappers &&
                 plasmoid.configuration.selectedWrapper
    }

    RowLayout {
        QQC2.Label {
            text: "Terminal:"
        }

        QQC2.ComboBox {
            model: terminals
            textRole: 'name'
            enabled: terminals
            implicitWidth: 150

            onCurrentIndexChanged: {
                generalPage.selectedTerm = model[currentIndex]['value']
            }

            Component.onCompleted: {
                if (terminals) {
                    currentIndex = JS.setIndex(plasmoid.configuration.selectedTerminal, terminals)

                    if (!plasmoid.configuration.selectedTerminal) {
                        plasmoid.configuration.selectedTerminal = model[currentIndex]['value']
                    }
                }
            }
        }

        QQC2.Label {
            font.pixelSize: tip.font.pixelSize
            color: Kirigami.Theme.neutralTextColor
            text: "Not installed"
            enabled: visible
            visible: !terminals
        }
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    RowLayout {
        Kirigami.FormData.label: "Notifications:"

        QQC2.CheckBox {
            id: notifications
            text: "Popup"
        }
    }

    QQC2.CheckBox {
        id: withSound
        text: "Sound"
        enabled: notifications.checked
    }

    QQC2.CheckBox {
        id: notifyStartup
        text: "Notify on startup"
        enabled: notifications.checked
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    RowLayout {
        QQC2.Label {
            Layout.maximumWidth: 250
            font.pixelSize: tip.font.pixelSize
            text: "To more configure notifications visit System Settings -> Notifications -> Configure -> Apdatifier"
            wrapMode: Text.WordWrap
        }
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        Kirigami.FormData.label: "Debug mode:"
        id: debugging
        text: "Print debug info in console"
    }

    Item {
        Kirigami.FormData.isSection: true
    }
}
