pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import "../../../components/"

Item {
    id: root

    signal backRequested

    Layout.fillWidth: true
    implicitHeight: 480
    Component.onCompleted: AudioService.refreshDevices()

    ColumnLayout {
        id: main
        anchors.fill: parent
        spacing: 12

        PageHeader {
            icon: "󰕾"
            title: "Audio"
            onBackClicked: root.backRequested()

            RefreshButton {
                loading: AudioService.refreshingDevices
                onClicked: AudioService.refreshDevices()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Config.surface1Color
        }

        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: contentColumn.implicitHeight + 28

            Column {
                id: contentColumn
                x: 10
                y: 10
                width: Math.max(0, scroll.width - 20)
                spacing: 14

                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Output"
                        color: Config.textColor
                        font.family: Config.font
                        font.bold: true
                        font.pixelSize: Config.fontSizeNormal
                    }

                    Text {
                        text: AudioService.outputStatusText
                        color: Config.subtextColor
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Rectangle {
                        visible: AudioService.outputDevices.length === 0
                        width: parent.width
                        height: 46
                        radius: Config.radiusLarge
                        color: Qt.alpha(Config.surface1Color, 0.6)

                        Text {
                            anchors.centerIn: parent
                            text: "No output devices found"
                            color: Config.subtextColor
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeSmall
                        }
                    }

                    Column {
                        id: outputColumn
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: AudioService.outputDevices

                            DeviceCard {
                                required property var modelData

                                width: outputColumn.width
                                title: modelData.name
                                subtitle: modelData.subtitle
                                icon: modelData.icon
                                active: modelData.isDefault
                                connecting: AudioService.switchingOutputName === modelData.nodeName
                                statusText: connecting ? "Switching..." : (active ? "Default" : "")
                                onClicked: AudioService.setDefaultOutput(modelData.nodeName)
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Config.surface1Color
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Input"
                        color: Config.textColor
                        font.family: Config.font
                        font.bold: true
                        font.pixelSize: Config.fontSizeNormal
                    }

                    Text {
                        text: AudioService.inputStatusText
                        color: Config.subtextColor
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Item {
                        id: micSlider
                        visible: AudioService.sourceReady
                        width: parent.width
                        height: 28

                        readonly property real from: 0
                        readonly property real to: 1.5
                        readonly property real sourceValue: Math.max(from, Math.min(to, AudioService.sourceVolume))
                        property real visualValue: sourceValue

                        onSourceValueChanged: {
                            if (!micMouse.pressed)
                                visualValue = sourceValue;
                        }

                        Behavior on visualValue {
                            NumberAnimation {
                                duration: Config.animDurationShort
                                easing.type: Easing.OutQuad
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: 8

                            Text {
                                text: AudioService.sourceMuted ? "" : ""
                                color: AudioService.sourceMuted ? Config.mutedColor : Config.subtextColor
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall + 1
                                font.bold: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Item {
                                id: micTrackArea
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                readonly property real valuePercent: Math.max(0, Math.min(1, (micSlider.visualValue - micSlider.from) / (micSlider.to - micSlider.from)))

                                Rectangle {
                                    id: micTrack
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: 6
                                    radius: 3
                                    color: Qt.alpha(Config.surface2Color, 0.9)
                                }

                                Rectangle {
                                    anchors.left: micTrack.left
                                    anchors.verticalCenter: micTrack.verticalCenter
                                    height: micTrack.height
                                    radius: micTrack.radius
                                    width: micTrack.width * micTrackArea.valuePercent
                                    color: AudioService.sourceMuted ? Config.mutedColor : Config.accentColor

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: Config.animDurationShort
                                            easing.type: Easing.OutQuad
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 10
                                    height: 10
                                    radius: 5
                                    y: micTrack.y + (micTrack.height - height) / 2
                                    x: Math.max(0, Math.min(micTrack.width - width, (micTrack.width * micTrackArea.valuePercent) - (width / 2)))
                                    color: AudioService.sourceMuted ? Config.mutedColor : Config.textColor
                                    border.width: 1
                                    border.color: Qt.alpha(Config.backgroundColor, 0.35)

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: Config.animDurationShort
                                            easing.type: Easing.OutQuad
                                        }
                                    }
                                }

                                MouseArea {
                                    id: micMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor

                                    function setFromMouse(mouseX) {
                                        const percent = Math.max(0, Math.min(1, mouseX / width));
                                        const next = micSlider.from + (micSlider.to - micSlider.from) * percent;
                                        micSlider.visualValue = next;
                                        AudioService.setSourceVolume(next);
                                    }

                                    onPressed: mouse => setFromMouse(mouse.x)
                                    onPositionChanged: mouse => {
                                        if (pressed)
                                            setFromMouse(mouse.x);
                                    }

                                    onWheel: wheel => {
                                        const step = (micSlider.to - micSlider.from) * 0.04;
                                        let next = micSlider.visualValue;
                                        if (wheel.angleDelta.y > 0)
                                            next = Math.min(micSlider.to, micSlider.visualValue + step);
                                        else
                                            next = Math.max(micSlider.from, micSlider.visualValue - step);

                                        micSlider.visualValue = next;
                                        AudioService.setSourceVolume(next);
                                    }
                                }
                            }

                            Text {
                                Layout.preferredWidth: 42
                                horizontalAlignment: Text.AlignRight
                                text: AudioService.sourcePercentage + "%"
                                color: Config.subtextColor
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }

                    Column {
                        id: inputPortColumn
                        visible: AudioService.inputPorts.length > 1
                        width: parent.width
                        spacing: 6

                        Text {
                            text: "Microphone source"
                            color: Config.subtextColor
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeSmall
                        }

                        Flickable {
                            width: inputPortColumn.width
                            height: 34
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            contentWidth: portPillsRow.implicitWidth
                            contentHeight: height

                            Row {
                                id: portPillsRow
                                y: 1
                                spacing: 6

                                Repeater {
                                    model: AudioService.inputPorts

                                    Rectangle {
                                        required property var modelData
                                        readonly property bool switching: AudioService.switchingInputPortName === modelData.portName

                                        height: 30
                                        radius: 15
                                        color: modelData.isActive ? Config.accentColor : Config.surface1Color
                                        border.width: modelData.isActive ? 0 : 1
                                        border.color: Config.surface2Color
                                        width: chipLabel.implicitWidth + chipIcon.implicitWidth + chipStatus.implicitWidth + 28

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Text {
                                                id: chipIcon
                                                text: modelData.icon
                                                font.family: Config.font
                                                font.pixelSize: Config.fontSizeSmall
                                                color: modelData.isActive ? Config.textReverseColor : Config.textColor
                                            }

                                            Text {
                                                id: chipLabel
                                                text: modelData.name
                                                font.family: Config.font
                                                font.pixelSize: Config.fontSizeSmall
                                                font.bold: true
                                                color: modelData.isActive ? Config.textReverseColor : Config.textColor
                                            }

                                            Text {
                                                id: chipStatus
                                                text: switching ? "…" : ""
                                                font.family: Config.font
                                                font.pixelSize: Config.fontSizeSmall
                                                color: modelData.isActive ? Qt.alpha(Config.textReverseColor, 0.85) : Config.subtextColor
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: AudioService.setInputPort(modelData.portName)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: AudioService.inputDevices.length === 0
                        width: parent.width
                        height: 46
                        radius: Config.radiusLarge
                        color: Qt.alpha(Config.surface1Color, 0.6)

                        Text {
                            anchors.centerIn: parent
                            text: "No input devices found"
                            color: Config.subtextColor
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeSmall
                        }
                    }

                    Column {
                        id: inputColumn
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: AudioService.inputDevices

                            DeviceCard {
                                required property var modelData

                                width: inputColumn.width
                                title: modelData.name
                                subtitle: modelData.subtitle
                                icon: modelData.icon
                                active: modelData.isDefault
                                connecting: AudioService.switchingInputName === modelData.nodeName
                                statusText: connecting ? "Switching..." : (active ? "Default" : "")
                                onClicked: AudioService.setDefaultInput(modelData.nodeName)
                            }
                        }
                    }
                }
            }
        }
    }
}
