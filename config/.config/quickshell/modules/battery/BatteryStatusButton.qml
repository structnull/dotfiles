pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.config
import qs.services
import "../../components/"

BarButton {
    id: root

    property bool popupLoaded: false
    readonly property var popupWindow: detailsLoader.active ? detailsLoader.item : null

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
    accessibleName: "Battery, " + (BatteryService.hasBattery ? BatteryService.percentage + " percent, " : "")
        + BatteryService.statusText

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 4

        Text {
            textFormat: Text.PlainText
            text: BatteryService.getBatteryIcon()
            font.family: Config.font
            font.pixelSize: Config.fontSizeNormal + 1
            font.bold: true
            color: {
                if (BatteryService.isCharging)
                    return Config.accentColor;
                if (BatteryService.isLow)
                    return Config.errorColor;
                if (BatteryService.isPlugged)
                    return Config.accentColor;
                return Config.textColor;
            }
        }

        Text {
            textFormat: Text.PlainText
            visible: BatteryService.hasBattery
            text: BatteryService.percentage + "%"
            font.family: Config.font
            font.pixelSize: Config.fontSizeSmall - 1
            font.bold: true
            color: Config.textColor
        }
    }

    LazyLoader {
        id: detailsLoader
        activeAsync: root.popupLoaded
        source: "./BatteryStatusWindow.qml"

        onActiveChanged: {
            const popup = item as BatteryStatusWindow;
            if (!active || !popup) return;
            popup.anchorItem = root;
            popup.visible = true;
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
