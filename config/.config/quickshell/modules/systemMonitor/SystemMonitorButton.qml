pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import "../../components/"

BarButton {
    id: root

    property bool popupLoaded: false
    readonly property var popupWindow: monitorLoader.item

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
    contentItem: buttonContent
    onClicked: togglePopup()

    RowLayout {
        id: buttonContent
        anchors.centerIn: parent
        spacing: Config.spacing

        Text {
            text: "󰍛"
            font.family: Config.font
            font.pixelSize: Config.fontSizeLarge
            color: root.active ? Config.accentColor : Config.textColor

            Behavior on color {
                ColorAnimation { duration: Config.animDuration }
            }
        }
    }

    Loader {
        id: monitorLoader
        active: root.popupLoaded
        asynchronous: true
        source: "./SystemMonitorWindow.qml"

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
