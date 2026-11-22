pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.config
import "../../components/"

BarButton {
    id: root
    accessibleName: "System monitor"

    property bool popupLoaded: false
    readonly property var popupWindow: monitorLoader.active ? monitorLoader.item : null

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
            textFormat: Text.PlainText
            text: "󰍛"
            font.family: Config.font
            font.pixelSize: Config.fontSizeLarge
            color: root.active ? Config.accentColor : Config.textColor

            Behavior on color {
                ColorAnimation { duration: Config.animDuration }
            }
        }
    }

    LazyLoader {
        id: monitorLoader
        activeAsync: root.popupLoaded
        source: "./SystemMonitorWindow.qml"

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
