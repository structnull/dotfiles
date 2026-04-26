pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import "../../components/"

BarButton {
    id: root

    property bool popupLoaded: false
    readonly property var popupWindow: notificationLoader.item

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
    contentItem: icon
    onClicked: togglePopup()
    onRightClicked: NotificationService.toggleDnd()

    Text {
        id: icon
        anchors.centerIn: parent
        text: {
            if (NotificationService.dndEnabled)
                return "󰂛";
            if (NotificationService.count > 0)
                return "󰂚";
            return "󰂜";
        }
        font.family: Config.font
        font.pixelSize: Config.fontSizeLarge
        color: root.active ? Config.accentColor : Config.textColor

        Behavior on color {
            ColorAnimation {
                duration: Config.animDuration
            }
        }
    }

    // Count badge
    Rectangle {
        visible: NotificationService.count > 0 && !NotificationService.dndEnabled
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -2
        anchors.rightMargin: -2

        width: Math.max(14, badgeText.implicitWidth + 6)
        height: 14
        radius: 7

        color: "#ff0000"

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: NotificationService.count > 99 ? "99+" : NotificationService.count.toString()
            font.family: Config.font
            font.pixelSize: 9
            font.bold: true
            color: "#ffffff"
        }
    }

    Loader {
        id: notificationLoader
        active: root.popupLoaded
        asynchronous: true
        source: "./NotificationWindow.qml"

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
