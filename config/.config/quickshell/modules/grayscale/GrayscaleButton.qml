pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import "../../components/"

BarButton {
    id: root

    active: GrayscaleService.enabled

    contentItem: Text {
        id: icon
        anchors.centerIn: parent
        text: "󰹊"
        font.family: Config.font
        font.pixelSize: Config.fontSizeIcon
        color: root.active ? Config.accentColor : Config.subtextColor

        Behavior on color {
            ColorAnimation {
                duration: Config.animDuration
            }
        }
    }

    ToolTip.visible: root.hovered
    ToolTip.text: root.active ? "Grayscale: on" : "Grayscale: off"
    ToolTip.delay: 500

    onClicked: GrayscaleService.toggle()
}
