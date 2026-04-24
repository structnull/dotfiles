pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
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
    implicitHeight: 54
    radius: 3
    color: "transparent"

    property color borderCol: {
        if (active)
            return Config.accentColor;
        if (mainMouse.containsMouse || (detailsMouse.containsMouse && hasDetails))
            return Qt.alpha(Config.textColor, 0.5);
        return Qt.alpha(Config.textColor, 0.25);
    }

    Behavior on borderCol {
        ColorAnimation {
            duration: Config.animDuration
        }
    }

    // Scale on hover/press
    scale: {
        if (mainMouse.pressed || detailsMouse.pressed)
            return 0.97;
        if (mainMouse.containsMouse || (detailsMouse.containsMouse && hasDetails))
            return 1.02;
        return 1.0;
    }

    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    // ====== DOTTED WIREFRAME BORDER ======
    Canvas {
        id: borderCanvas
        anchors.fill: parent
        antialiasing: true

        property color strokeColor: root.borderCol

        onStrokeColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.setLineDash([5, 4]);
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


    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 6
        spacing: 0

        // Toggle area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: 12

                Text {
                    text: root.icon
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeIcon
                    color: root.active ? Config.accentColor : Config.textColor

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: root.label
                        font.family: Config.font
                        font.bold: true
                        font.pixelSize: Config.fontSizeNormal
                        color: root.active ? Config.accentColor : Config.textColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration
                            }
                        }
                    }

                    Text {
                        visible: root.subLabel !== ""
                        text: root.subLabel
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: root.active ? Qt.alpha(Config.accentColor, 0.6) : Config.mutedColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: mainMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggled()
            }
        }

        // Thin separator
        Rectangle {
            visible: root.hasDetails
            Layout.preferredWidth: 1
            Layout.preferredHeight: parent.height * 0.4
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            color: Qt.alpha(root.borderCol, 0.5)
        }

        // Details arrow
        Item {
            visible: root.hasDetails
            Layout.preferredWidth: 28
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: ""
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal + 1
                font.bold: true
                color: {
                    if (root.active)
                        return detailsMouse.containsMouse ? Config.accentColor : Qt.alpha(Config.accentColor, 0.8);
                    return detailsMouse.containsMouse ? Config.textColor : Qt.alpha(Config.textColor, 0.7);
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
