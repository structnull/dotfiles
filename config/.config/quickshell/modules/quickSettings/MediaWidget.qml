pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Rectangle {
    id: root

    visible: MprisService.hasPlayer

    Layout.fillWidth: true
    readonly property int sourceRowHeight: MprisService.orderedPlayersCount > 1 ? 28 : 0
    readonly property int sourceExpandedExtra: (sourceDropdownOpen && MprisService.orderedPlayersCount > 1) ? (sourceListColumn.implicitHeight + 12) : 0
    implicitHeight: 148 + sourceRowHeight + sourceExpandedExtra
    radius: 4
    clip: true
    color: "transparent"

    property string transitionKey: MprisService.trackKey
    property bool sourceDropdownOpen: false

    onVisibleChanged: {
        if (!visible)
            sourceDropdownOpen = false;
    }

    Connections {
        target: MprisService
        function onOrderedPlayersCountChanged() {
            if (MprisService.orderedPlayersCount <= 1)
                sourceDropdownOpen = false;
        }
    }

    onTransitionKeyChanged: {
        if (progressWave)
            progressWave.visualProgress = MprisService.progress;
        if (swapAnim.running)
            swapAnim.stop();
        swapAnim.start();
    }

    SequentialAnimation {
        id: swapAnim
        NumberAnimation {
            target: contentWrap
            property: "opacity"
            to: 0.55
            duration: 70
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: contentWrap
            property: "opacity"
            to: 1
            duration: 180
            easing.type: Easing.OutQuad
        }
    }

    // ====== DOTTED WIREFRAME BORDER ======
    Canvas {
        id: mediaBorder
        anchors.fill: parent
        antialiasing: true

        property color strokeColor: Qt.alpha(Config.textColor, 0.2)

        onStrokeColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.setLineDash([6, 4]);
            ctx.strokeStyle = strokeColor.toString();
            ctx.lineWidth = 1;
            var r = root.radius;
            var x = 0.5, y = 0.5, w = width - 1, h = height - 1;
            ctx.beginPath();
            ctx.moveTo(x + r, y);
            ctx.lineTo(x + w - r, y);
            ctx.arcTo(x + w, y, x + w, y + r, r);
            ctx.lineTo(x + w, y + h - r);
            ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
            ctx.lineTo(x + r, y + h);
            ctx.arcTo(x, y + h, x, y + h - r, r);
            ctx.lineTo(x, y + r);
            ctx.arcTo(x, y, x + r, y, r);
            ctx.closePath();
            ctx.stroke();
        }
    }

    Item {
        id: contentWrap
        anchors.fill: parent
        opacity: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // Cover art with wireframe frame
            Rectangle {
                id: coverShell
                Layout.preferredWidth: 90
                Layout.preferredHeight: 90
                Layout.alignment: Qt.AlignVCenter
                radius: 4
                color: Qt.alpha(Config.surface1Color, 0.5)
                border.width: 0
                clip: true

                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: MprisService.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                    sourceSize: Qt.size(320, 320)
                    visible: status === Image.Ready
                }

                // Subtle vignette
                Rectangle {
                    anchors.fill: parent
                    visible: coverImage.visible
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: "transparent"
                        }
                        GradientStop {
                            position: 1.0
                            color: Qt.alpha(Config.backgroundColor, 0.2)
                        }
                    }
                }

                // Fallback icon
                Text {
                    anchors.centerIn: parent
                    visible: !coverImage.visible
                    text: ""
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeIconLarge
                    color: Qt.alpha(Config.subtextColor, 0.5)
                }

                // Play state badge
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 5
                    anchors.bottomMargin: 5
                    width: 22
                    height: 16
                    radius: 8
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.alpha(Config.textColor, 0.25)

                    Text {
                        anchors.centerIn: parent
                        text: MprisService.isPlaying ? "" : ""
                        font.family: Config.font
                        font.pixelSize: 8
                        color: Config.subtextColor
                        anchors.horizontalCenterOffset: MprisService.isPlaying ? 0 : 0.5
                    }
                }

                // Dotted frame around cover
                Canvas {
                    anchors.fill: parent
                    antialiasing: true
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.setLineDash([4, 3]);
                        ctx.strokeStyle = Qt.alpha(Config.textColor, 0.2).toString();
                        ctx.lineWidth = 1;
                        var r = 4;
                        var x = 0.5, y = 0.5, w = width - 1, h = height - 1;
                        ctx.beginPath();
                        ctx.moveTo(x + r, y);
                        ctx.lineTo(x + w - r, y);
                        ctx.arcTo(x + w, y, x + w, y + r, r);
                        ctx.lineTo(x + w, y + h - r);
                        ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
                        ctx.lineTo(x + r, y + h);
                        ctx.arcTo(x, y + h, x, y + h - r, r);
                        ctx.lineTo(x, y + r);
                        ctx.arcTo(x, y, x + r, y, r);
                        ctx.closePath();
                        ctx.stroke();
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 3

                // Status pill
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: MprisService.isPlaying ? "▸ PLAYING" : "‖ PAUSED"
                        font.family: Config.font
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1.5
                        color: MprisService.isPlaying ? Config.accentColor : Config.mutedColor
                        opacity: 0.7

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration
                            }
                        }
                    }
                }

                // Title
                Text {
                    Layout.fillWidth: true
                    text: MprisService.title
                    color: Config.textColor
                    font.family: Config.font
                    font.bold: true
                    font.pixelSize: Config.fontSizeNormal + 1
                    elide: Text.ElideRight
                }

                // Artist
                Text {
                    Layout.fillWidth: true
                    text: MprisService.album !== "" ? (MprisService.artist + " · " + MprisService.album) : MprisService.artist
                    color: Config.subtextColor
                    opacity: 0.7
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    elide: Text.ElideRight
                }

                // Source picker
                Item {
                    id: sourcePickerBlock
                    visible: MprisService.orderedPlayersCount > 1
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? (sourceDropdownOpen ? (sourceListColumn.implicitHeight + 34) : 28) : 0

                    Rectangle {
                        id: sourceButton
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: 26
                        radius: 4
                        color: "transparent"
                        border.width: 1
                        border.color: sourceButtonMouse.containsMouse ? Qt.alpha(Config.textColor, 0.4) : Qt.alpha(Config.textColor, 0.2)

                        Behavior on border.color {
                            ColorAnimation {
                                duration: Config.animDurationShort
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Rectangle {
                                width: 5
                                height: 5
                                radius: 2.5
                                color: MprisService.isPlaying ? Config.accentColor : Config.mutedColor
                            }

                            Text {
                                text: "Source: " + (MprisService.playerIdentity !== "" ? MprisService.playerIdentity : "Media")
                                color: Config.subtextColor
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: sourceDropdownOpen ? "▴" : "▾"
                                color: Config.subtextColor
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                            }
                        }

                        MouseArea {
                            id: sourceButtonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sourceDropdownOpen = !sourceDropdownOpen
                        }
                    }

                    Rectangle {
                        id: sourceDropdownPanel
                        anchors.top: sourceButton.bottom
                        anchors.topMargin: 4
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: sourceListColumn.implicitHeight + 8
                        radius: 4
                        color: Qt.alpha(Config.surface0Color, 0.96)
                        border.width: 1
                        border.color: Qt.alpha(Config.textColor, 0.2)
                        visible: sourceDropdownOpen
                        opacity: visible ? 1 : 0
                        transformOrigin: Item.Top
                        scale: visible ? 1 : 0.97

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Config.animDurationShort
                                easing.type: Easing.OutQuad
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: Config.animDurationShort
                                easing.type: Easing.OutQuad
                            }
                        }

                        Column {
                            id: sourceListColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 4
                            spacing: 4

                            Repeater {
                                model: MprisService.orderedPlayers

                                Rectangle {
                                    required property var modelData

                                    readonly property string key: MprisService.playerKey(modelData)
                                    readonly property string displayName: MprisService.playerDisplayName(modelData)
                                    readonly property bool active: MprisService.activePlayerKey === key
                                    readonly property bool playing: modelData?.isPlaying ?? false

                                    width: sourceListColumn.width
                                    height: 28
                                    radius: 4
                                    color: active ? Qt.alpha(Config.accentColor, 0.12) : "transparent"
                                    border.width: active ? 1 : 0.5
                                    border.color: active ? Qt.alpha(Config.accentColor, 0.3) : Qt.alpha(Config.textColor, 0.15)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        Rectangle {
                                            width: 5
                                            height: 5
                                            radius: 2.5
                                            color: playing ? Config.accentColor : Qt.alpha(Config.mutedColor, 0.6)
                                        }

                                        Text {
                                            text: displayName
                                            font.family: Config.font
                                            font.pixelSize: Config.fontSizeSmall
                                            font.bold: active
                                            color: active ? Config.accentColor : Config.textColor
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: active ? "" : (playing ? "" : "")
                                            font.family: Config.font
                                            font.pixelSize: Config.fontSizeSmall
                                            color: active ? Config.accentColor : Config.subtextColor
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            MprisService.setActivePlayer(modelData);
                                            sourceDropdownOpen = false;
                                        }
                                    }

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

                // ====== SINE WAVE PROGRESS ======
                Canvas {
                    id: progressWave
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    property real visualProgress: MprisService.progress

                    function clamped(value) {
                        return Math.max(0, Math.min(1, value));
                    }

                    function syncProgress() {
                        if (!seekArea.pressed)
                            visualProgress = clamped(MprisService.progress);
                    }

                    Behavior on visualProgress {
                        enabled: !seekArea.pressed
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }

                    Connections {
                        target: MprisService
                        function onProgressChanged() {
                            progressWave.syncProgress();
                        }
                    }

                    onVisualProgressChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();

                        var w = width;
                        var h = height;
                        var cy = h / 2;
                        var amp = 8;
                        var freq = 0.18;
                        var prog = clamped(visualProgress);
                        var splitX = w * prog;

                        var accent = Config.accentColor.toString();
                        var muted = Qt.alpha(Config.textColor, 0.2).toString();

                        // Draw played portion
                        if (splitX > 0) {
                            ctx.beginPath();
                            ctx.moveTo(0, cy);
                            for (var x = 0; x <= splitX; x += 1) {
                                var y = cy + Math.sin(x * freq) * amp;
                                ctx.lineTo(x, y);
                            }
                            ctx.strokeStyle = accent;
                            ctx.lineWidth = 2;
                            ctx.stroke();
                        }

                        // Draw remaining portion
                        if (splitX < w) {
                            ctx.beginPath();
                            ctx.moveTo(splitX, cy + Math.sin(splitX * freq) * amp);
                            for (var x2 = splitX; x2 <= w; x2 += 1) {
                                var y2 = cy + Math.sin(x2 * freq) * amp;
                                ctx.lineTo(x2, y2);
                            }
                            ctx.strokeStyle = muted;
                            ctx.lineWidth = 1;
                            ctx.stroke();
                        }

                        // Current position marker
                        if (prog > 0 && prog < 1) {
                            var markerY = cy + Math.sin(splitX * freq) * amp;
                            // Outer ring
                            ctx.beginPath();
                            ctx.arc(splitX, markerY, 6, 0, 2 * Math.PI);
                            ctx.strokeStyle = accent;
                            ctx.lineWidth = 1.5;
                            ctx.stroke();
                            // Center dot
                            ctx.beginPath();
                            ctx.arc(splitX, markerY, 2, 0, 2 * Math.PI);
                            ctx.fillStyle = accent;
                            ctx.fill();
                        }
                    }

                    MouseArea {
                        id: seekArea
                        anchors.fill: parent
                        enabled: MprisService.canSeek
                        hoverEnabled: true
                        cursorShape: MprisService.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor

                        function updateFromMouse(mouseX) {
                            const percent = progressWave.clamped(mouseX / width);
                            progressWave.visualProgress = percent;
                            MprisService.seekToProgress(percent);
                        }

                        onPressed: function(mouse) {
                            updateFromMouse(mouse.x);
                        }
                        onPositionChanged: function(mouse) {
                            if (pressed)
                                updateFromMouse(mouse.x);
                        }
                    }
                }

                // Controls row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: MprisService.elapsedText
                        color: Config.mutedColor
                        font.family: Config.font
                        font.pixelSize: 10
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Previous
                    WireframeButton {
                        icon: ""
                        enabledState: MprisService.canGoPrevious
                        onClicked: MprisService.previous()
                    }

                    // Play/Pause
                    Rectangle {
                        id: playButton
                        width: 44
                        height: 32
                        radius: 16
                        color: playMouse.containsMouse ? Qt.alpha(Config.accentColor, 0.15) : Qt.alpha(Config.accentColor, 0.08)
                        border.width: 1.5
                        border.color: playMouse.containsMouse ? Config.accentColor : Qt.alpha(Config.accentColor, 0.7)
                        enabled: MprisService.canControl
                        opacity: enabled ? 1 : 0.4

                        Behavior on border.color {
                            ColorAnimation {
                                duration: Config.animDurationShort
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDurationShort
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: MprisService.isPlaying ? "" : ""
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeLarge
                            font.bold: true
                            color: Config.accentColor
                            anchors.horizontalCenterOffset: MprisService.isPlaying ? 0 : 1
                        }

                        scale: playMouse.pressed ? 0.9 : 1.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                            }
                        }

                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            enabled: playButton.enabled
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: MprisService.playPause()
                        }
                    }

                    // Next
                    WireframeButton {
                        icon: ""
                        enabledState: MprisService.canGoNext
                        onClicked: MprisService.next()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: MprisService.remainingText
                        color: Config.mutedColor
                        font.family: Config.font
                        font.pixelSize: 10
                    }
                }
            }
        }
    }

    // Wireframe icon button component
    component WireframeButton: Rectangle {
        id: btn

        property string icon: ""
        property bool enabledState: true
        signal clicked

        width: 32
        height: 32
        radius: 16
        color: buttonMouse.containsMouse ? Qt.alpha(Config.textColor, 0.1) : "transparent"
        border.width: 1
        border.color: buttonMouse.containsMouse ? Qt.alpha(Config.textColor, 0.5) : Qt.alpha(Config.textColor, 0.25)
        opacity: enabledState ? 1 : 0.3

        Behavior on border.color {
            ColorAnimation {
                duration: Config.animDurationShort
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Config.animDurationShort
            }
        }

        Text {
            anchors.centerIn: parent
            text: btn.icon
            font.family: Config.font
            font.pixelSize: Config.fontSizeNormal
            font.bold: true
            color: Config.textColor

            Behavior on color {
                ColorAnimation {
                    duration: Config.animDurationShort
                }
            }
        }

        scale: buttonMouse.pressed ? 0.85 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: 100
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            enabled: btn.enabledState
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: btn.clicked()
        }
    }
}
