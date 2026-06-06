pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
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

    property bool popupLoaded: false
    property bool volumePopupVisible: false
    property bool volumeWheelSuppressingOsd: false
    property real volumePopupX: 0
    property real volumePopupY: 0
    readonly property var popupWindow: quickSettingsLoader.item

    readonly property real barVolumeValue: AudioService.volumeKnown ? AudioService.volume : 0
    readonly property int barVolumePercent: Math.round(Math.max(0, Math.min(1.5, barVolumeValue)) * 100)

    function togglePopup() {
        if (popupWindow) {
            if (popupWindow.visible)
                popupWindow.closeWindow();
            else
                popupWindow.visible = true;
            return;
        }

        popupLoaded = true;
    }

    function showVolumePopup() {
        const pos = outputIconCell.mapToGlobal(outputIconCell.width / 2, outputIconCell.height);
        volumePopupX = pos.x;
        volumePopupY = pos.y;
        volumePopupVisible = true;
        volumePopupTimer.restart();
    }

    function suppressVolumeOsdForWheel() {
        if (!OsdService.suppressed) {
            volumeWheelSuppressingOsd = true;
            OsdService.suppressed = true;
        }

        volumeOsdSuppressTimer.restart();
    }

    function changeVolumeFromWheel(deltaY) {
        const direction = deltaY > 0 ? 1 : -1;
        const current = AudioService.volumeKnown ? AudioService.volume : 0;
        const next = Math.max(0, Math.min(1.5, current + (direction * 0.05)));
        suppressVolumeOsdForWheel();
        AudioService.setVolume(next);
        showVolumePopup();
    }

    active: popupWindow?.visible ?? false
    contentItem: iconsLayout
    onClicked: togglePopup()
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
        readonly property bool outputSilent: AudioService.outputSilent

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
                id: outputIconCell
                text: iconsLayout.outputIcon()
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal + 1
                font.bold: true
                color: iconsLayout.outputSilent ? Config.mutedColor : iconsLayout.iconColor
                Layout.alignment: Qt.AlignVCenter
                z: 20

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y;
                        root.changeVolumeFromWheel(delta);
                        event.accepted = true;
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

    Loader {
        id: quickSettingsLoader
        active: root.popupLoaded
        asynchronous: true
        source: "./QuickSettingsWindow.qml"

        onLoaded: {
            item.anchorItem = root;
            item.visible = true;
        }
    }

    Connections {
        target: root.popupWindow

        function onVisibleChanged() {
            if (root.popupWindow && !root.popupWindow.visible)
                root.popupLoaded = false;
        }
    }

    Timer {
        id: volumePopupTimer
        interval: 900
        repeat: false
        onTriggered: root.volumePopupVisible = false
    }

    Timer {
        id: volumeOsdSuppressTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (!root.volumeWheelSuppressingOsd)
                return;

            root.volumeWheelSuppressingOsd = false;
            if (!(root.popupWindow?.visible ?? false))
                OsdService.suppressed = false;
        }
    }

    PanelWindow {
        id: volumeHoverPopup
        visible: root.volumePopupVisible || popupContent.popupProgress > 0.01
        implicitWidth: popupContent.width
        implicitHeight: popupContent.height
        color: "transparent"
        screen: root.hostScreen

        anchors {
            top: true
            left: true
        }

        margins.left: {
            const screenWidth = screen ? screen.width : 1920;
            const screenOffsetX = screen ? screen.x : 0;
            const localX = root.volumePopupX - screenOffsetX;
            return Math.max(8, Math.min(screenWidth - popupContent.width - 8, localX - (popupContent.width / 2)));
        }
        margins.top: {
            const screenOffsetY = screen ? screen.y : 0;
            return (root.volumePopupY - screenOffsetY) + 8;
        }

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs_modules"

        Rectangle {
            id: popupContent
            property real popupProgress: root.volumePopupVisible ? 1.0 : 0.0

            width: percentText.implicitWidth + 22
            height: 28
            radius: height / 2
            color: Config.backgroundTransparentColor
            border.width: 1
            border.color: Qt.alpha(Config.textColor, 0.15)
            opacity: popupProgress
            y: -4 + (4 * popupProgress)
            scale: 0.94 + (0.06 * popupProgress)
            transformOrigin: Item.Top

            Behavior on popupProgress {
                NumberAnimation {
                    duration: root.volumePopupVisible ? 90 : 130
                    easing.type: root.volumePopupVisible ? Easing.OutCubic : Easing.InCubic
                }
            }

            Text {
                id: percentText
                anchors.centerIn: parent
                text: "[" + root.barVolumePercent + "%]"
                font.family: Config.font
                font.pixelSize: 12
                font.bold: true
                color: AudioService.muted ? Config.mutedColor : Config.accentColor
                opacity: popupContent.popupProgress
            }
        }
    }
}
