pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config

Switch {
    id: root

    implicitWidth: 44
    implicitHeight: 24

    indicator: Rectangle {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight
        radius: height / 2

        // Subtle tint fill when on for contrast
        color: root.checked ? Qt.alpha(Config.accentColor, 0.12) : "transparent"
        border.width: 1.5
        border.color: root.checked ? Config.accentColor : Qt.alpha(Config.textColor, 0.3)

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

        // Sliding dot
        Rectangle {
            x: root.checked ? (parent.width - width - 5) : 5
            anchors.verticalCenter: parent.verticalCenter
            width: root.checked ? 13 : 10
            height: root.checked ? 13 : 10
            radius: width / 2

            color: root.checked ? Config.accentColor : "transparent"
            border.width: root.checked ? 0 : 1.5
            border.color: Qt.alpha(Config.textColor, 0.25)

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

            Behavior on x {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.5
                }
            }

            Behavior on width {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    contentItem: Item {}
}
