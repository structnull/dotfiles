pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.config
import qs.services
import "../../../components/"

Item {
    id: root

    signal backRequested

    Layout.fillWidth: true
    implicitHeight: 480

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
                        textFormat: Text.PlainText
                        text: "Output"
                        color: Config.textColor
                        font.family: Config.font
                        font.bold: true
                        font.pixelSize: Config.fontSizeNormal
                    }

                    Text {
                        textFormat: Text.PlainText
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
                            textFormat: Text.PlainText
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
                            model: ScriptModel { comparisonMode: ObjectComparison.Structure; values: AudioService.outputDevices }

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
                        textFormat: Text.PlainText
                        text: "Input"
                        color: Config.textColor
                        font.family: Config.font
                        font.bold: true
                        font.pixelSize: Config.fontSizeNormal
                    }

                    Text {
                        textFormat: Text.PlainText
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
                                textFormat: Text.PlainText
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
                                textFormat: Text.PlainText
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

                    Rectangle {
                        visible: AudioService.inputDevices.length === 0
                        width: parent.width
                        height: 46
                        radius: Config.radiusLarge
                        color: Qt.alpha(Config.surface1Color, 0.6)

                        Text {
                            textFormat: Text.PlainText
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
                            model: ScriptModel { comparisonMode: ObjectComparison.Structure; values: AudioService.inputDevices }

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
