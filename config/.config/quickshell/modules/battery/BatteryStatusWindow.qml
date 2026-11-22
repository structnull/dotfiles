pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import "../../components/"

// Hallmark · component: battery popup · quiet native · existing Config tokens
// Pre-emit critique: philosophy 5, hierarchy 5, execution 4, specificity 5, restraint 5, variety 4.
QsPopupWindow {
    id: root

    popupWidth: 360
    popupMaxHeight: 400
    anchorSide: "right"
    contentImplicitHeight: batteryContent.implicitHeight

    readonly property color stateColor: BatteryService.isLow ? Config.errorColor : Config.accentColor
    readonly property bool hasPowerReading: BatteryService.powerRateKnown
    readonly property string powerLabel: BatteryService.powerRateLabel
    readonly property string estimateText: {
        if (!BatteryService.hasBattery)
            return BatteryService.isPlugged ? "Running on external power" : "No battery detected";
        if (BatteryService.isFull)
            return "Ready to unplug";
        if (BatteryService.isCharging) {
            const seconds = BatteryService.timeToFullSeconds;
            return Number.isFinite(seconds) && seconds > 0
                ? BatteryService.formatDuration(seconds) + " until full" : "Estimating…";
        }
        if (BatteryService.isDischarging) {
            const seconds = BatteryService.timeToEmptySeconds;
            return Number.isFinite(seconds) && seconds > 0
                ? BatteryService.formatDuration(seconds) + " remaining" : "Estimating…";
        }
        return BatteryService.isPlugged ? "Connected, not charging" : "Time estimate unavailable";
    }

    readonly property var history: BatteryService.powerHistory
    readonly property int readingCount: history.filter(value => Number.isFinite(value) && value > 0.05).length
    readonly property bool hasHistory: readingCount >= 2
    readonly property real chartCeiling: {
        let peak = 0;
        for (const value of history) {
            if (Number.isFinite(value) && value > peak)
                peak = value;
        }
        return Math.max(5, Math.ceil(peak * 1.15 / 5) * 5);
    }
    // BatteryService records every five seconds, retaining at most 48 samples.
    readonly property int historySeconds: Math.max(0, history.length - 1) * 5
    readonly property string historyDuration: {
        const minutes = Math.floor(historySeconds / 60);
        const seconds = historySeconds % 60;
        return (minutes > 0 ? minutes + "m " : "") + seconds + "s";
    }

    // The shared popup supplies the border, positioning and opening animation.
    // This opaque inset surface belongs only to the battery popup.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -15
        radius: Math.max(0, Config.radiusLarge - 1)
        color: Config.surface0Color
    }

    ColumnLayout {
        id: batteryContent
        width: parent.width
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                textFormat: Text.PlainText
                text: BatteryService.hasBattery ? "Battery" : "Power"
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
                font.weight: Font.Medium
                color: Config.textColor
            }

            Item { Layout.fillWidth: true }

            Text {
                Layout.maximumWidth: batteryContent.width * 0.65
                textFormat: Text.PlainText
                text: BatteryService.hasBattery
                    ? (BatteryService.isLow ? "Low battery" : BatteryService.statusText)
                    : (BatteryService.isPlugged ? "Connected" : "Disconnected")
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                color: BatteryService.isLow || BatteryService.isCharging ? root.stateColor : Config.subtextColor
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    textFormat: Text.PlainText
                    text: BatteryService.hasBattery ? BatteryService.percentage + "%"
                        : (BatteryService.isPlugged ? "AC power" : "No battery")
                    font.family: Config.font
                    font.pixelSize: BatteryService.hasBattery ? 40 : 28
                    font.weight: Font.DemiBold
                    color: Config.textColor
                    elide: Text.ElideRight
                    Accessible.role: Accessible.StaticText
                    Accessible.name: BatteryService.hasBattery
                        ? BatteryService.percentage + " percent battery" : text
                }

                Text {
                    textFormat: Text.PlainText
                    text: BatteryService.getBatteryIcon()
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeIconLarge
                    color: root.stateColor
                    Accessible.ignored: true
                }
            }

            Text {
                Layout.fillWidth: true
                textFormat: Text.PlainText
                text: root.estimateText
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
                color: Config.subtextColor
                wrapMode: Text.WordWrap
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            visible: BatteryService.hasBattery
            radius: 3
            color: Config.surface2Color
            clip: true
            readonly property real value: BatteryService.percentage
            readonly property real minimumValue: 0
            readonly property real maximumValue: 100
            Accessible.role: Accessible.ProgressBar
            Accessible.name: "Battery charge, " + BatteryService.percentage + " percent"

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, BatteryService.percentage / 100))
                height: parent.height
                radius: parent.radius
                color: root.stateColor

                Behavior on width {
                    NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            visible: BatteryService.hasBattery
            color: Qt.alpha(Config.textColor, 0.10)
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: BatteryService.hasBattery
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    textFormat: Text.PlainText
                    text: root.powerLabel
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    color: Config.subtextColor
                    elide: Text.ElideRight
                }

                Text {
                    textFormat: Text.PlainText
                    text: root.hasPowerReading ? BatteryService.powerRateW.toFixed(1) + " W" : "Unavailable"
                    font.family: Config.font
                    font.pixelSize: root.hasPowerReading ? Config.fontSizeLarge : Config.fontSizeSmall
                    font.weight: Font.Medium
                    color: root.hasPowerReading ? Config.textColor : Config.subtextColor
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        textFormat: Text.PlainText
                        text: "Recent power"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: Config.subtextColor
                    }

                    Text {
                        visible: root.hasHistory
                        textFormat: Text.PlainText
                        text: root.chartCeiling + " W"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: Config.subtextColor
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    Accessible.role: Accessible.StaticText
                    Accessible.name: root.hasHistory
                        ? "Reported power over the last " + root.historyDuration + ", scale zero to " + root.chartCeiling + " watts"
                        : "Waiting for power history"

                    Canvas {
                        id: historyChart
                        anchors.fill: parent
                        antialiasing: true
                        visible: root.hasHistory

                        readonly property var samples: root.history
                        readonly property real ceiling: root.chartCeiling
                        readonly property color lineColor: Config.accentColor
                        readonly property color gridColor: Qt.alpha(Config.textColor, 0.08)
                        onSamplesChanged: requestPaint()
                        onCeilingChanged: requestPaint()
                        onLineColorChanged: requestPaint()
                        onGridColorChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        onVisibleChanged: requestPaint()

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const inset = 3;
                            const plotWidth = Math.max(0, width - inset * 2);
                            const plotHeight = Math.max(0, height - inset * 2);
                            if (!root.hasHistory || plotWidth <= 0 || plotHeight <= 0)
                                return;

                            ctx.strokeStyle = gridColor.toString();
                            ctx.lineWidth = 1;
                            ctx.beginPath();
                            for (let row = 0; row < 3; ++row) {
                                const y = inset + plotHeight * row / 2;
                                ctx.moveTo(inset, y);
                                ctx.lineTo(width - inset, y);
                            }
                            ctx.stroke();

                            ctx.strokeStyle = lineColor.toString();
                            ctx.fillStyle = lineColor.toString();
                            ctx.lineWidth = 2;
                            ctx.lineJoin = "round";
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            let connected = false;
                            for (let i = 0; i < samples.length; ++i) {
                                const value = samples[i];
                                if (!Number.isFinite(value) || value <= 0.05) {
                                    connected = false;
                                    continue;
                                }
                                const x = inset + plotWidth * i / (samples.length - 1);
                                const y = inset + plotHeight * (1 - value / ceiling);
                                if (connected)
                                    ctx.lineTo(x, y);
                                else
                                    ctx.moveTo(x, y);
                                connected = true;
                            }
                            ctx.stroke();

                            // Mark isolated readings and the newest valid sample without bridging gaps.
                            for (let i = 0; i < samples.length; ++i) {
                                const value = samples[i];
                                if (!Number.isFinite(value) || value <= 0.05)
                                    continue;
                                const previousValid = i > 0 && Number.isFinite(samples[i - 1]) && samples[i - 1] > 0.05;
                                const nextValid = i + 1 < samples.length && Number.isFinite(samples[i + 1]) && samples[i + 1] > 0.05;
                                if ((previousValid || nextValid) && i !== samples.length - 1)
                                    continue;
                                ctx.beginPath();
                                ctx.arc(inset + plotWidth * i / (samples.length - 1),
                                    inset + plotHeight * (1 - value / ceiling), 2.5, 0, Math.PI * 2);
                                ctx.fill();
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        width: parent.width
                        visible: !root.hasHistory
                        textFormat: Text.PlainText
                        text: root.readingCount > 0 ? "Collecting power readings…" : "No power readings yet"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: Config.subtextColor
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: root.hasHistory

                    Text {
                        Layout.fillWidth: true
                        textFormat: Text.PlainText
                        text: root.historyDuration + " ago"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: Config.subtextColor
                    }

                    Text {
                        textFormat: Text.PlainText
                        text: "Now"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: Config.subtextColor
                    }
                }
            }
        }
    }
}
