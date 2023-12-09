import QtQuick 2.6
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.5 as Kirigami
import "../tools/tools.js" as JS

Kirigami.FormLayout {
    id: generalPage

    property alias cfg_interval: interval.checked
    property alias cfg_time: time.value
    property alias cfg_flatpak: flatpak.checked
    property alias cfg_pacman: pacman.checked
    property alias cfg_checkupdates: checkupdates.checked
    property alias cfg_wrapper: wrapper.checked

    property var selectedWrapper: plasmoid.configuration.selectedWrapper
    property var dependencies: plasmoid.configuration.dependencies
    property var packages: plasmoid.configuration.packages
    property var wrappers: plasmoid.configuration.wrappers

    property alias cfg_wrapperIndex: generalPage.indexWrapper
    property int indexWrapper


    RowLayout {
        Layout.fillWidth: true

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
        spacing: 15
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
            font.italic: true
            font.pixelSize: 12
            text: '<a href="https://flathub.org/setup/Arch" style="color: ' + Kirigami.Theme.negativeTextColor + '">not installed</a>'
            textFormat: Text.RichText
            onLinkActivated: Qt.openUrlExternally(link)
            enabled: visible
            visible: !packages[2]
        }
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    RowLayout {
        Layout.fillWidth: true

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
        spacing: 15
        QQC2.RadioButton {
            id: checkupdates
            text: 'checkupdates'
            enabled: !packages[1] ? false : true
            QQC2.ButtonGroup.group: searchGroup
        }

        QQC2.Label {
            font.italic: true
            font.pixelSize: 12
            text: '<a href="https://archlinux.org/packages/extra/x86_64/pacman-contrib" style="color: ' + Kirigami.Theme.negativeTextColor + '">not installed</a>'
            textFormat: Text.RichText
            onLinkActivated: Qt.openUrlExternally(link)
            enabled: visible
            visible: !packages[1]
        }
    }

    RowLayout {
        spacing: 15
        QQC2.RadioButton {
            id: wrapper
            text: 'wrapper'
            enabled: !wrappers ? false : true
            QQC2.ButtonGroup.group: searchGroup
        }

        QQC2.Label {
            font.italic: true
            font.pixelSize: 12
            text: '<a href="https://wiki.archlinux.org/title/AUR_helpers#Pacman_wrappers" style="color: ' + Kirigami.Theme.negativeTextColor + '">not installed</a>'
            textFormat: Text.RichText
            onLinkActivated: Qt.openUrlExternally(link)
            visible: !wrappers
            enabled: visible
        }

        QQC2.Label {
            font.italic: true
            font.pixelSize: 12
            color: Kirigami.Theme.positiveTextColor
            text: "found: " + selectedWrapper
            visible: wrapper.checked && wrappers.length == 1
            enabled: visible
        }
    }

    QQC2.ComboBox {
        model: wrappers
        textRole: 'name'
        enabled: wrapper.checked
        implicitWidth: 150
        visible: wrappers && wrappers.length > 1

        onCurrentIndexChanged: {
            plasmoid.configuration.selectedWrapper = model[currentIndex]['value']
            generalPage.indexWrapper = currentIndex
        }

        Component.onCompleted: {
            if (wrappers) {
                currentIndex = JS.setIndex(selectedWrapper, wrappers)
                currentIndex = JS.setIndexInit(plasmoid.configuration.wrapperIndex)
            }
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    QQC2.Label {
        Layout.maximumWidth: 250
        font.italic: true
        font.pixelSize: 12
        text: "If you rarely update local repository databases and don't need AUR support, it is recommended to use checkupdates, as it uses databases that are automatically updated."
        wrapMode: Text.WordWrap
    }
}
