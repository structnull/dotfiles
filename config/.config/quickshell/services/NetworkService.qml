pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    // --- PUBLIC PROPERTIES (preserved interface) ---

    property var accessPoints: []
    property string connectingSsid: ""

    readonly property var liveDevices: Array.from(Networking.devices.values)
    readonly property var liveWifiDevice: liveDevices.find(device => device.type === DeviceType.Wifi) ?? null
    readonly property var liveEthernetDevice: liveDevices.find(device => device.type === DeviceType.Wired && (device.connected || (device.network?.connected ?? false))) ?? (liveDevices.find(device => device.type === DeviceType.Wired) ?? null)
    readonly property var liveWifiNetworks: liveWifiDevice && liveWifiDevice.networks ? Array.from(liveWifiDevice.networks.values) : []
    readonly property var liveActiveNetwork: liveWifiNetworks.find(network => network.connected) ?? null

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiConnected: (liveWifiDevice?.connected ?? false) || liveActiveNetwork !== null
    readonly property bool ethernetConnected: liveDevices.some(device => device.type === DeviceType.Wired && (device.connected || (device.network?.connected ?? false)))
    readonly property string ethernetInterface: liveEthernetDevice?.name ?? ""
    readonly property var activeNetwork: liveActiveNetwork
    readonly property bool scanning: liveWifiDevice?.scannerEnabled ?? false

    readonly property string systemIcon: {
        if (ethernetConnected)
            return "󰈀";
        if (!wifiEnabled)
            return "󰤮";
        if (activeNetwork)
            return getWifiIcon(activeNetwork.signalStrength ?? 0);
        if (wifiConnected)
            return "󰤨";
        return "󰤫";
    }

    // Status text
    readonly property string statusText: {
        if (ethernetConnected)
            return "Ethernet";
        if (!wifiEnabled)
            return "Off";

        // If there is an active network, return the name
        if (activeNetwork)
            return activeNetwork.name || "Hidden Network";

        if (wifiConnected)
            return "Connected";

        // If enabled but not connected
        return "On";
    }

    // --- FUNCTIONS ---

    function getWifiIcon(signal) {
        if (signal > 0 && signal <= 1)
            signal *= 100;

        if (signal > 80)
            return "󰤨";
        if (signal > 60)
            return "󰤥";
        if (signal > 40)
            return "󰤢";
        if (signal > 20)
            return "󰤟";
        return "󰤫";
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function scan() {
        if (liveWifiDevice) {
            liveWifiDevice.scannerEnabled = true;
        }
    }

    function disconnect() {
        if (liveActiveNetwork) {
            liveActiveNetwork.disconnect();
        } else if (liveWifiDevice) {
            liveWifiDevice.disconnect();
        }
    }

    function connect(ssid, password) {
        const network = liveWifiNetworks.find(n => n.name === ssid);
        if (!network) {
            console.warn("[NetworkService] Network not found: " + ssid);
            return;
        }

        root.connectingSsid = ssid;

        if (password && password.length > 0) {
            network.connectWithPsk(password);
        } else {
            network.connect();
        }
    }

    function forget(ssid) {
        const network = liveWifiNetworks.find(n => n.name === ssid);
        if (!network) {
            console.warn("[NetworkService] Cannot forget unknown network: " + ssid);
            return;
        }
        network.forget();
    }

    // --- INTERNAL: Build accessPoints from native API ---

    function _rebuildAccessPoints() {
        const networks = liveWifiNetworks;
        var tempParams = [];
        const seen = new Set();

        for (let i = 0; i < networks.length; i++) {
            const net = networks[i];
            const ssid = net.name;

            if (!ssid)
                continue;
            if (seen.has(ssid))
                continue;
            seen.add(ssid);

            tempParams.push({
                ssid: ssid,
                signal: Math.round((net.signalStrength ?? 0) * 100),
                active: net.connected,
                secure: net.security !== WifiSecurityType.Open,
                securityType: WifiSecurityType.toString(net.security),
                saved: net.known,
            });
        }

        // Sort: Connected > Saved > Signal
        tempParams.sort((a, b) => {
            if (a.active)
                return -1;
            if (b.active)
                return 1;
            if (a.saved && !b.saved)
                return -1;
            if (!a.saved && b.saved)
                return 1;
            return b.signal - a.signal;
        });

        root.accessPoints = tempParams;
    }

    // Rebuild whenever the wifi networks list changes
    onLiveWifiNetworksChanged: _rebuildAccessPoints()

    // --- INTERNAL: Listen for connectionFailed on all wifi networks ---

    // Use Instantiator to attach connectionFailed handlers to each WifiNetwork
    Instantiator {
        model: liveWifiDevice?.networks ?? null
        delegate: QtObject {
            required property var modelData

            Component.onCompleted: {
                if (modelData.connectionFailed) {
                    modelData.connectionFailed.connect(reason => {
                        console.warn("[NetworkService] Connection failed for " + modelData.name + ": " + reason);
                        if (root.connectingSsid === modelData.name) {
                            root.connectingSsid = "";
                        }
                    });
                }
            }
        }
    }

    // Clear connectingSsid when the target network successfully connects
    onLiveActiveNetworkChanged: {
        if (liveActiveNetwork && liveActiveNetwork.name === connectingSsid) {
            root.connectingSsid = "";
        }
    }
}
