pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import "../../components/"

BarButton {
    id: root

    readonly property color okColor: "#7ee2a8"
    readonly property color lowColor: "#ff5f57"
    readonly property color pluggedColor: "#8ab4ff"

    property bool popupLoaded: false
    readonly property var popupWindow: detailsLoader.item

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
    visible: BatteryService.hasBattery || BatteryService.isPlugged
    contentItem: content
    onClicked: togglePopup()

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: BatteryService.getBatteryIcon()
            font.family: Config.font
            font.pixelSize: Config.fontSizeNormal + 1
            font.bold: true
            color: {
                if (BatteryService.isCharging)
                    return root.okColor;
                if (BatteryService.isLow)
                    return root.lowColor;
                if (BatteryService.isPlugged)
                    return root.pluggedColor;
                return Config.textColor;
            }
        }

        Text {
            visible: BatteryService.hasBattery
            text: BatteryService.percentage + "%"
            font.family: Config.font
            font.pixelSize: Config.fontSizeSmall - 1
            font.bold: true
            color: Config.textColor
        }
    }

    Loader {
        id: detailsLoader
        active: root.popupLoaded
        asynchronous: true
        source: "./BatteryStatusWindow.qml"

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
