pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import "../../components/"

QsPopupWindow {
    id: root

    popupWidth: 388
    popupMaxHeight: 560
    anchorSide: "right"
    contentImplicitHeight: content.implicitHeight

    readonly property color accentInfo: "#8ab4ff"
    readonly property color accentGood: "#7ee2a8"
    readonly property color accentWarn: "#ffcc66"
    readonly property color accentDanger: "#ff5f57"
    readonly property color stateColor: BatteryService.isLow ? accentDanger : (BatteryService.isCharging ? accentGood : accentInfo)
    readonly property color techDot: Qt.alpha("#d8e8ff", 0.12)

    component InfoTile: Item {
        required property string label
        required property string value
        property color valueColor: Config.textColor

        Layout.fillWidth: true
        Layout.preferredHeight: 72

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                var r = 12; // radius matching the other tiles
                ctx.reset();
                ctx.setLineDash([2, 4]);
                ctx.strokeStyle = Qt.alpha("#f5f5f0", 0.6).toString();
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.moveTo(r, 0); ctx.lineTo(width-r, 0); ctx.arcTo(width, 0, width, r, r);
                ctx.lineTo(width, height-r); ctx.arcTo(width, height, width-r, height, r);
                ctx.lineTo(r, height); ctx.arcTo(0, height, 0, height-r, r);
                ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r);
                ctx.stroke();
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 5

            Text {
                text: parent.parent.label
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                color: Config.mutedColor
            }

            Text {
                text: parent.parent.value
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
                font.bold: true
                color: parent.parent.valueColor
            }
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 10

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 144
            clip: true
            
            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    var r = 14;
                    ctx.setLineDash([2, 4]);
                    ctx.strokeStyle = Qt.alpha("#f5f5f0", 0.6).toString();
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(r, 0); ctx.lineTo(width-r, 0); ctx.arcTo(width, 0, width, r, r);
                    ctx.lineTo(width, height-r); ctx.arcTo(width, height, width-r, height, r);
                    ctx.lineTo(r, height); ctx.arcTo(0, height, 0, height-r, r);
                    ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r);
                    ctx.stroke();
                }
            }

            Canvas {
                id: heroAccent
                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    const w = width;
                    const h = height;

                    ctx.fillStyle = Qt.alpha(root.stateColor, 0.15).toString();
                    for (let row = 0; row < Math.floor(h / 12); ++row) {
                        for (let col = 0; col < Math.floor(w / 12); ++col) {
                            const x = 14 + (col * 12) + ((row % 2) * 4);
                            const y = 14 + (row * 12);
                            if (x < w - 10 && y < h - 10) {
                                ctx.beginPath();
                                ctx.arc(x, y, ((row + col) % 5 === 0) ? 1.2 : 0.8, 0, Math.PI * 2);
                                ctx.fill();
                            }
                        }
                    }
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                radius: 19
                                color: Qt.alpha(root.stateColor, 0.14)

                                Text {
                                    anchors.centerIn: parent
                                    text: BatteryService.getBatteryIcon()
                                    font.family: Config.font
                                    font.pixelSize: 19
                                    color: root.stateColor
                                }
                            }

                            ColumnLayout {
                                spacing: 2

                                Text {
                                    text: BatteryService.hasBattery ? (BatteryService.percentage + "%") : "Power"
                                    font.family: Config.font
                                    font.pixelSize: 26
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
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 42
                        color: Qt.alpha(Config.surface3Color, 0.45)
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 96
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        spacing: 3

                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: BatteryService.powerRateText
                            font.family: Config.font
                            font.pixelSize: 19
                            font.bold: true
                            color: root.stateColor
                            horizontalAlignment: Text.AlignRight
                        }

                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: BatteryService.powerRateLabel
                            font.family: Config.font
                            font.pixelSize: 10
                            color: Config.mutedColor
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Charge"
                            font.family: Config.font
                            font.pixelSize: 11
                            color: Config.mutedColor
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: BatteryService.statusText
                            font.family: Config.font
                            font.pixelSize: 11
                            color: Config.mutedColor
                            elide: Text.ElideRight
                        }
                    }

                    Canvas {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 12
                        
                        property real pct: BatteryService.percentage / 100.0
                        property color fillColor: root.stateColor
                        
                        Behavior on pct {
                            NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic }
                        }
                        
                        onPctChanged: requestPaint()
                        onFillColorChanged: requestPaint()
                        
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var w = width;
                            var h = height;
                            
                            var segments = 40;
                            var spacing = 2;
                            var segWidth = (w - (segments - 1) * spacing) / segments;
                            
                            var filledSegments = Math.round(segments * pct);
                            
                            for (var i = 0; i < segments; i++) {
                                var x = i * (segWidth + spacing);
                                ctx.beginPath();
                                
                                // slant the segments
                                ctx.moveTo(x + 2, 0);
                                ctx.lineTo(x + segWidth + 2, 0);
                                ctx.lineTo(x + segWidth - 2, h);
                                ctx.lineTo(x - 2, h);
                                ctx.closePath();
                                
                                if (i < filledSegments) {
                                    ctx.fillStyle = fillColor.toString();
                                } else {
                                    ctx.fillStyle = Qt.alpha("#f5f5f0", 0.15).toString();
                                }
                                ctx.fill();
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 260
            clip: true
            
            // Container dotted border
            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    var r = 14;
                    ctx.reset();
                    ctx.setLineDash([2, 4]);
                    ctx.strokeStyle = Qt.alpha("#f5f5f0", 0.6).toString();
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(r, 0); ctx.lineTo(width-r, 0); ctx.arcTo(width, 0, width, r, r);
                    ctx.lineTo(width, height-r); ctx.arcTo(width, height, width-r, height, r);
                    ctx.lineTo(r, height); ctx.arcTo(0, height, 0, height-r, r);
                    ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r);
                    ctx.stroke();
                }
            }

            // The Sci-Fi Cluster Canvas
            Canvas {
                id: clusterCanvas
                anchors.fill: parent
                property real powerRate: BatteryService.powerRateW
                readonly property real absPower: Math.abs(BatteryService.powerRateW)
                
                property color stateColor: {
                    if (absPower < 25) return root.accentGood;
                    if (absPower < 45) return root.accentWarn;
                    return root.accentDanger;
                }
                
                Behavior on powerRate { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic } }
                onPowerRateChanged: requestPaint()
                onStateColorChanged: requestPaint()
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var w = width;
                    var h = height;
                    var cx = w / 2;
                    var cy = h / 2;
                    
                    var r1 = 45;
                    var r2 = 60;
                    var r3 = 75;
                    
                    // Outer dotted ring
                    ctx.strokeStyle = Qt.alpha("#f5f5f0", 0.2).toString();
                    ctx.lineWidth = 1;
                    ctx.setLineDash([2, 6]);
                    ctx.beginPath();
                    ctx.arc(cx, cy, r3, 0, Math.PI * 2);
                    ctx.stroke();
                    
                    // Middle dashed ring
                    ctx.strokeStyle = Qt.alpha(stateColor.toString(), 0.4);
                    ctx.lineWidth = 3;
                    ctx.setLineDash([8, 12]);
                    ctx.beginPath();
                    ctx.arc(cx, cy, r2, 0, Math.PI * 2);
                    ctx.stroke();
                    
                    // Inner solid ring boundary
                    ctx.strokeStyle = Qt.alpha("#f5f5f0", 0.4).toString();
                    ctx.lineWidth = 1;
                    ctx.setLineDash([]);
                    ctx.beginPath();
                    ctx.arc(cx, cy, r1, 0, Math.PI * 2);
                    ctx.stroke();
                    
                    // Dynamic Power Arc
                    var maxPower = Math.max(30, BatteryService.maxObservedPowerW);
                    var powerAngle = Math.min(1.0, Math.abs(powerRate) / maxPower) * Math.PI * 1.5;
                    var startAngle = Math.PI * 0.75;
                    
                    ctx.strokeStyle = stateColor.toString();
                    ctx.lineWidth = 6;
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.arc(cx, cy, r1 - 6, startAngle, startAngle + powerAngle);
                    ctx.stroke();
                    
                    // --- Circuit Traces to Data ---
                    ctx.strokeStyle = Qt.alpha("#f5f5f0", 0.3).toString();
                    ctx.lineWidth = 1;
                    ctx.setLineDash([2, 4]);
                    
                    var lineLen = 80;
                    
                    // Top Left (Status)
                    var tlY = cy - 65;
                    ctx.beginPath(); ctx.moveTo(cx - r2 * 0.7, cy - r2 * 0.7); ctx.lineTo(cx - r3 - 10, cy - r2 * 0.7); ctx.lineTo(20 + lineLen, tlY); ctx.lineTo(20, tlY); ctx.stroke();
                    
                    // Top Right (Sys Draw)
                    var trY = cy - 65;
                    ctx.beginPath(); ctx.moveTo(cx + r2 * 0.7, cy - r2 * 0.7); ctx.lineTo(cx + r3 + 10, cy - r2 * 0.7); ctx.lineTo(w - 20 - lineLen, trY); ctx.lineTo(w - 20, trY); ctx.stroke();
                    
                    // Bottom Left (Time to full)
                    var blY = cy + 65;
                    ctx.beginPath(); ctx.moveTo(cx - r2 * 0.7, cy + r2 * 0.7); ctx.lineTo(cx - r3 - 10, cy + r2 * 0.7); ctx.lineTo(20 + lineLen, blY); ctx.lineTo(20, blY); ctx.stroke();
                    
                    // Bottom Right (Time to empty)
                    var brY = cy + 65;
                    ctx.beginPath(); ctx.moveTo(cx + r2 * 0.7, cy + r2 * 0.7); ctx.lineTo(cx + r3 + 10, cy + r2 * 0.7); ctx.lineTo(w - 20 - lineLen, brY); ctx.lineTo(w - 20, brY); ctx.stroke();
                    
                    // Node dots
                    ctx.setLineDash([]);
                    ctx.fillStyle = stateColor.toString();
                    [ {x: 20, y: tlY}, {x: w - 20, y: trY}, {x: 20, y: blY}, {x: w - 20, y: brY} ].forEach(p => {
                        ctx.beginPath(); ctx.arc(p.x, p.y, 2.5, 0, Math.PI * 2); ctx.fill();
                    });
                }
            }
            
            // --- Text Readouts ---
            
            // Status (Top Left)
            Column {
                x: 20
                y: parent.height / 2 - 65 - 34
                spacing: 2
                Text { text: "STATUS"; font.family: Config.font; font.pixelSize: 10; font.letterSpacing: 1; color: Config.mutedColor }
                Text { text: BatteryService.statusText; font.family: Config.font; font.pixelSize: 13; font.bold: true; color: clusterCanvas.stateColor }
            }
            
            // Power Flow (Top Right)
            Column {
                x: parent.width - 20 - width
                y: parent.height / 2 - 65 - 34
                spacing: 2
                Text { text: "SYS DRAW"; font.family: Config.font; font.pixelSize: 10; font.letterSpacing: 1; color: Config.mutedColor; anchors.right: parent.right }
                Text { text: BatteryService.powerRateText; font.family: Config.font; font.pixelSize: 13; font.bold: true; color: clusterCanvas.stateColor; anchors.right: parent.right }
            }
            
            // Time to Full (Bottom Left)
            Column {
                x: 20
                y: parent.height / 2 + 65 + 6
                spacing: 2
                Text { text: "TIME TO FULL"; font.family: Config.font; font.pixelSize: 10; font.letterSpacing: 1; color: Config.mutedColor }
                Text { 
                    text: BatteryService.isCharging ? BatteryService.formatDuration(BatteryService.timeToFullSeconds) : "--"
                    font.family: Config.font; font.pixelSize: 13; font.bold: true; color: BatteryService.isCharging ? root.accentGood : Config.textColor 
                }
            }
            
            // Time to Empty (Bottom Right)
            Column {
                x: parent.width - 20 - width
                y: parent.height / 2 + 65 + 6
                spacing: 2
                Text { text: "TIME TO EMPTY"; font.family: Config.font; font.pixelSize: 10; font.letterSpacing: 1; color: Config.mutedColor; anchors.right: parent.right }
                Text { 
                    text: BatteryService.isDischarging ? BatteryService.formatDuration(BatteryService.timeToEmptySeconds) : "--"
                    font.family: Config.font; font.pixelSize: 13; font.bold: true; color: BatteryService.isDischarging ? root.accentWarn : Config.textColor; anchors.right: parent.right
                }
            }
            
            // Center Knob Data
            Column {
                anchors.centerIn: parent
                spacing: 2
                
                Text { 
                    text: BatteryService.isCharging ? "SYS DRAW" : "PWR"
                    font.family: Config.font; font.pixelSize: 10; font.letterSpacing: 2; color: Config.mutedColor; anchors.horizontalCenter: parent.horizontalCenter
                }
                Text { 
                    text: Math.abs(BatteryService.powerRateW).toFixed(1)
                    font.family: Config.font; font.pixelSize: 22; font.bold: true; color: clusterCanvas.stateColor; anchors.horizontalCenter: parent.horizontalCenter
                }
                Text { 
                    text: "W"
                    font.family: Config.font; font.pixelSize: 10; color: Config.mutedColor; anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 14
        }
    }
}
