pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.config
import "../../components/"

Scope {
    id: root

    property bool osdLoaded: false

    readonly property var icons: ({
            "volume_off": "󰖁",
            "volume_low": "󰕿",
            "volume_medium": "󰖀",
            "volume_high": "󰕾",
            "mute": "󰝟",
            "brightness_low": "󰃞",
            "brightness_medium": "󰃟",
            "brightness_high": "󰃠"
        })

    readonly property real normalizedValue: Math.max(0, Math.min(1, OsdService.value))

    readonly property real sliderValue: {
        if (OsdService.type === "brightness")
            return Math.max(0.05, Math.min(1.0, BrightnessService.brightness));
        if (AudioService.muted)
            return 0;
        return Math.max(0, Math.min(1.5, AudioService.volume));
    }

    readonly property real sliderTo: OsdService.type === "brightness" ? 1.0 : 1.5

    function getIcon() {
        if (OsdService.muted)
            return icons.mute;

        if (OsdService.type === "brightness") {
            if (normalizedValue < 0.3)
                return icons.brightness_low;
            if (normalizedValue < 0.6)
                return icons.brightness_medium;
            return icons.brightness_high;
        }

        if (normalizedValue < 0.01)
            return icons.volume_off;
        if (normalizedValue < 0.33)
            return icons.volume_low;
        if (normalizedValue < 0.66)
            return icons.volume_medium;
        return icons.volume_high;
    }

    function updateValue(newValue) {
        if (OsdService.type === "brightness") {
            const brightnessValue = Math.max(0.05, Math.min(1.0, newValue));
            BrightnessService.setBrightness(brightnessValue);
            OsdService.showBrightness(brightnessValue);
            return;
        }

        const volumeValue = Math.max(0, Math.min(1.5, newValue));
        AudioService.setVolume(volumeValue);
        OsdService.showVolume(volumeValue, false);
    }

    function toggleCurrentType() {
        if (OsdService.type === "brightness") {
            BrightnessService.toggleBrightness();
            OsdService.showBrightness(Math.max(0.05, Math.min(1.0, BrightnessService.brightness)));
            return;
        }

        const nextMuted = !AudioService.muted;
        AudioService.toggleMute();
        OsdService.showVolume(Math.max(0, Math.min(1.5, AudioService.volume)), nextMuted);
    }

    Connections {
        target: OsdService

        function onVisibleChanged() {
            if (OsdService.visible) {
                unloadTimer.stop();
                root.osdLoaded = true;
            } else {
                unloadTimer.restart();
            }
        }
    }

    Timer {
        id: unloadTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (!OsdService.visible)
                root.osdLoaded = false;
        }
    }

    LazyLoader {
        active: root.osdLoaded

        PanelWindow {
            id: osdWindow
            visible: OsdService.visible || content.opacity > 0.01

            anchors {
                top: true
                left: true
            }

            margins.left: {
                const screenWidth = screen ? screen.width : 1920;
                const screenOffsetX = screen ? screen.x : 0;
                const localAnchorX = OsdService.anchorX - screenOffsetX;
                const targetX = OsdService.anchorX > 0 ? localAnchorX - (content.width / 2) : (screenWidth - content.width - 16);
                return Math.max(10, Math.min(screenWidth - content.width - 10, targetX));
            }
            margins.top: {
                const screenHeight = screen ? screen.height : 1080;
                const screenOffsetY = screen ? screen.y : 0;
                const localAnchorY = OsdService.anchorY - screenOffsetY;
                const targetY = OsdService.anchorY > 0 ? (localAnchorY + 8) : (Config.barHeight + 10);
                return Math.max(Config.barHeight + 4, Math.min(screenHeight - content.height - 10, targetY));
            }

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs_modules"

            implicitWidth: content.width
            implicitHeight: content.height
            color: "transparent"

            Rectangle {
                id: content
                width: 360
                height: 62
                radius: 16
                color: Qt.rgba(0.11, 0.11, 0.12, 0.76)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.2)

                opacity: OsdService.visible ? 1.0 : 0.0
                y: OsdService.visible ? 0 : -10
                scale: OsdService.visible ? 1.0 : 0.96

                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutQuint
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.OutQuint
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.OutQuint
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    spacing: 10

                    QsSlider {
                        Layout.fillWidth: true
                        value: root.sliderValue
                        from: 0
                        to: root.sliderTo
                        icon: root.getIcon()
                        showPercentage: false
                        percentageFromRawValue: OsdService.type === "volume"
                        fillColor: (OsdService.type === "volume" && OsdService.muted) ? Config.surface2Color : Config.accentColor
                        onMoved: newValue => root.updateValue(newValue)
                        onIconClicked: root.toggleCurrentType()
                    }

                    // Inline percentage readout — bracket style
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: {
                            var pct;
                            if (OsdService.type === "volume")
                                pct = Math.round(root.sliderValue * 100);
                            else
                                pct = Math.round(((root.sliderValue - 0) / (root.sliderTo - 0)) * 100);
                            return "[" + pct + "%]";
                        }
                        font.family: Config.font
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 1
                        color: (OsdService.type === "volume" && OsdService.muted) ? Config.mutedColor : Config.accentColor

                        Behavior on color {
                            ColorAnimation { duration: Config.animDuration }
                        }
                    }
                }
            }
        }
    }
}
