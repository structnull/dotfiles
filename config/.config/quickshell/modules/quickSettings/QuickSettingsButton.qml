pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import "../../components/"

BarButton {
    id: root

    active: quickSettingsWindow.visible
    contentItem: iconsLayout
    onClicked: quickSettingsWindow.visible = !quickSettingsWindow.visible

    RowLayout {
        id: iconsLayout
        anchors.centerIn: parent
        spacing: Config.spacing + 1

        property color iconColor: root.active ? Config.accentColor : Config.textColor
        readonly property bool bluetoothOutput: AudioService.outputDeviceType === "bluetooth"
        readonly property bool headphoneOutput: AudioService.outputDeviceType === "headphones"

        function outputIcon() {
            if (bluetoothOutput)
                return "";
            if (headphoneOutput)
                return "";
            return "󰕾";
        }

        function sourceIcon() {
            if (AudioService.sourceMuted)
                return "";
            return "";
        }

        Behavior on iconColor {
            ColorAnimation {
                duration: Config.animDuration
            }
        }

        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: AudioService.muted ? "󰟎" : iconsLayout.outputIcon()
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal + 1
                font.bold: true
                color: AudioService.muted ? Config.mutedColor : iconsLayout.iconColor

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }
            }

            Text {
                text: "•"
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                color: Qt.alpha(Config.mutedColor, 0.7)
            }

            Text {
                text: iconsLayout.sourceIcon()
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
                font.bold: true
                color: AudioService.sourceMuted ? Config.mutedColor : Qt.alpha(iconsLayout.iconColor, 0.9)

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }
            }
        }

        Text {
            visible: CaffeineService.enabled
            text: ""
            font.family: Config.font
            font.pixelSize: Config.fontSizeNormal
            font.bold: true
            color: Qt.alpha(iconsLayout.iconColor, 0.92)
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: Config.animDuration
                }
            }
        }

        WifiIcon {
            color: iconsLayout.iconColor
        }
    }

    QuickSettingsWindow {
        id: quickSettingsWindow
        visible: false
        anchorItem: root
    }
}
