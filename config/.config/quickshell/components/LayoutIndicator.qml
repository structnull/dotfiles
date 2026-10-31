pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services

Item {
    id: root

    readonly property var layouts: ({
        scrolling: ({ symbol: "≋", label: "Scrolling" }),
        dwindle: ({ symbol: "◩", label: "Dwindle" }),
        master: ({ symbol: "▰", label: "Master" }),
        monocle: ({ symbol: "◉", label: "Monocle" })
    })

    readonly property var current: layouts[LayoutService.currentLayout] ?? ({ symbol: "", label: "" })

    implicitWidth: LayoutService.visible ? 92 : 0
    implicitHeight: 20
    width: implicitWidth
    height: implicitHeight
    clip: true

    Behavior on implicitWidth {
        NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: capsule
        anchors.fill: parent
        anchors.leftMargin: 6
        radius: height / 2
        color: Qt.alpha(Config.surface2Color, 0.88)
        border.width: 1
        border.color: Qt.alpha(Config.accentColor, 0.28)
        opacity: LayoutService.visible ? 1 : 0

        Row {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            spacing: 6
            opacity: LayoutService.visible ? 1 : 0

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.current.symbol
                color: Config.accentColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal + 1
                font.bold: true
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.current.label
                color: Config.textColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                font.bold: true
            }

            Behavior on opacity {
                NumberAnimation { duration: Config.animDuration }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Config.animDuration }
        }
    }
}
