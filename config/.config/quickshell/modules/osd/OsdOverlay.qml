pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.config

Scope {
    id: root

    // Icons for each type (Nerd Font)
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

    function getIcon(): string {
        if (OsdService.type === "mute" || OsdService.muted) {
            return icons.mute;
        }
        if (OsdService.type === "brightness") {
            if (OsdService.value < 0.3)
                return icons.brightness_low;
            if (OsdService.value < 0.6)
                return icons.brightness_medium;
            return icons.brightness_high;
        }
        // Volume
        if (OsdService.value < 0.01)
            return icons.volume_off;
        if (OsdService.value < 0.33)
            return icons.volume_low;
        if (OsdService.value < 0.66)
            return icons.volume_medium;
        return icons.volume_high;
    }

    function getTitle(): string {
        if (OsdService.type === "brightness")
            return "Brightness";
        if (OsdService.muted)
            return "Muted";
        return "Volume";
    }

    LazyLoader {
        active: OsdService.visible

        PanelWindow {
            id: osdWindow

            // Screen is intentionally unset so compositor chooses active monitor.
            anchors {
                top: true
                left: true
            }
            margins.left: Math.max(0, (((screen?.width ?? 1920) - content.width) / 2))
            margins.top: Math.max(0, (((screen?.height ?? 1080) - content.height) / 2))
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs_modules"

            implicitWidth: content.width
            implicitHeight: content.height
            color: "transparent"

            // Prevent blocking mouse events behind the OSD
            mask: Region {}

            Rectangle {
                id: content
                width: 130
                height: 165
                radius: 28
                color: Qt.rgba(0, 0, 0, 0.5)
                border.color: Qt.rgba(1, 1, 1, 0.16)
                border.width: 1

                // Entry animation
                scale: OsdService.visible ? 1 : 0.8
                opacity: OsdService.visible ? 1 : 0

                Behavior on scale {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Config.animDuration
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.getIcon()
                        font.family: Config.font
                        font.pixelSize: 30
                        color: OsdService.muted ? Qt.rgba(1, 1, 1, 0.65) : Qt.rgba(1, 1, 1, 0.95)

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDurationShort
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.getTitle()
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        font.bold: true
                        color: Qt.rgba(1, 1, 1, 0.9)
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 7
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.2)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom

                            width: parent.width * Math.min(1, OsdService.value)
                            radius: parent.radius
                            color: OsdService.muted ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 0.95)

                            Behavior on width {
                                NumberAnimation {
                                    duration: Config.animDurationShort
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDurationShort
                                }
                            }
                        }
                    }

                    Text {
                        text: Math.round(OsdService.value * 100) + "%"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        font.weight: Font.DemiBold
                        color: OsdService.muted ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(1, 1, 1, 0.95)
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDurationShort
                            }
                        }
                    }
                }
            }
        }
    }
}
