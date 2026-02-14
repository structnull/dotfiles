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
    implicitHeight: 142 + sourceRowHeight + sourceExpandedExtra
    radius: Config.radiusLarge
    clip: true
    color: Config.surface1Color
    border.width: 1
    border.color: Qt.alpha(Config.surface3Color, 0.55)

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
        if (progressBar)
            progressBar.visualProgress = MprisService.progress;
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

    Item {
        id: contentWrap
        anchors.fill: parent
        opacity: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Rectangle {
                id: coverShell
                Layout.preferredWidth: 94
                Layout.preferredHeight: 94
                Layout.alignment: Qt.AlignVCenter
                radius: Config.radiusLarge
                color: Qt.alpha(Config.surface2Color, 0.95)
                border.width: 1
                border.color: Qt.alpha(Config.surface3Color, 0.85)
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

                Rectangle {
                    anchors.fill: parent
                    visible: coverImage.visible
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Qt.alpha(Config.backgroundColor, 0.0)
                        }
                        GradientStop {
                            position: 1.0
                            color: Qt.alpha(Config.backgroundColor, 0.18)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: !coverImage.visible
                    text: ""
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeIconLarge
                    color: Qt.alpha(Config.subtextColor, 0.8)
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 6
                    anchors.bottomMargin: 6
                    width: 26
                    height: 18
                    radius: 9
                    color: Qt.alpha(Config.surface0Color, 0.82)
                    border.width: 1
                    border.color: Qt.alpha(Config.surface3Color, 0.65)

                    Text {
                        anchors.centerIn: parent
                        text: MprisService.isPlaying ? "" : ""
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: Config.textColor
                        anchors.horizontalCenterOffset: MprisService.isPlaying ? 0 : 1
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredHeight: 20
                        Layout.preferredWidth: statusLabel.implicitWidth + 12
                        radius: 10
                        color: MprisService.isPlaying ? Qt.alpha(Config.successColor, 0.18) : Qt.alpha(Config.surface3Color, 0.34)
                        border.width: 1
                        border.color: MprisService.isPlaying ? Qt.alpha(Config.successColor, 0.45) : Qt.alpha(Config.surface3Color, 0.7)

                        Text {
                            id: statusLabel
                            anchors.centerIn: parent
                            text: MprisService.isPlaying ? "Playing" : "Paused"
                            color: MprisService.isPlaying ? Config.successColor : Config.subtextColor
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeSmall
                            font.bold: true
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: MprisService.title
                    color: Config.textColor
                    font.family: Config.font
                    font.bold: true
                    font.pixelSize: Config.fontSizeNormal + 1
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: MprisService.album !== "" ? (MprisService.artist + " • " + MprisService.album) : MprisService.artist
                    color: Qt.alpha(Config.subtextColor, 0.88)
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    elide: Text.ElideRight
                }

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
                        radius: 8
                        color: sourceButtonMouse.containsMouse ? Qt.alpha(Config.surface3Color, 0.9) : Qt.alpha(Config.surface2Color, 0.8)
                        border.width: 1
                        border.color: Qt.alpha(Config.surface3Color, 0.62)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: MprisService.isPlaying ? Config.successColor : Config.mutedColor
                            }

                            Text {
                                text: "Source: " + (MprisService.playerIdentity !== "" ? MprisService.playerIdentity : "Media")
                                color: Config.textColor
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

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDurationShort
                            }
                        }
                    }

                    Rectangle {
                        id: sourceDropdownPanel
                        anchors.top: sourceButton.bottom
                        anchors.topMargin: 4
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: sourceListColumn.implicitHeight + 8
                        radius: 8
                        color: Qt.alpha(Config.surface0Color, 0.96)
                        border.width: 1
                        border.color: Qt.alpha(Config.surface3Color, 0.7)
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
                                    height: 30
                                    radius: 8
                                    color: active ? Qt.alpha(Config.accentColor, 0.95) : Qt.alpha(Config.surface1Color, 0.95)
                                    border.width: active ? 0 : 1
                                    border.color: Qt.alpha(Config.surface3Color, 0.6)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: playing ? Config.successColor : Qt.alpha(Config.mutedColor, 0.8)
                                        }

                                        Text {
                                            text: displayName
                                            font.family: Config.font
                                            font.pixelSize: Config.fontSizeSmall
                                            font.bold: active
                                            color: active ? Config.textReverseColor : Config.textColor
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: active ? "" : (playing ? "" : "")
                                            font.family: Config.font
                                            font.pixelSize: Config.fontSizeSmall
                                            color: active ? Qt.alpha(Config.textReverseColor, 0.86) : Qt.alpha(Config.subtextColor, 0.86)
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

                Item {
                    id: progressBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24

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
                            progressBar.syncProgress();
                        }
                    }

                    Rectangle {
                        id: progressTrack
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 5
                        radius: 2
                        color: Qt.alpha(Config.surface2Color, 0.85)
                    }

                    Rectangle {
                        id: progressFill
                        anchors.left: progressTrack.left
                        anchors.verticalCenter: progressTrack.verticalCenter
                        width: progressTrack.width * progressBar.clamped(progressBar.visualProgress)
                        height: progressTrack.height
                        radius: progressTrack.radius
                        color: Qt.alpha(Config.accentColor, 0.96)
                    }

                    Rectangle {
                        width: 9
                        height: 9
                        radius: 5
                        y: progressTrack.y + (progressTrack.height - height) / 2
                        x: Math.max(0, Math.min(progressTrack.width - width, progressFill.width - (width / 2)))
                        color: Qt.alpha(Config.textColor, 0.94)
                        border.width: 1
                        border.color: Qt.alpha(Config.backgroundColor, 0.42)
                    }

                    MouseArea {
                        id: seekArea
                        anchors.fill: parent
                        enabled: MprisService.canSeek
                        hoverEnabled: true
                        cursorShape: MprisService.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor

                        function updateFromMouse(mouseX) {
                            const percent = progressBar.clamped(mouseX / width);
                            progressBar.visualProgress = percent;
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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: MprisService.elapsedText
                        color: Qt.alpha(Config.subtextColor, 0.74)
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    RoundIconButton {
                        icon: ""
                        enabledState: MprisService.canGoPrevious
                        onClicked: MprisService.previous()
                    }

                    Rectangle {
                        id: playButton
                        width: 42
                        height: 30
                        radius: 15
                        color: playMouse.containsMouse ? Qt.lighter(Config.accentColor, 1.06) : Config.accentColor
                        border.width: 1
                        border.color: Qt.alpha(Config.surface3Color, 0.45)
                        enabled: MprisService.canControl
                        opacity: enabled ? 1 : 0.45

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDurationShort
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: MprisService.isPlaying ? "" : ""
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeLarge - 1
                            color: Config.textReverseColor
                            anchors.horizontalCenterOffset: MprisService.isPlaying ? 0 : 1
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

                    RoundIconButton {
                        icon: ""
                        enabledState: MprisService.canGoNext
                        onClicked: MprisService.next()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: MprisService.remainingText
                        color: Qt.alpha(Config.subtextColor, 0.74)
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                    }
                }
            }
        }
    }

    component RoundIconButton: Rectangle {
        id: btn

        property string icon: ""
        property bool enabledState: true
        property int size: 30
        signal clicked

        width: size
        height: size
        radius: size / 2
        color: buttonMouse.containsMouse ? Qt.alpha(Config.surface3Color, 0.9) : Qt.alpha(Config.surface2Color, 0.82)
        opacity: enabledState ? 1 : 0.4
        border.width: 1
        border.color: Qt.alpha(Config.surface3Color, 0.55)

        Text {
            anchors.centerIn: parent
            text: btn.icon
            font.family: Config.font
            font.pixelSize: Config.fontSizeSmall
            color: Config.textColor
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            enabled: btn.enabledState
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: btn.clicked()
        }

        Behavior on color {
            ColorAnimation {
                duration: Config.animDurationShort
            }
        }
    }
}
