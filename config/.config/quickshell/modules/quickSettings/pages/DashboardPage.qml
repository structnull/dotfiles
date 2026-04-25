pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import "../../quickSettings/"
import "../../../components/"

Item {
    id: root

    signal closeWindow

    Layout.fillWidth: true
    implicitHeight: main.implicitHeight

    ColumnLayout {
        id: main
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 14

        // ==================== HEADER ====================
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Username label
            Text {
                text: Quickshell.env("USER").toUpperCase()
                font.family: Config.font
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 3
                color: Config.mutedColor
                opacity: 0.7
            }

            // Separator dot
            Rectangle {
                width: 4
                height: 4
                radius: 2
                color: Config.accentColor
                opacity: 0.4
            }

            // Date
            Text {
                text: TimeService.format("ddd, dd MMM")
                font.family: Config.font
                font.pixelSize: 12
                color: Config.mutedColor
                opacity: 0.5
                Layout.fillWidth: true
            }

            // Battery indicator
            Rectangle {
                visible: BatteryService.hasBattery
                Layout.preferredHeight: 30
                Layout.preferredWidth: batteryContent.implicitWidth + 14
                radius: Config.radius
                color: Config.backgroundTransparentColor
                border.width: 0.5
                border.color: Qt.alpha(Config.textColor, 0.2)

                RowLayout {
                    id: batteryContent
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: BatteryService.getBatteryIcon()
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        color: {
                            if (BatteryService.isCharging)
                                return Config.successColor;
                            if (BatteryService.percentage < 20)
                                return Config.errorColor;
                            if (BatteryService.percentage < 40)
                                return Config.warningColor;
                            return Config.subtextColor;
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration
                            }
                        }
                    }

                    Text {
                        text: BatteryService.percentage + "%"
                        font.family: Config.font
                        font.pixelSize: 12
                        font.bold: true
                        color: Config.subtextColor
                    }
                }
            }

            // Power Menu
            ClearButton {
                icon: "⏻"

                Layout.preferredWidth: 30
                Layout.preferredHeight: 30

                onClicked: {
                    root.closeWindow();
                    PowerService.showOverlay();
                }
            }
        }

        // ==================== MEDIA ====================
        MediaWidget {
            Layout.fillWidth: true
        }

        // ==================== CONTROLS SECTION ====================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // Section label
            Text {
                text: "CONTROLS"
                font.family: Config.font
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2.5
                color: Config.mutedColor
                opacity: 0.4
            }

            GridLayout {
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                Layout.fillWidth: true

                // WI-FI
                QuickSettingsTile {
                    icon: NetworkService.systemIcon
                    label: "Wi-Fi"
                    subLabel: NetworkService.statusText
                    active: NetworkService.wifiEnabled
                    hasDetails: true
                    onToggled: NetworkService.toggleWifi()
                    onOpenDetails: pageStack.currentIndex = 1
                }

                // BLUETOOTH
                QuickSettingsTile {
                    visible: BluetoothService.adapter !== null
                    icon: BluetoothService.systemIcon
                    label: "Bluetooth"
                    subLabel: BluetoothService.statusText
                    active: BluetoothService.isPowered
                    hasDetails: true
                    onToggled: BluetoothService.togglePower()
                    onOpenDetails: pageStack.currentIndex = 3
                }

                // CAFFEINE
                QuickSettingsTile {
                    icon: ""
                    label: "Caffeine"
                    subLabel: CaffeineService.enabled ? "Idle inhibit on" : "Idle inhibit off"
                    active: CaffeineService.enabled
                    hasDetails: false
                    onToggled: CaffeineService.toggle()
                }

                // DND
                QuickSettingsTile {
                    Layout.columnSpan: BluetoothService.adapter === null ? 2 : 1
                    icon: NotificationService.dndEnabled ? "󰂛" : "󰂚"
                    label: "Do not disturb"
                    subLabel: NotificationService.dndEnabled ? "Enabled" : "Disabled"
                    active: NotificationService.dndEnabled
                    hasDetails: false
                    onToggled: NotificationService.toggleDnd()
                }
            }
        }

        // ==================== THIN RULE ====================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.alpha(Config.textColor, 0.12)
            opacity: 1
        }

        // ==================== AUDIO SECTION ====================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            // Section label
            Text {
                text: "AUDIO"
                font.family: Config.font
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2.5
                color: Config.mutedColor
                opacity: 0.4
            }

            QsSlider {
                icon: AudioService.systemIcon
                value: AudioService.volume
                hasDetails: true
                onMoved: val => AudioService.setVolume(val)
                onIconClicked: AudioService.toggleMute()
                onOpenDetails: {
                    AudioService.refreshDevices();
                    pageStack.currentIndex = 4;
                }
            }

            // Brightness (only shows if available)
            QsSlider {
                visible: BrightnessService.available
                icon: BrightnessService.icon
                value: BrightnessService.brightness
                onMoved: val => BrightnessService.setBrightness(val)
                onIconClicked: BrightnessService.toggleBrightness()
            }
        }
    }
}
