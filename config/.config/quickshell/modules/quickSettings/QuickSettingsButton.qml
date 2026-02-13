pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import "../../components/"

BarButton {
    id: root

    readonly property var hostScreen: QsWindow.window?.screen ?? null
    readonly property var hostMonitor: hostScreen ? Hyprland.monitorFor(hostScreen) : null
    readonly property bool shouldPublishAnchor: {
        const focused = Hyprland.focusedMonitor;
        if (!focused || !hostMonitor)
            return true;
        return focused.name === hostMonitor.name;
    }

    function syncOsdAnchor() {
        if (!shouldPublishAnchor && OsdService.anchorX > 0 && OsdService.anchorY > 0)
            return;

        const bottomCenter = root.mapToGlobal(root.width / 2, root.height);
        OsdService.anchorX = bottomCenter.x;
        OsdService.anchorY = bottomCenter.y;
    }

    active: quickSettingsWindow.visible
    contentItem: iconsLayout
    onClicked: quickSettingsWindow.visible = !quickSettingsWindow.visible
    Component.onCompleted: Qt.callLater(syncOsdAnchor)
    onXChanged: Qt.callLater(syncOsdAnchor)
    onYChanged: Qt.callLater(syncOsdAnchor)
    onWidthChanged: Qt.callLater(syncOsdAnchor)
    onHeightChanged: Qt.callLater(syncOsdAnchor)

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.syncOsdAnchor()
    }

    RowLayout {
        id: iconsLayout
        anchors.centerIn: parent
        spacing: Config.spacing + 1

        property color iconColor: root.active ? Config.accentColor : Config.textColor
        readonly property bool bluetoothOutput: AudioService.outputDeviceType === "bluetooth"
        readonly property bool headphoneOutput: AudioService.outputDeviceType === "headphones"
        readonly property bool speakerOutput: !bluetoothOutput && !headphoneOutput
        readonly property bool outputSilent: AudioService.muted || AudioService.volume <= 0.001

        function outputIcon() {
            if (speakerOutput && outputSilent)
                return "󰖁";
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
                text: iconsLayout.outputIcon()
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal + 1
                font.bold: true
                color: iconsLayout.outputSilent ? Config.mutedColor : iconsLayout.iconColor

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
