pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
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
    contentImplicitHeight: monitorContent.implicitHeight
    property bool _monitorRegistered: false

    function syncMonitoring() {
        if (_monitorRegistered === visible)
            return;
        _monitorRegistered = visible;
        if (visible)
            SystemMonitorService.acquireWindow();
        else
            SystemMonitorService.releaseWindow();
    }

    onVisibleChanged: syncMonitoring()
    Component.onCompleted: syncMonitoring()
    Component.onDestruction: {
        if (_monitorRegistered)
            SystemMonitorService.releaseWindow();
    }

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
        id: monitorContent
        anchors.fill: parent
        spacing: 14

        // ==================== HEADER ====================
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                textFormat: Text.PlainText
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
                implicitWidth: 4
                implicitHeight: 4
                radius: 2
                color: root.accentBlue
                opacity: 0.5
            }

            Text {
                textFormat: Text.PlainText
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

            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Qt.alpha(Config.surface2Color, 0.4)
                    strokeWidth: 0.5
                    PathAngleArc { centerX: cpuGauge.width / 2; centerY: cpuGauge.height / 2; radiusX: 52; radiusY: 52; startAngle: 0; sweepAngle: 360 }
                }
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Qt.alpha(Config.surface2Color, 0.5)
                    strokeWidth: 2.5
                    PathAngleArc { centerX: cpuGauge.width / 2; centerY: cpuGauge.height / 2; radiusX: 62; radiusY: 62; startAngle: 0; sweepAngle: 360 }
                }
            }
            Repeater {
                model: 4
                Shape {
                    id: gaugeTick
                    antialiasing: true
                    required property int index
                    anchors.fill: parent
                    readonly property real angle: index * Math.PI / 2 - Math.PI / 2
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Qt.alpha(Config.surface2Color, 0.6)
                        strokeWidth: 0.8
                        startX: cpuGauge.width / 2 + 48 * Math.cos(gaugeTick.angle)
                        startY: cpuGauge.height / 2 + 48 * Math.sin(gaugeTick.angle)
                        PathLine { x: cpuGauge.width / 2 + 55 * Math.cos(gaugeTick.angle); y: cpuGauge.height / 2 + 55 * Math.sin(gaugeTick.angle) }
                    }
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
                    var dotCount = 24;
                    var activeDots = Math.floor((cpuGauge.animUsage / 100) * dotCount);
                    var accent = root.usageColor(cpuGauge.cpuUsage).toString();
                    var muted = Config.surface3Color.toString();

                    const startAngle = -Math.PI / 2;
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
                    textFormat: Text.PlainText
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
                    textFormat: Text.PlainText
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
                        textFormat: Text.PlainText
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
                        textFormat: Text.PlainText
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
        Shape {
            id: sineWave
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            antialiasing: true
            property real phase: 0

            function wave(amplitude, periods, speed, offset) {
                const points = [];
                if (width <= 0) return points;
                for (let x = 0; x <= width; x += 2)
                    points.push(Qt.point(x, height / 2 + amplitude * Math.sin((x / width) * periods * Math.PI + phase * speed + offset)));
                return points;
            }

            Timer {
                running: root.visible
                repeat: true
                interval: 80
                onTriggered: sineWave.phase += 0.03
            }

            ShapePath {
                strokeColor: Qt.alpha(root.accentBlue, 0.12)
                strokeWidth: 1
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                PathPolyline { path: sineWave.wave(5, 4, 1, 0) }
            }
            ShapePath {
                strokeColor: Qt.alpha(root.accentBlue, 0.06)
                strokeWidth: 1
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                PathPolyline { path: sineWave.wave(3.5, 3, 0.6, 1.2) }
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
                    textFormat: Text.PlainText
                    text: "GPU"
                    font.family: Config.font
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.5
                    color: Config.mutedColor
                    Layout.preferredWidth: 40
                }

                Text {
                    textFormat: Text.PlainText
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
                        width: SystemMonitorService.gpuUsageKnown ? parent.width * (SystemMonitorService.gpuUsage / 100) : 0
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
                    textFormat: Text.PlainText
                    text: SystemMonitorService.gpuUsageKnown ? SystemMonitorService.gpuUsage + "%" : "—"
                    font.family: Config.font
                    font.pixelSize: 13
                    font.bold: true
                    color: Config.subtextColor
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 36
                }

                // GPU temp
                Text {
                    textFormat: Text.PlainText
                    text: SystemMonitorService.gpuTempKnown ? SystemMonitorService.gpuTemp + "°" : "—"
                    font.family: Config.font
                    font.pixelSize: 12
                    color: SystemMonitorService.gpuTempKnown ? root.tempColor(SystemMonitorService.gpuTemp) : Config.subtextColor
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
                DottedBorder {
                    anchors.fill: parent
                    radius: Config.radius
                    strokeColor: Qt.alpha("#f5f5f0", 0.8)
                }
                


                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    Text {
                        textFormat: Text.PlainText
                        text: "↓"
                        font.family: Config.font
                        font.pixelSize: 15
                        font.bold: true
                        color: root.okColor
                    }

                    Text {
                        textFormat: Text.PlainText
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
                DottedBorder {
                    anchors.fill: parent
                    radius: Config.radius
                    strokeColor: Qt.alpha("#f5f5f0", 0.8)
                }
                


                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    Text {
                        textFormat: Text.PlainText
                        text: "↑"
                        font.family: Config.font
                        font.pixelSize: 15
                        font.bold: true
                        color: root.warnColor
                    }

                    Text {
                        textFormat: Text.PlainText
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
        Shape {
            id: thinRule
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            ShapePath {
                strokeColor: Qt.alpha(Config.textColor, 0.15)
                strokeWidth: 1
                strokeStyle: ShapePath.DashLine
                capStyle: ShapePath.FlatCap
                dashPattern: [2, 4]
                fillColor: "transparent"
                startX: 0; startY: 0
                PathLine { x: thinRule.width; y: 0 }
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
                    textFormat: Text.PlainText
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
                    textFormat: Text.PlainText
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
                
                DottedBorder {
                    anchors.fill: parent
                    radius: Config.radiusLarge
                    strokeColor: Qt.alpha("#f5f5f0", 0.8)
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


                    
                    Shape {
                        id: powerBracket
                        anchors.fill: parent
                        antialiasing: true
                        property color bracketColor: root.profileColor(root.profileForIndex(root.selectedPowerIndex))
                        Behavior on bracketColor { ColorAnimation { duration: Config.animDuration } }
                        ShapePath {
                            strokeColor: powerBracket.bracketColor
                            strokeWidth: 2
                            capStyle: ShapePath.FlatCap
                            fillColor: "transparent"
                            startX: 10; startY: 0
                            PathLine { x: Config.radius; y: 0 }
                            PathArc { x: 0; y: Config.radius; radiusX: Config.radius; radiusY: Config.radius; direction: PathArc.Counterclockwise }
                            PathLine { x: 0; y: 10 }
                            PathMove { x: 0; y: powerBracket.height - 10 }
                            PathLine { x: 0; y: powerBracket.height - Config.radius }
                            PathArc { x: Config.radius; y: powerBracket.height; radiusX: Config.radius; radiusY: Config.radius; direction: PathArc.Counterclockwise }
                            PathLine { x: 10; y: powerBracket.height }
                            PathMove { x: powerBracket.width - 10; y: 0 }
                            PathLine { x: powerBracket.width - Config.radius; y: 0 }
                            PathArc { x: powerBracket.width; y: Config.radius; radiusX: Config.radius; radiusY: Config.radius }
                            PathLine { x: powerBracket.width; y: 10 }
                            PathMove { x: powerBracket.width; y: powerBracket.height - 10 }
                            PathLine { x: powerBracket.width; y: powerBracket.height - Config.radius }
                            PathArc { x: powerBracket.width - Config.radius; y: powerBracket.height; radiusX: Config.radius; radiusY: Config.radius }
                            PathLine { x: powerBracket.width - 10; y: powerBracket.height }
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
                                    textFormat: Text.PlainText
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
                                    textFormat: Text.PlainText
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
            textFormat: Text.PlainText
            text: metric.label
            font.family: Config.font
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 1.5
            color: Config.mutedColor
            Layout.preferredWidth: 40
        }

        Text {
            textFormat: Text.PlainText
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
            textFormat: Text.PlainText
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
