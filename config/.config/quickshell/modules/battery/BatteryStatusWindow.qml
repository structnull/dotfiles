pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import "../../components/"

QsPopupWindow {
    id: root

    popupWidth: 340
    popupMaxHeight: 420
    anchorSide: "right"
    contentImplicitHeight: content.implicitHeight

    readonly property color accentInfo: "#8ab4ff"
    readonly property color accentGood: "#7ee2a8"
    readonly property color accentWarn: "#ffcc66"
    readonly property color accentDanger: "#ff5f57"
    readonly property real rateNorm: Math.min(1, BatteryService.chargeRateW / 60)

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: Config.radius
                color: Qt.alpha(Config.accentColor, 0.18)

                Text {
                    anchors.centerIn: parent
                    text: BatteryService.getBatteryIcon()
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeLarge
                    color: BatteryService.isLow ? root.accentDanger : (BatteryService.isCharging ? root.accentGood : root.accentInfo)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: BatteryService.hasBattery ? (BatteryService.percentage + "%") : "Power"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeLarge
                    font.bold: true
                    color: Config.textColor
                }

                Text {
                    text: BatteryService.statusText
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    color: Config.mutedColor
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Config.surface1Color
        }

        // Charge level
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Charge"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    color: Config.mutedColor
                }
                Item {
                    Layout.fillWidth: true
                }
                Text {
                    text: BatteryService.hasBattery ? (BatteryService.percentage + "%") : "--"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.bold: true
                    color: Config.textColor
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 9
                radius: 5
                color: Config.surface2Color

                Rectangle {
                    width: parent.width * (BatteryService.percentage / 100)
                    height: parent.height
                    radius: parent.radius
                    color: BatteryService.isLow ? root.accentDanger : (BatteryService.isCharging ? root.accentGood : root.accentInfo)

                    Behavior on width {
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: Config.radius
            color: Config.surface0Color

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                Text {
                    text: {
                        if (BatteryService.isCharging)
                            return "󰚥 Charge Rate";
                        if (BatteryService.isDischarging)
                            return "󰚥 Discharge Rate";
                        return "󰚥 Power Rate";
                    }
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    color: Config.mutedColor
                }
                Text {
                    text: BatteryService.hasBattery ? BatteryService.chargeRateW.toFixed(1) + " W" : "--"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    font.bold: true
                    color: BatteryService.isLow ? root.accentDanger : root.accentWarn
                }
            }
        }

        // Small rate graph
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: Config.radius
            color: Config.surface0Color

            Row {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                Repeater {
                    model: 24
                    delegate: Rectangle {
                        required property int index
                        width: (parent.width - (23 * 4)) / 24
                        height: Math.max(4, (parent.height - 4) * root.rateNorm * (0.4 + ((index % 6) * 0.1)))
                        y: parent.height - height
                        radius: 2
                        color: Qt.alpha(BatteryService.isLow ? root.accentDanger : root.accentInfo, 0.8)
                    }
                }
            }
        }

        // Times
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                radius: Config.radius
                color: Config.surface0Color

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    Text {
                        text: "󰚦 Time to Full"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: Config.mutedColor
                    }
                    Text {
                        text: BatteryService.isCharging ? BatteryService.formatDuration(BatteryService.timeToFullSeconds) : "--"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        font.bold: true
                        color: Config.textColor
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                radius: Config.radius
                color: Config.surface0Color

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    Text {
                        text: "󰁹 Time to Empty"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: Config.mutedColor
                    }
                    Text {
                        text: BatteryService.isDischarging ? BatteryService.formatDuration(BatteryService.timeToEmptySeconds) : "--"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        font.bold: true
                        color: Config.textColor
                    }
                }
            }
        }
    }
}
