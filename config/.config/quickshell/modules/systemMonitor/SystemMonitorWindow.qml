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
    popupMaxHeight: 720
    anchorSide: "left"
    contentImplicitHeight: content.implicitHeight

    readonly property bool hasGpu: SystemMonitorService.gpuType !== "unknown"
    readonly property color accentBlue: Config.accentColor
    readonly property color okColor: "#4fd18b"
    readonly property color warnColor: "#f2c14e"
    readonly property color dangerColor: "#ff6b6b"

    function usageColor(usage: int): color {
        if (usage >= 90)
            return dangerColor;
        if (usage >= 70)
            return warnColor;
        return accentBlue;
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
            return "";
        if (profile === PowerProfile.Performance)
            return "";
        return "";
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
        return accentBlue;
    }

    readonly property int selectedPowerIndex: indexForProfile(PowerProfiles.profile)

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 14

        // ==================== HEADER ====================
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "SYS  MONITOR"
                font.family: Config.font
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 3.5
                color: Config.mutedColor
                opacity: 0.7
                Layout.fillWidth: true
            }

            Rectangle {
                width: 4
                height: 4
                radius: 2
                color: root.accentBlue
                opacity: 0.5
            }

            Text {
                text: SystemMonitorService.uptime
                font.family: Config.font
                font.pixelSize: 13
                font.bold: true
                color: Config.mutedColor
                opacity: 0.5
            }
        }

        // ==================== CPU WIREFRAME RING ====================
        Item {
            id: cpuGauge
            Layout.preferredWidth: 170
            Layout.preferredHeight: 170
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            Layout.bottomMargin: 4

            property int cpuUsage: SystemMonitorService.cpuUsage
            property real animUsage: 0

            onCpuUsageChanged: animUsage = cpuUsage
            Component.onCompleted: animUsage = cpuUsage

            Behavior on animUsage {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutCubic
                }
            }

            Canvas {
                id: cpuCanvas
                anchors.fill: parent
                antialiasing: true

                Connections {
                    target: cpuGauge
                    function onAnimUsageChanged() {
                        cpuCanvas.requestPaint();
                    }
                }

                Connections {
                    target: Config
                    function onSurface2ColorChanged() {
                        cpuCanvas.requestPaint();
                    }
                }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();

                    var cx = width / 2;
                    var cy = height / 2;
                    var outerR = 72;
                    var arcR = 62;
                    var innerR = 52;
                    var dotCount = 24;
                    var activeDots = Math.floor((cpuGauge.animUsage / 100) * dotCount);
                    var accent = root.usageColor(cpuGauge.cpuUsage).toString();
                    var muted = Config.surface3Color.toString();
                    var faint = Config.surface2Color.toString();

                    // Inner guide ring
                    ctx.beginPath();
                    ctx.arc(cx, cy, innerR, 0, 2 * Math.PI);
                    ctx.strokeStyle = Qt.alpha(faint, 0.4).toString();
                    ctx.lineWidth = 0.5;
                    ctx.stroke();

                    // Tick marks at N/E/S/W
                    for (var t = 0; t < 4; t++) {
                        var ta = (t / 4) * 2 * Math.PI - Math.PI / 2;
                        ctx.beginPath();
                        ctx.moveTo(cx + (innerR - 4) * Math.cos(ta), cy + (innerR - 4) * Math.sin(ta));
                        ctx.lineTo(cx + (innerR + 3) * Math.cos(ta), cy + (innerR + 3) * Math.sin(ta));
                        ctx.strokeStyle = Qt.alpha(faint, 0.6).toString();
                        ctx.lineWidth = 0.8;
                        ctx.stroke();
                    }

                    // Background arc
                    var startAngle = -Math.PI / 2;
                    ctx.beginPath();
                    ctx.arc(cx, cy, arcR, 0, 2 * Math.PI);
                    ctx.strokeStyle = Qt.alpha(faint, 0.5).toString();
                    ctx.lineWidth = 2.5;
                    ctx.stroke();

                    // Progress arc
                    if (cpuGauge.animUsage > 0) {
                        var sweep = (cpuGauge.animUsage / 100) * 2 * Math.PI;
                        ctx.beginPath();
                        ctx.arc(cx, cy, arcR, startAngle, startAngle + sweep);
                        ctx.strokeStyle = accent;
                        ctx.lineWidth = 3;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }

                    // 24 dot markers on outer ring
                    for (var i = 0; i < dotCount; i++) {
                        var angle = (i / dotCount) * 2 * Math.PI - Math.PI / 2;
                        var dx = cx + outerR * Math.cos(angle);
                        var dy = cy + outerR * Math.sin(angle);
                        var isActive = i < activeDots;

                        ctx.beginPath();
                        ctx.arc(dx, dy, isActive ? 2.8 : 1.6, 0, 2 * Math.PI);
                        ctx.fillStyle = isActive ? accent : muted;
                        ctx.fill();
                    }
                }
            }

            // Center text
            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SystemMonitorService.cpuUsage + "%"
                    font.family: Config.font
                    font.pixelSize: 28
                    font.bold: true
                    color: root.usageColor(SystemMonitorService.cpuUsage)

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "CPU"
                    font.family: Config.font
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2
                    color: Config.mutedColor
                    opacity: 0.6
                }

                RowLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4

                    Text {
                        text: "󰔏"
                        font.family: Config.font
                        font.pixelSize: 12
                        color: root.tempColor(SystemMonitorService.cpuTemp)

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration
                            }
                        }
                    }

                    Text {
                        text: SystemMonitorService.cpuTemp + "°"
                        font.family: Config.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.tempColor(SystemMonitorService.cpuTemp)

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration
                            }
                        }
                    }
                }
            }
        }

        // ==================== SINE WAVE SEPARATOR ====================
        Canvas {
            id: sineWave
            Layout.fillWidth: true
            Layout.preferredHeight: 26

            property real phase: 0

            Timer {
                running: true
                repeat: true
                interval: 80
                onTriggered: {
                    sineWave.phase += 0.03;
                    sineWave.requestPaint();
                }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var h = height;
                var w = width;
                var accent = root.accentBlue.toString();

                // Primary wave
                ctx.beginPath();
                for (var x = 0; x <= w; x += 2) {
                    var y = h / 2 + 5 * Math.sin((x / w) * 4 * Math.PI + phase);
                    if (x === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.strokeStyle = Qt.alpha(accent, 0.12).toString();
                ctx.lineWidth = 1;
                ctx.stroke();

                // Secondary wave (offset)
                ctx.beginPath();
                for (var x2 = 0; x2 <= w; x2 += 2) {
                    var y2 = h / 2 + 3.5 * Math.sin((x2 / w) * 3 * Math.PI + phase * 0.6 + 1.2);
                    if (x2 === 0)
                        ctx.moveTo(x2, y2);
                    else
                        ctx.lineTo(x2, y2);
                }
                ctx.strokeStyle = Qt.alpha(accent, 0.06).toString();
                ctx.lineWidth = 1;
                ctx.stroke();
            }
        }

        // ==================== COMPACT METRICS ====================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // GPU row (with toggle)
            RowLayout {
                Layout.fillWidth: true
                visible: root.hasGpu
                spacing: 10
                opacity: SystemMonitorService.gpuMonitorEnabled ? 1.0 : 0.35

                Behavior on opacity {
                    NumberAnimation {
                        duration: Config.animDuration
                    }
                }

                Text {
                    text: "GPU"
                    font.family: Config.font
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.5
                    color: Config.mutedColor
                    Layout.preferredWidth: 40
                }

                Text {
                    text: SystemMonitorService.gpuType.toUpperCase()
                    font.family: Config.font
                    font.pixelSize: 12
                    color: Config.subtextColor
                    opacity: 0.5
                    Layout.preferredWidth: 55
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4

                    Rectangle {
                        anchors.fill: parent
                        radius: 2
                        color: Config.surface2Color
                    }

                    Rectangle {
                        width: parent.width * (SystemMonitorService.gpuUsage / 100)
                        height: parent.height
                        radius: 2
                        color: root.usageColor(SystemMonitorService.gpuUsage)

                        Behavior on width {
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
                    }
                }

                Text {
                    text: SystemMonitorService.gpuUsage + "%"
                    font.family: Config.font
                    font.pixelSize: 13
                    font.bold: true
                    color: Config.subtextColor
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 36
                }

                // GPU temp
                Text {
                    text: SystemMonitorService.gpuTemp + "°"
                    font.family: Config.font
                    font.pixelSize: 12
                    color: root.tempColor(SystemMonitorService.gpuTemp)
                    opacity: 0.7
                    Layout.preferredWidth: 26

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }

                QsSwitch {
                    scale: 0.8
                    checked: SystemMonitorService.gpuMonitorEnabled
                    onToggled: SystemMonitorService.toggleGpuMonitor()
                }
            }

            // RAM
            CompactMetric {
                label: "RAM"
                detail: SystemMonitorService.ramUsed + " / " + SystemMonitorService.ramTotal
                usage: SystemMonitorService.ramUsage
                barColor: root.usageColor(SystemMonitorService.ramUsage)
            }

            // Disk
            CompactMetric {
                label: "DSK"
                detail: SystemMonitorService.diskUsed + " / " + SystemMonitorService.diskTotal
                usage: SystemMonitorService.diskUsage
                barColor: root.usageColor(SystemMonitorService.diskUsage)
            }
        }

        // ==================== NETWORK ====================
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Download
            Item {
                Layout.fillWidth: true
                implicitHeight: 38
                
                // Dotted border
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        var r = Config.radius;
                        ctx.setLineDash([2, 4]);
                        ctx.strokeStyle = Qt.alpha("#f5f5f0", 0.8).toString();
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.moveTo(r, 0); ctx.lineTo(width-r, 0); ctx.arcTo(width, 0, width, r, r);
                        ctx.lineTo(width, height-r); ctx.arcTo(width, height, width-r, height, r);
                        ctx.lineTo(r, height); ctx.arcTo(0, height, 0, height-r, r);
                        ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r);
                        ctx.stroke();
                    }
                }
                


                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    Text {
                        text: "↓"
                        font.family: Config.font
                        font.pixelSize: 15
                        font.bold: true
                        color: root.okColor
                    }

                    Text {
                        text: SystemMonitorService.networkDown
                        font.family: Config.font
                        font.pixelSize: 13
                        font.bold: true
                        color: Config.textColor
                        Layout.fillWidth: true
                    }
                }
            }

            // Upload
            Item {
                Layout.fillWidth: true
                implicitHeight: 38
                
                // Dotted border
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        var r = Config.radius;
                        ctx.setLineDash([2, 4]);
                        ctx.strokeStyle = Qt.alpha("#f5f5f0", 0.8).toString();
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.moveTo(r, 0); ctx.lineTo(width-r, 0); ctx.arcTo(width, 0, width, r, r);
                        ctx.lineTo(width, height-r); ctx.arcTo(width, height, width-r, height, r);
                        ctx.lineTo(r, height); ctx.arcTo(0, height, 0, height-r, r);
                        ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r);
                        ctx.stroke();
                    }
                }
                


                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    Text {
                        text: "↑"
                        font.family: Config.font
                        font.pixelSize: 15
                        font.bold: true
                        color: root.warnColor
                    }

                    Text {
                        text: SystemMonitorService.networkUp
                        font.family: Config.font
                        font.pixelSize: 13
                        font.bold: true
                        color: Config.textColor
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // ==================== THIN RULE ====================
        Canvas {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            onPaint: {
                var ctx = getContext("2d");
                ctx.setLineDash([2, 4]);
                ctx.strokeStyle = Qt.alpha(Config.textColor, 0.15).toString();
                ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(width, 0); ctx.stroke();
            }
        }

        // ==================== POWER PROFILE ====================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "POWER"
                    font.family: Config.font
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 2
                    color: Config.mutedColor
                    opacity: 0.5
                    Layout.fillWidth: true
                }



                Text {
                    text: root.profileLabel(PowerProfiles.profile)
                    font.family: Config.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.profileColor(PowerProfiles.profile)

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }
            }

            Item {
                id: powerSegment
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        var r = Config.radiusLarge;
                        ctx.setLineDash([2, 4]);
                        ctx.strokeStyle = Qt.alpha("#f5f5f0", 0.8).toString();
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.moveTo(r, 0); ctx.lineTo(width-r, 0); ctx.arcTo(width, 0, width, r, r);
                        ctx.lineTo(width, height-r); ctx.arcTo(width, height, width-r, height, r);
                        ctx.lineTo(r, height); ctx.arcTo(0, height, 0, height-r, r);
                        ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r);
                        ctx.stroke();
                    }
                }

                readonly property real slotWidth: (width - 8) / 3

                // Glow behind selection
                Rectangle {
                    x: powerPill.x - 3
                    y: powerPill.y - 3
                    width: powerPill.width + 6
                    height: powerPill.height + 6
                    radius: Config.radius + 2
                    color: Qt.alpha(root.profileColor(root.profileForIndex(root.selectedPowerIndex)), 0.06)



                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }

                // Selection pill (Scanner Bracket)
                Item {
                    id: powerPill
                    y: 4
                    x: 4 + (root.selectedPowerIndex * powerSegment.slotWidth)
                    width: powerSegment.slotWidth
                    height: powerSegment.height - 8


                    
                    Canvas {
                        anchors.fill: parent
                        property color bracketColor: root.profileColor(root.profileForIndex(root.selectedPowerIndex))
                        Behavior on bracketColor { ColorAnimation { duration: Config.animDuration } }
                        onBracketColorChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = bracketColor.toString();
                            ctx.lineWidth = 2;
                            var w = width; var h = height;
                            var r = Config.radius;
                            var len = 10; // Bracket arm length
                            
                            ctx.beginPath();
                            // Top left
                            ctx.moveTo(len, 0); ctx.lineTo(r, 0); ctx.arcTo(0, 0, 0, r, r); ctx.lineTo(0, len);
                            // Bottom left
                            ctx.moveTo(0, h - len); ctx.lineTo(0, h - r); ctx.arcTo(0, h, r, h, r); ctx.lineTo(len, h);
                            // Top right
                            ctx.moveTo(w - len, 0); ctx.lineTo(w - r, 0); ctx.arcTo(w, 0, w, r, r); ctx.lineTo(w, len);
                            // Bottom right
                            ctx.moveTo(w, h - len); ctx.lineTo(w, h - r); ctx.arcTo(w, h, w - r, h, r); ctx.lineTo(w - len, h);
                            ctx.stroke();
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
                            readonly property bool hovered: profileMouse.containsMouse

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            scale: {
                                if (profileMouse.pressed && !profileItem.disabled)
                                    return 0.94;
                                if (profileItem.hovered && !profileItem.disabled)
                                    return 1.04;
                                return 1.0;
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: root.profileIcon(profileItem.profile)
                                    font.family: Config.font
                                    font.pixelSize: Config.fontSizeNormal
                                    color: {
                                        if (profileItem.disabled)
                                            return Qt.alpha(Config.subtextColor, 0.3);
                                        if (profileItem.selected)
                                            return root.profileColor(profileItem.profile);
                                        if (profileItem.hovered)
                                            return Config.textColor;
                                        return Config.subtextColor;
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }

                                Text {
                                    text: root.profileLabel(profileItem.profile)
                                    font.family: Config.font
                                    font.pixelSize: 13
                                    font.bold: profileItem.selected
                                    color: {
                                        if (profileItem.disabled)
                                            return Qt.alpha(Config.subtextColor, 0.3);
                                        if (profileItem.selected)
                                            return root.profileColor(profileItem.profile);
                                        if (profileItem.hovered)
                                            return Config.textColor;
                                        return Config.subtextColor;
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: profileMouse
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
    }

    // ====================================================================
    // COMPACT METRIC ROW COMPONENT
    // ====================================================================
    component CompactMetric: RowLayout {
        id: metric

        required property string label
        required property string detail
        required property int usage
        required property color barColor

        Layout.fillWidth: true
        spacing: 10

        property real animatedUsage: 0
        Behavior on animatedUsage {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }
        onUsageChanged: animatedUsage = usage

        Text {
            text: metric.label
            font.family: Config.font
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 1.5
            color: Config.mutedColor
            Layout.preferredWidth: 40
        }

        Text {
            text: metric.detail
            font.family: Config.font
            font.pixelSize: 12
            color: Config.subtextColor
            opacity: 0.5
            Layout.preferredWidth: 80
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 4

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: Config.surface2Color
            }

            Rectangle {
                width: parent.width * (metric.animatedUsage / 100)
                height: parent.height
                radius: 2
                color: metric.barColor

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }
            }
        }

        Text {
            text: metric.usage + "%"
            font.family: Config.font
            font.pixelSize: 13
            font.bold: true
            color: Config.subtextColor
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 36
        }
    }
}
