pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import "../../components/"

QsPopupWindow {
    id: root

    popupWidth: 320
    popupMaxHeight: 650
    anchorSide: "left"
    contentImplicitHeight: calendarContent.implicitHeight

    // Calendar state
    property int displayMonth: today.getMonth()
    property int displayYear: today.getFullYear()
    readonly property date today: TimeService.date

    function resetToToday() {
        displayMonth = today.getMonth();
        displayYear = today.getFullYear();
    }

    function previousMonth() {
        if (displayMonth === 0) {
            displayMonth = 11;
            displayYear--;
        } else {
            displayMonth--;
        }
    }

    function nextMonth() {
        if (displayMonth === 11) {
            displayMonth = 0;
            displayYear++;
        } else {
            displayMonth++;
        }
    }

    onVisibleChanged: {
        if (visible)
            resetToToday();
    }

    ColumnLayout {
        id: calendarContent
        anchors.fill: parent
        spacing: 16

        // ==================== CLOCK READOUT ====================
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            
            // Static Background Grid
            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.strokeStyle = Qt.alpha(Config.textColor, 0.04).toString();
                    ctx.lineWidth = 1;
                    for (var gx = 10; gx < width; gx += 10) {
                        ctx.beginPath(); ctx.moveTo(gx, 0); ctx.lineTo(gx, height); ctx.stroke();
                    }
                    for (var gy = 10; gy < height; gy += 10) {
                        ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke();
                    }
                }
            }

            // Animated 60-Second Gauge
            Canvas {
                id: clockCanvas
                anchors.fill: parent
                
                Connections {
                    target: TimeService
                    function onDateChanged() {
                        clockCanvas.requestPaint();
                    }
                }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    var secs = root.today.getSeconds();
                    
                    var padX = 24;
                    var padY = 10;
                    var x0 = padX;
                    var y0 = padY;
                    var x1 = width - padX;
                    var y1 = height - padY;
                    
                    var ticksTop = 20;
                    var ticksRight = 10;
                    var ticksBottom = 20;
                    var ticksLeft = 10;
                    var tickLengthRatio = 0.6; // 60% line, 40% gap
                    
                    function drawTick(i, startPt, endPt) {
                        ctx.beginPath();
                        ctx.moveTo(startPt.x, startPt.y);
                        var drawX = startPt.x + (endPt.x - startPt.x) * tickLengthRatio;
                        var drawY = startPt.y + (endPt.y - startPt.y) * tickLengthRatio;
                        ctx.lineTo(drawX, drawY);
                        
                        if (i < secs) {
                            ctx.strokeStyle = Qt.alpha(Config.accentColor, 0.6).toString();
                            ctx.lineWidth = 2;
                        } else if (i === secs) {
                            ctx.strokeStyle = Config.accentColor.toString();
                            ctx.lineWidth = 4;
                        } else {
                            ctx.strokeStyle = Qt.alpha("#f5f5f0", 0.15).toString();
                            ctx.lineWidth = 2;
                        }
                        ctx.stroke();
                    }
                    
                    // Top edge (0 to 19)
                    var stepX_top = (x1 - x0) / ticksTop;
                    for (var i = 0; i < ticksTop; i++) {
                        drawTick(i, {x: x0 + i*stepX_top, y: y0}, {x: x0 + (i+1)*stepX_top, y: y0});
                    }
                    
                    // Right edge (20 to 29)
                    var stepY_right = (y1 - y0) / ticksRight;
                    for (var i = 0; i < ticksRight; i++) {
                        drawTick(i + ticksTop, {x: x1, y: y0 + i*stepY_right}, {x: x1, y: y0 + (i+1)*stepY_right});
                    }
                    
                    // Bottom edge (30 to 49)
                    var stepX_bottom = (x0 - x1) / ticksBottom; // Negative direction
                    for (var i = 0; i < ticksBottom; i++) {
                        drawTick(i + ticksTop + ticksRight, {x: x1 + i*stepX_bottom, y: y1}, {x: x1 + (i+1)*stepX_bottom, y: y1});
                    }
                    
                    // Left edge (50 to 59)
                    var stepY_left = (y0 - y1) / ticksLeft; // Negative direction
                    for (var i = 0; i < ticksLeft; i++) {
                        drawTick(i + ticksTop + ticksRight + ticksBottom, {x: x0, y: y1 + i*stepY_left}, {x: x0, y: y1 + (i+1)*stepY_left});
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    text: TimeService.format("hh:mm AP")
                    font.family: Config.font
                    font.pixelSize: 52
                    font.bold: true
                    color: Config.accentColor
                    Layout.alignment: Qt.AlignHCenter
                }
            }
            

        }



        // ==================== MONTH NAVIGATION ====================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Previous Button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: prevHover.hovered ? Qt.alpha(Config.textColor, 0.1) : "transparent"
                border.width: 1
                border.color: prevHover.hovered ? Qt.alpha(Config.textColor, 0.4) : Qt.alpha(Config.textColor, 0.15)
                
                Behavior on color { ColorAnimation { duration: Config.animDurationShort } }
                Behavior on border.color { ColorAnimation { duration: Config.animDurationShort } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    color: Config.textColor
                }

                HoverHandler { id: prevHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.previousMonth() }
            }

            // Month Label with progress line
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        var r = 4;
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
                
                Text {
                    anchors.centerIn: parent
                    text: new Date(root.displayYear, root.displayMonth, 1).toLocaleDateString(Qt.locale(), "MMMM yyyy").toUpperCase()
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.bold: true
                    font.letterSpacing: 2
                    color: Config.textColor
                }
                
                HoverHandler {
                    id: monthHover
                    cursorShape: {
                        const now = new Date();
                        if (root.displayMonth === now.getMonth() && root.displayYear === now.getFullYear())
                            return Qt.ArrowCursor;
                        return Qt.PointingHandCursor;
                    }
                }
                TapHandler { onTapped: root.resetToToday() }
                
                // Progress bar indicating month progress
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    height: 2
                    color: Qt.alpha(Config.accentColor, 0.6)
                    width: {
                        var d = new Date(root.displayYear, root.displayMonth, 1);
                        var now = new Date();
                        if (d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear()) {
                            var daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
                            return (now.getDate() / daysInMonth) * parent.width;
                        }
                        return 0;
                    }
                }
            }

            // Next Button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: nextHover.hovered ? Qt.alpha(Config.textColor, 0.1) : "transparent"
                border.width: 1
                border.color: nextHover.hovered ? Qt.alpha(Config.textColor, 0.4) : Qt.alpha(Config.textColor, 0.15)
                
                Behavior on color { ColorAnimation { duration: Config.animDurationShort } }
                Behavior on border.color { ColorAnimation { duration: Config.animDurationShort } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅂"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    color: Config.textColor
                }

                HoverHandler { id: nextHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.nextMonth() }
            }
        }

        // ==================== CALENDAR GRID ====================
        Item {
            Layout.fillWidth: true
            implicitHeight: gridContainer.implicitHeight + 20
            
            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    var r = 4;
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

            ColumnLayout {
                id: gridContainer
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                DayOfWeekRow {
                    Layout.fillWidth: true
                    locale: grid.locale

                    delegate: Text {
                        required property var model
                        horizontalAlignment: Text.AlignHCenter
                        text: model.shortName.toUpperCase()
                        font.family: Config.font
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1
                        color: (model.day === 0 || model.day === 6) ? Qt.alpha(Config.textColor, 0.4) : Qt.alpha(Config.textColor, 0.7)
                    }
                }

                // Dotted line separator
                Canvas {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.setLineDash([2, 4]);
                        ctx.strokeStyle = Qt.alpha("#f5f5f0", 0.6).toString();
                        ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(width, 0); ctx.stroke();
                    }
                }

                MonthGrid {
                    id: grid
                    month: root.displayMonth
                    year: root.displayYear
                    Layout.fillWidth: true
                    spacing: 6
                    locale: Qt.locale()

                    delegate: Item {
                        id: dayCell
                        required property var model
                        readonly property bool isToday: model.today
                        readonly property bool isCurrentMonth: model.month === grid.month
                        readonly property bool isWeekend: {
                            const dow = model.date.getDay();
                            return dow === 0 || dow === 6;
                        }

                        implicitWidth: implicitHeight
                        implicitHeight: dayText.implicitHeight + 16

                        // Active date plate
                        Rectangle {
                            id: todayPlate
                            anchors.centerIn: parent
                            width: Math.min(parent.width - 2, dayText.implicitWidth + 18)
                            height: parent.height - 4
                            visible: dayCell.isToday
                            radius: 4
                            color: Qt.alpha(Config.accentColor, 0.14)
                            border.width: 1
                            border.color: Qt.alpha(Config.accentColor, 0.65)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: 5
                                anchors.rightMargin: 5
                                anchors.bottomMargin: 3
                                height: 2
                                radius: 1
                                color: Config.accentColor
                            }
                        }

                        Text {
                            id: dayText
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            text: dayCell.model.day
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            font.bold: dayCell.isToday
                            color: {
                                if (dayCell.isToday) return Config.accentColor;
                                if (dayCell.isWeekend) return Qt.alpha(Config.textColor, 0.5);
                                return Config.textColor;
                            }
                            opacity: dayCell.isCurrentMonth ? 1.0 : 0.15
                        }
                    }
                }
                
                WheelHandler {
                    onWheel: event => {
                        if (event.angleDelta.y > 0) root.previousMonth();
                        else if (event.angleDelta.y < 0) root.nextMonth();
                    }
                }
            }
        }
    }
}
