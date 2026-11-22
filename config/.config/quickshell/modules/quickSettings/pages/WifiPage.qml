pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.config
import qs.services
import "../../../components/"

Item {
    id: root

    signal backRequested
    signal connectRequested(var network)

    Layout.fillWidth: true
    implicitHeight: 350

    ColumnLayout {
        id: main
        anchors.fill: parent
        spacing: 12

        // Header
        PageHeader {
            icon: NetworkService.systemIcon
            title: "Wi-Fi"
            onBackClicked: root.backRequested()

            // On/Off Switch
            QsSwitch {
                checked: NetworkService.wifiEnabled
                onToggled: NetworkService.toggleWifi()
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Config.surface1Color
        }

        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: NetworkService.connectionError
            textFormat: Text.PlainText
            color: Config.errorColor
            font.family: Config.font
            font.pixelSize: Config.fontSizeSmall
            wrapMode: Text.Wrap
        }

        // Network List
        ListView {
            id: wifiList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 10
            clip: true
            spacing: 8

            model: ScriptModel { comparisonMode: ObjectComparison.Structure; values: NetworkService.wifiEnabled ? NetworkService.accessPoints : [] }

            delegate: DeviceCard {
                required property var modelData

                property bool isConnectingThis: NetworkService.pendingNetwork === modelData.network && !NetworkService.awaitingPassword

                title: modelData.ssid || "Hidden Network"
                subtitle: Math.round(modelData.signal * 100) + "%"
                icon: NetworkService.getWifiIcon(modelData.signal)

                active: modelData.active
                connecting: isConnectingThis
                secured: modelData.secure && !active && !connecting

                statusText: {
                    if (connecting)
                        return "Connecting...";
                    if (active)
                        return "Connected";
                    if (modelData.saved)
                        return "Saved";
                    if (modelData.secure)
                        return "Secured";
                    return "Open";
                }

                showMenu: !connecting

                menuModel: {
                    var list = [];
                    if (active) {
                        list.push({
                            text: "Disconnect",
                            action: "disconnect",
                            icon: "",
                            textColor: Config.warningColor,
                            iconColor: Config.warningColor
                        });
                    } else {
                        list.push({
                            text: "Connect",
                            action: "connect",
                            icon: "",
                            textColor: Config.successColor,
                            iconColor: Config.successColor
                        });
                    }
                    if (active || modelData.saved) {
                        list.push({
                            text: "Forget",
                            action: "forget",
                            icon: "",
                            textColor: Config.errorColor,
                            iconColor: Config.errorColor
                        });
                    }
                    return list;
                }

                onMenuAction: actionId => {
                    if (actionId === "disconnect") {
                        NetworkService.disconnect();
                    } else if (actionId === "connect") {
                        wifiToggleConnect();
                    } else if (actionId === "forget") {
                        modelData.network?.forget();
                    }
                }

                onClicked: wifiToggleConnect()

                function wifiToggleConnect() {
                    if (active) {
                        NetworkService.disconnect();
                        return;
                    }
                    root.connectRequested(modelData.network);
                }
            }

            // Empty state
            Column {
                anchors.centerIn: parent
                spacing: 12
                visible: !NetworkService.wifiEnabled || (wifiList.count === 0)

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 64
                    height: 64
                    radius: 32
                    color: Config.surface1Color

                    Text {
                        textFormat: Text.PlainText
                        anchors.centerIn: parent
                        text: {
                            if (!NetworkService.wifiEnabled)
                                return "󰤮";
                            if (NetworkService.scanning)
                                return "󰤩";
                            return "󰤫";
                        }
                        font.family: Config.font
                        font.pixelSize: 28
                        color: Config.subtextColor
                        opacity: 0.5
                    }
                }

                Text {
                    textFormat: Text.PlainText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (!NetworkService.wifiEnabled)
                            return "Wi-Fi Off";
                        if (NetworkService.scanning)
                            return "Scanning...";
                        return "No networks found";
                    }
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    color: Config.subtextColor
                    opacity: 0.7
                }

                Text {
                    textFormat: Text.PlainText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (!NetworkService.wifiEnabled)
                            return "Turn on to see networks";
                        if (NetworkService.scanning)
                            return "Looking for networks";
                        return "Try scanning again";
                    }
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    color: Config.subtextColor
                    opacity: 0.5
                }
            }
        }
    }
}
