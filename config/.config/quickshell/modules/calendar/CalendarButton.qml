pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.config
import qs.services
import "../../components/"

BarButton {
    id: root

    property bool popupLoaded: false
    readonly property var popupWindow: calendarLoader.active ? calendarLoader.item : null

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
        textFormat: Text.PlainText
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

    LazyLoader {
        id: calendarLoader
        activeAsync: root.popupLoaded
        source: "./CalendarWindow.qml"

        onActiveChanged: {
            if (!active) return;
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
