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
    property int settingsWindows: 0
    property bool scanRequested: false
    property var _scanDevice: null

    function acquireSettingsWindow() {
        settingsWindows++;
        _syncScanner();
        if (settingsWindows === 1)
            _rebuildAccessPoints();
    }

    function releaseSettingsWindow() {
        settingsWindows = Math.max(0, settingsWindows - 1);
        // Keep the user's scan intent for the next popup session, but turn
        // the native repeating scanner off while all windows are hidden.
        _syncScanner();
    }

    function _syncScanner() {
        // Unknown networks disappear from QS's model when scanning stops.
        // Keep them available until an in-flight connection succeeds or fails.
        const needed = settingsWindows > 0 || connectingSsid !== "";
        const nextDevice = scanRequested && needed && wifiEnabled && wifiHardwareEnabled ? liveWifiDevice : null;
        if (Qt.isQtObject(_scanDevice) && _scanDevice !== nextDevice)
            _scanDevice.scannerEnabled = false;
        _scanDevice = nextDevice;
        if (_scanDevice)
            _scanDevice.scannerEnabled = true;
        else if (liveWifiDevice && (!needed || !wifiEnabled || !wifiHardwareEnabled))
            liveWifiDevice.scannerEnabled = false;
    }

    function _radioChanged() {
        if (!wifiEnabled || !wifiHardwareEnabled)
            connectingSsid = "";
        _syncScanner();
    }

    onConnectingSsidChanged: _syncScanner()
    onWifiEnabledChanged: _radioChanged()
    onWifiHardwareEnabledChanged: _radioChanged()

    onLiveWifiDeviceChanged: {
        // Native device objects can survive a config reload.
        if (liveWifiDevice?.scannerEnabled)
            scanRequested = true;
        _syncScanner();
    }

    readonly property var liveDevices: Array.from(Networking.devices.values)
    readonly property var liveWifiDevice: liveDevices.find(device => device.type === DeviceType.Wifi) ?? null
    readonly property var liveEthernetDevice: liveDevices.find(device => device.type === DeviceType.Wired && (device.connected || (device.network?.connected ?? false))) ?? (liveDevices.find(device => device.type === DeviceType.Wired) ?? null)
    readonly property var liveWifiNetworks: liveWifiDevice && liveWifiDevice.networks ? Array.from(liveWifiDevice.networks.values) : []
    readonly property var liveActiveNetwork: liveWifiNetworks.find(network => network.connected) ?? null

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
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
        scanRequested = true;
        _syncScanner();
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

    function _scheduleAccessPointsUpdate() {
        if (settingsWindows > 0)
            Qt.callLater(root._rebuildAccessPoints);
    }

    function _rebuildAccessPoints() {
        if (settingsWindows === 0)
            return;
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
            if (a.active !== b.active)
                return a.active ? -1 : 1;
            if (a.saved && !b.saved)
                return -1;
            if (!a.saved && b.saved)
                return 1;
            return b.signal - a.signal;
        });

        if (JSON.stringify(root.accessPoints) !== JSON.stringify(tempParams))
            root.accessPoints = tempParams;
    }

    // Rebuild whenever the wifi networks list changes
    onLiveWifiNetworksChanged: _scheduleAccessPointsUpdate()

    // QObject-bound Connections are released with each delegate. Rebuild only
    // when network data changes, coalescing property bursts into one update.
    Instantiator {
        model: ScriptModel { values: root.liveWifiNetworks }
        delegate: Connections {
            id: networkSignals
            required property var modelData
            target: modelData

            function onConnectionFailed(reason) {
                console.warn("[NetworkService] Connection failed for " + modelData.name + ": " + reason);
                if (root.connectingSsid === modelData.name)
                    root.connectingSsid = "";
            }
            readonly property Connections details: Connections {
                target: networkSignals.modelData
                enabled: root.settingsWindows > 0
                function onNameChanged() { root._scheduleAccessPointsUpdate(); }
                function onSignalStrengthChanged() { root._scheduleAccessPointsUpdate(); }
                function onConnectedChanged() { root._scheduleAccessPointsUpdate(); }
                function onKnownChanged() { root._scheduleAccessPointsUpdate(); }
                function onSecurityChanged() { root._scheduleAccessPointsUpdate(); }
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
