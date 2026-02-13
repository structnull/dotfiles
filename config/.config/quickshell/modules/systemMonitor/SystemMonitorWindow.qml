pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.config
import qs.services
import "../../components/"

QsPopupWindow {
    id: root

    popupWidth: 380
    popupMaxHeight: 700
    anchorSide: "left"
    contentImplicitHeight: content.implicitHeight

    readonly property bool hasGpu: SystemMonitorService.gpuType !== "unknown"
    readonly property color okColor: "#4fd18b"
    readonly property color warnColor: "#f2c14e"
    readonly property color dangerColor: "#ff6b6b"
    readonly property color infoColor: "#58a6ff"

    // Color helpers
    function usageColor(usage: int): color {
        if (usage >= 90)
            return dangerColor;
        if (usage >= 70)
            return warnColor;
        return infoColor;
    }

    function tempColor(temp: int): color {
        if (temp >= 85)
            return dangerColor;
        if (temp >= 70)
            return warnColor;
        return okColor;
    }

    function profileForIndex(index: int): int {
        if (index === 0)
            return PowerProfile.PowerSaver;
        if (index === 2)
            return PowerProfile.Performance;
        return PowerProfile.Balanced;
    }

    function indexForProfile(profile: int): int {
        if (profile === PowerProfile.PowerSaver)
            return 0;
        if (profile === PowerProfile.Performance)
            return 2;
        return 1;
    }

    function profileIcon(profile: int): string {
        if (profile === PowerProfile.PowerSaver)
            return "";
        if (profile === PowerProfile.Performance)
            return "";
        return "";
    }

    function profileLabel(profile: int): string {
        if (profile === PowerProfile.PowerSaver)
            return "Saver";
        if (profile === PowerProfile.Performance)
            return "Perf";
        return "Balanced";
    }

    function profileColor(profile: int): color {
        if (profile === PowerProfile.PowerSaver)
            return okColor;
        if (profile === PowerProfile.Performance)
            return warnColor;
        return infoColor;
    }

    readonly property int selectedPowerIndex: indexForProfile(PowerProfiles.profile)

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 12

        // ==================== HEADER ====================
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: Config.radius
                color: Qt.alpha(Config.accentColor, 0.15)

                Text {
                    anchors.centerIn: parent
                    text: "󰍛"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeLarge
                    color: Config.accentColor
                }
            }

            Text {
                text: "System Monitor"
                font.family: Config.font
                font.bold: true
                font.pixelSize: Config.fontSizeLarge
                color: Config.textColor
                Layout.fillWidth: true
            }

            // Uptime badge
            Rectangle {
                Layout.preferredHeight: 26
                Layout.preferredWidth: uptimeContent.implicitWidth + 14
                radius: Config.radius
                color: Config.surface1Color

                RowLayout {
                    id: uptimeContent
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰅐"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: Config.mutedColor
                    }

                    Text {
                        text: SystemMonitorService.uptime
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        font.bold: true
                        color: Config.mutedColor
                    }
                }
            }
        }

        // ==================== POWER PROFILE ====================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󱐋"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeLarge
                    color: root.profileColor(PowerProfiles.profile)

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }

                Text {
                    text: "Power Profile"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    font.bold: true
                    color: Config.textColor
                    Layout.fillWidth: true
                }

                Text {
                    text: root.profileLabel(PowerProfiles.profile)
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.bold: true
                    color: root.profileColor(PowerProfiles.profile)

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }
            }

            Rectangle {
                id: powerSegment
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                radius: Config.radius
                color: Config.surface1Color
                border.width: 1
                border.color: Config.surface2Color

                readonly property real slotWidth: (width - 8) / 3

                Rectangle {
                    id: powerSelection
                    y: 4
                    x: 4 + (root.selectedPowerIndex * powerSegment.slotWidth)
                    width: powerSegment.slotWidth
                    height: powerSegment.height - 8
                    radius: Config.radius
                    color: Qt.alpha(root.profileColor(root.profileForIndex(root.selectedPowerIndex)), 0.22)
                    border.width: 1
                    border.color: Qt.alpha(root.profileColor(root.profileForIndex(root.selectedPowerIndex)), 0.45)

                    Behavior on x {
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 0

                    Repeater {
                        model: 3

                        delegate: Item {
                            id: profileItem
                            required property int index

                            readonly property int profile: root.profileForIndex(index)
                            readonly property bool selected: root.selectedPowerIndex === index
                            readonly property bool disabled: index === 2 && !PowerProfiles.hasPerformanceProfile

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: root.profileIcon(profileItem.profile)
                                    font.family: Config.font
                                    font.pixelSize: Config.fontSizeNormal
                                    color: {
                                        if (profileItem.disabled)
                                            return Qt.alpha(Config.subtextColor, 0.45);
                                        if (profileItem.selected)
                                            return root.profileColor(profileItem.profile);
                                        return Config.subtextColor;
                                    }
                                }

                                Text {
                                    text: root.profileLabel(profileItem.profile)
                                    font.family: Config.font
                                    font.pixelSize: 11
                                    font.bold: profileItem.selected
                                    color: {
                                        if (profileItem.disabled)
                                            return Qt.alpha(Config.subtextColor, 0.45);
                                        if (profileItem.selected)
                                            return root.profileColor(profileItem.profile);
                                        return Config.subtextColor;
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !profileItem.disabled
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: PowerProfiles.profile = profileItem.profile
                            }
                        }
                    }
                }
            }
        }

        // ==================== SEPARATOR ====================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Config.surface1Color
        }

        // ==================== GAUGES (CPU + GPU) ====================
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            ArcGauge {
                label: "CPU"
                usage: SystemMonitorService.cpuUsage
                temp: SystemMonitorService.cpuTemp
                arcColor: root.usageColor(SystemMonitorService.cpuUsage)
                badgeColor: root.tempColor(SystemMonitorService.cpuTemp)
            }

            ArcGauge {
                visible: root.hasGpu
                label: "GPU"
                subtitle: SystemMonitorService.gpuType.toUpperCase()
                usage: SystemMonitorService.gpuUsage
                temp: SystemMonitorService.gpuTemp
                arcColor: root.usageColor(SystemMonitorService.gpuUsage)
                badgeColor: root.tempColor(SystemMonitorService.gpuTemp)
            }
        }

        // ==================== SEPARATOR ====================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Config.surface1Color
        }

        // ==================== RAM ====================
        MetricBar {
            icon: "󰘚"
            label: "RAM"
            usage: SystemMonitorService.ramUsage
            detail: SystemMonitorService.ramUsed + " / " + SystemMonitorService.ramTotal + " GiB"
            barColor: root.usageColor(SystemMonitorService.ramUsage)
        }

        // ==================== DISK ====================
        MetricBar {
            icon: "󰋊"
            label: "Disk (/)"
            usage: SystemMonitorService.diskUsage
            detail: SystemMonitorService.diskUsed + " / " + SystemMonitorService.diskTotal + " GiB"
            barColor: root.usageColor(SystemMonitorService.diskUsage)
        }

        // ==================== SEPARATOR ====================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Config.surface1Color
        }

        // ==================== NETWORK ====================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰛳"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeLarge
                    color: root.infoColor
                }

                Text {
                    text: "Network"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    font.bold: true
                    color: Config.textColor
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Download
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Config.radius
                    color: Config.surface0Color

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Text {
                            text: "󰁅"
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            color: root.okColor
                        }

                        Text {
                            text: SystemMonitorService.networkDown
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeSmall
                            font.bold: true
                            color: Config.mutedColor
                            Layout.fillWidth: true
                        }
                    }
                }

                // Upload
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Config.radius
                    color: Config.surface0Color

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Text {
                            text: "󰁝"
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            color: root.warnColor
                        }

                        Text {
                            text: SystemMonitorService.networkUp
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeSmall
                            font.bold: true
                            color: Config.mutedColor
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    // ====================================================================
    // ARC GAUGE COMPONENT
    // ====================================================================
    component ArcGauge: ColumnLayout {
        id: gauge

        required property string label
        property string subtitle: ""
        required property int usage
        required property int temp
        required property color arcColor
        required property color badgeColor

        spacing: 8
        Layout.alignment: Qt.AlignHCenter

        property real animatedUsage: 0
        Behavior on animatedUsage {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuad
            }
        }
        onUsageChanged: animatedUsage = usage

        Item {
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            Layout.alignment: Qt.AlignHCenter

            Canvas {
                id: canvas
                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();

                    var cx = width / 2;
                    var cy = height / 2;
                    var radius = 50;
                    var lineWidth = 8;
                    var startAngle = (135 * Math.PI) / 180;
                    var sweepAngle = (270 * Math.PI) / 180;
                    var endAngle = startAngle + sweepAngle;

                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, startAngle, endAngle);
                    ctx.strokeStyle = Config.surface2Color.toString();
                    ctx.lineWidth = lineWidth;
                    ctx.lineCap = "round";
                    ctx.stroke();

                    if (gauge.animatedUsage > 0) {
                        var valueEnd = startAngle + (gauge.animatedUsage / 100) * sweepAngle;
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, valueEnd);
                        ctx.strokeStyle = gauge.arcColor.toString();
                        ctx.lineWidth = lineWidth;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }
                }

                Connections {
                    target: gauge
                    function onAnimatedUsageChanged() {
                        canvas.requestPaint();
                    }
                    function onArcColorChanged() {
                        canvas.requestPaint();
                    }
                }

                Connections {
                    target: Config
                    function onSurface2ColorChanged() {
                        canvas.requestPaint();
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: gauge.usage + "%"
                font.family: Config.font
                font.pixelSize: 22
                font.bold: true
                color: gauge.arcColor

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: gauge.subtitle ? (gauge.label + " · " + gauge.subtitle) : gauge.label
            font.family: Config.font
            font.pixelSize: Config.fontSizeSmall
            font.bold: true
            color: Config.mutedColor
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: tempText.implicitWidth + 14
            Layout.preferredHeight: 24
            radius: 8
            color: Qt.alpha(gauge.badgeColor, 0.15)

            Behavior on color {
                ColorAnimation {
                    duration: Config.animDuration
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "󰔏"
                    font.family: Config.font
                    font.pixelSize: 12
                    color: gauge.badgeColor

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }

                Text {
                    id: tempText
                    text: gauge.temp + "°C"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.bold: true
                    color: gauge.badgeColor

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }
            }
        }
    }

    // ====================================================================
    // METRIC BAR COMPONENT (RAM, Disk)
    // ====================================================================
    component MetricBar: ColumnLayout {
        id: metric

        required property string icon
        required property string label
        required property int usage
        required property string detail
        required property color barColor

        Layout.fillWidth: true
        spacing: 6

        property real animatedUsage: 0
        Behavior on animatedUsage {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuad
            }
        }
        onUsageChanged: animatedUsage = usage

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: metric.icon
                font.family: Config.font
                font.pixelSize: Config.fontSizeLarge
                color: metric.barColor

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }
            }

            Text {
                text: metric.label
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
                font.bold: true
                color: Config.textColor
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: metric.detail
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                color: Config.mutedColor
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            radius: 4
            color: Config.surface2Color

            Rectangle {
                width: parent.width * (metric.animatedUsage / 100)
                height: parent.height
                radius: 4
                color: metric.barColor

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }
            }
        }

        Text {
            text: metric.usage + "% used"
            font.family: Config.font
            font.pixelSize: 11
            color: Config.mutedColor
            Layout.alignment: Qt.AlignRight
        }
    }
}
