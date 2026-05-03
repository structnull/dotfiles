pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property string icon: ""
    property bool showPercentage: true
    property bool alwaysShowPercentage: false
    property bool percentageFromRawValue: false
    property color fillColor: Config.accentColor
    property bool hasDetails: false
    property string detailsIcon: ""
    property real visualValue: 0
    readonly property real clampedValue: clampValue(value)

    Behavior on visualValue {
        enabled: !sliderMouse.pressed
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    signal moved(real newValue)
    signal iconClicked
    signal openDetails

    implicitHeight: 40
    Layout.fillWidth: true

    function clampValue(rawValue) {
        return Math.max(from, Math.min(to, rawValue));
    }

    Component.onCompleted: {
        visualValue = clampedValue;
    }

    onClampedValueChanged: {
        if (!sliderMouse.pressed)
            visualValue = clampedValue;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // Icon button: wireframe outline
        Rectangle {
            id: iconBtn
            Layout.fillHeight: true
            Layout.preferredWidth: height
            radius: Config.radius
            color: "transparent"
            border.width: 1
            border.color: iconMouse.containsMouse ? Qt.alpha(Config.textColor, 0.4) : Qt.alpha(Config.textColor, 0.2)

            Behavior on border.color {
                ColorAnimation {
                    duration: 150
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: Config.font
                font.pixelSize: Config.fontSizeLarge
                font.bold: true
                color: Config.textColor

                scale: iconMouse.pressed ? 0.85 : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            MouseArea {
                id: iconMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.iconClicked()
            }
        }

        // Slider track area
        Item {
            id: sliderContainer
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height

            readonly property real percent: {
                var p = (root.visualValue - root.from) / (root.to - root.from);
                return Math.max(0, Math.min(1, p));
            }

            // Background track line
            Rectangle {
                id: track
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 2
                radius: 1
                color: Qt.alpha(Config.textColor, 0.15)
            }

            // Fill line
            Rectangle {
                id: fill
                anchors.left: track.left
                anchors.verticalCenter: track.verticalCenter
                height: track.height
                radius: 1
                width: track.width * sliderContainer.percent
                color: root.fillColor
            }

            // Tick dots at 0%, 25%, 50%, 75%, 100%
            Repeater {
                model: 5

                Rectangle {
                    required property int index

                    readonly property real tickPos: index / 4
                    readonly property bool active: tickPos <= sliderContainer.percent

                    x: track.x + (track.width * tickPos) - (width / 2)
                    y: track.y + (track.height - height) / 2
                    width: 4
                    height: 4
                    radius: 2
                    color: active ? root.fillColor : Qt.alpha(Config.textColor, 0.2)
                    opacity: 0.5

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }
            }

            // Handle: outlined circle with center dot
            Item {
                id: handle
                x: Math.max(0, Math.min(track.width - width, track.width * sliderContainer.percent - width / 2))
                y: track.y + (track.height - height) / 2
                width: 14
                height: 14

                Rectangle {
                    anchors.fill: parent
                    radius: parent.width / 2
                    color: "transparent"
                    border.width: 1.5
                    border.color: root.fillColor

                    Rectangle {
                        anchors.centerIn: parent
                        width: 4
                        height: 4
                        radius: 2
                        color: root.fillColor
                    }
                }

                scale: sliderMouse.pressed ? 1.3 : (sliderMouse.containsMouse ? 1.15 : 1.0)
                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Floating percentage tooltip
            Rectangle {
                id: percentTooltip
                visible: root.showPercentage
                x: handle.x + (handle.width - width) / 2
                y: handle.y - height - 8
                width: percentText.implicitWidth + 12
                height: 20
                radius: 4
                color: Config.surface0Color
                border.width: 0.5
                border.color: Qt.alpha(Config.textColor, 0.2)

                opacity: (sliderMouse.containsMouse || sliderMouse.pressed || root.alwaysShowPercentage) ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Text {
                    id: percentText
                    anchors.centerIn: parent
                    text: {
                        if (root.percentageFromRawValue)
                            return Math.round(root.visualValue * 100) + "%";
                        return Math.round(((root.visualValue - root.from) / (root.to - root.from)) * 100) + "%";
                    }
                    font.family: Config.font
                    font.bold: true
                    font.pixelSize: 10
                    color: Config.subtextColor
                }
            }

            MouseArea {
                id: sliderMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function updateFromMouse(mouseX) {
                    let percent = mouseX / width;
                    percent = Math.max(0, Math.min(1, percent));
                    let val = root.from + (root.to - root.from) * percent;
                    root.visualValue = val;
                    root.moved(val);
                }

                preventStealing: true
                onPressed: mouse => updateFromMouse(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed)
                        updateFromMouse(mouse.x);
                }

                onWheel: wheel => {
                    let step = (root.to - root.from) * 0.05;
                    if (wheel.angleDelta.y > 0)
                        root.visualValue = Math.min(root.to, root.visualValue + step);
                    else
                        root.visualValue = Math.max(root.from, root.visualValue - step);

                    root.moved(root.visualValue);
                }
            }
        }

        // Details button: wireframe outline
        Rectangle {
            id: detailsBtn
            visible: root.hasDetails
            Layout.fillHeight: true
            Layout.preferredWidth: height
            radius: Config.radius
            color: "transparent"
            border.width: 1
            border.color: detailsMouse.containsMouse ? Qt.alpha(Config.textColor, 0.4) : Qt.alpha(Config.textColor, 0.2)

            Behavior on border.color {
                ColorAnimation {
                    duration: 150
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.detailsIcon
                font.family: Config.font
                font.pixelSize: Config.fontSizeLarge
                font.bold: true
                color: detailsMouse.containsMouse ? Config.textColor : Qt.alpha(Config.textColor, 0.7)

                scale: detailsMouse.pressed ? 0.85 : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            MouseArea {
                id: detailsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openDetails()
            }
        }
    }
}
