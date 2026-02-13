pragma ComponentBehavior: Bound
import QtQuick
import qs.config

Rectangle {
    id: root

    property bool active: false
    property Item contentItem: null
    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool highlighted: active || hovered

    signal clicked
    signal rightClicked

    implicitWidth: (contentItem?.implicitWidth ?? 0) + (Config.padding * 2)
    implicitHeight: Config.barHeight - 10
    radius: 8

    color: {
        if (!highlighted)
            return "transparent";
        return Qt.rgba(1, 1, 1, active ? 0.14 : 0.09);
    }
    border.width: highlighted ? 1 : 0
    border.color: highlighted ? Qt.rgba(1, 1, 1, 0.26) : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Config.animDuration
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Config.animDuration
        }
    }

    Behavior on border.width {
        NumberAnimation {
            duration: Config.animDurationShort
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
    }
}
