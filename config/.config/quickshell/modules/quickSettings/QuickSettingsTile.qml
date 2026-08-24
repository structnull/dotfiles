pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string subLabel: ""

    property bool active: false
    property bool hasDetails: false

    signal toggled
    signal openDetails

    Layout.fillWidth: true
    implicitHeight: 62
    radius: 14

    color: {
        if (root.active)
            return Qt.alpha(Config.accentColor, 0.18);
        if (mouseArea.containsMouse)
            return Config.surface2Color;
        return Qt.alpha(Config.surface1Color, 0.6);
    }

    border.width: 1
    border.color: {
        if (root.active)
            return Qt.alpha(Config.accentColor, 0.45);
        if (mouseArea.containsMouse)
            return Qt.alpha(Config.textColor, 0.16);
        return Qt.alpha(Config.textColor, 0.06);
    }

    Behavior on color {
        ColorAnimation {
            duration: Config.animDurationShort
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Config.animDurationShort
        }
    }

    scale: {
        if (mouseArea.pressed)
            return 0.94;
        if (mouseArea.containsMouse)
            return 1.02;
        return 1.0;
    }

    Behavior on scale {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutQuad
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.icon
            font.family: Config.font
            font.pixelSize: Config.fontSizeIcon
            color: root.active ? Config.accentColor : (mouseArea.containsMouse ? Config.textColor : Config.subtextColor)
            Layout.alignment: Qt.AlignHCenter

            Behavior on color {
                ColorAnimation {
                    duration: Config.animDurationShort
                }
            }
        }

        Text {
            text: root.label
            font.family: Config.font
            font.bold: true
            font.pixelSize: 11
            color: root.active ? Config.accentColor : (mouseArea.containsMouse ? Config.textColor : Config.mutedColor)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignHCenter

            Behavior on color {
                ColorAnimation {
                    duration: Config.animDurationShort
                }
            }
        }
    }

    ToolTip.visible: mouseArea.containsMouse
    ToolTip.delay: 450
    ToolTip.text: {
        var txt = root.label;
        if (root.subLabel !== "")
            txt += " • " + root.subLabel;
        if (root.hasDetails)
            txt += "\n(Hold or Right-click for settings)";
        return txt;
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        pressAndHoldInterval: 350

        property bool holdTriggered: false

        onPressed: mouse => {
            holdTriggered = false;
        }

        onPressAndHold: mouse => {
            if (mouse.button === Qt.LeftButton && root.hasDetails) {
                holdTriggered = true;
                root.openDetails();
            }
        }

        onClicked: mouse => {
            if (holdTriggered) {
                holdTriggered = false;
                return;
            }

            if (mouse.button === Qt.RightButton && root.hasDetails) {
                root.openDetails();
            } else {
                root.toggled();
            }
        }
    }
}
