pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import "../../components/"

BarButton {
    id: root

    property bool popupLoaded: false
    readonly property var popupWindow: calendarLoader.item

    function togglePopup() {
        if (popupWindow) {
            if (popupWindow.visible)
                popupWindow.closeWindow();
            else
                popupWindow.visible = true;
            return;
        }

        popupLoaded = true;
    }

    active: popupWindow?.visible ?? false
    contentItem: clockText
    onClicked: togglePopup()

    Text {
        id: clockText
        anchors.centerIn: parent
        text: TimeService.format("hh:mm AP")
        font.family: Config.font
        font.pixelSize: Config.fontSizeNormal
        font.bold: true
        color: root.active ? Config.accentColor : Config.textColor

        Behavior on color {
            ColorAnimation { duration: Config.animDuration }
        }
    }

    Loader {
        id: calendarLoader
        active: root.popupLoaded
        asynchronous: true
        source: "./CalendarWindow.qml"

        onLoaded: {
            item.anchorItem = root;
            item.visible = true;
        }
    }

    Connections {
        target: root.popupWindow

        function onVisibleChanged() {
            if (root.popupWindow && !root.popupWindow.visible)
                root.popupLoaded = false;
        }
    }
}
