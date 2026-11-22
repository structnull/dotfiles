pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    // --- PUBLIC PROPERTIES (preserved interface) ---

    property var accessPoints: []
    property WifiNetwork pendingNetwork: null
    property var connectionOwner: null
    property bool awaitingPassword: false
    property bool triedPassword: false
    property string connectionError: ""
    property int wifiViews: 0
    property WifiDevice scanDevice: null

    signal passwordRequired(var owner)

    function acquireWifiView() {
        if (wifiViews++ === 0) {
            connectionError = "";
            _rebuildAccessPoints();
        }
        _syncScanner();
    }

    function releaseWifiView(owner) {
        wifiViews = Math.max(0, wifiViews - 1);
        if (connectionOwner === owner) {
            if (awaitingPassword)
                finishConnection("");
            else
                connectionOwner = null;
        }
        if (wifiViews === 0)
            accessPoints = [];
        _syncScanner();
    }

    function _syncScanner() {
        // Unknown networks can disappear when discovery stops.
        const needed = wifiViews > 0 || pendingNetwork !== null;
        const nextDevice = needed && wifiEnabled && wifiHardwareEnabled ? liveWifiDevice : null;
        if (scanDevice && scanDevice !== nextDevice)
            scanDevice.scannerEnabled = false;
        scanDevice = nextDevice;
        if (liveWifiDevice)
            liveWifiDevice.scannerEnabled = nextDevice !== null;
    }

    function _radioChanged() {
        if (pendingNetwork && (!wifiEnabled || !wifiHardwareEnabled || pendingNetwork.device !== liveWifiDevice))
            finishConnection("Wi-Fi became unavailable.");
        _syncScanner();
    }

    onPendingNetworkChanged: _syncScanner()
    onWifiEnabledChanged: _radioChanged()
    onWifiHardwareEnabledChanged: _radioChanged()
    onLiveWifiDeviceChanged: _radioChanged()
    Component.onDestruction: {
        if (scanDevice)
            scanDevice.scannerEnabled = false;
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
        if (signal > 0.8)
            return "󰤨";
        if (signal > 0.6)
            return "󰤥";
        if (signal > 0.4)
            return "󰤢";
        if (signal > 0.2)
            return "󰤟";
        return "󰤫";
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function disconnect() {
        if (liveActiveNetwork)
            liveActiveNetwork.disconnect();
        else
            liveWifiDevice?.disconnect();
    }

    function connectNetwork(network: WifiNetwork, owner: QtObject) {
        if (!network || network.device !== liveWifiDevice || pendingNetwork || !wifiEnabled || !wifiHardwareEnabled)
            return;

        connectionError = "";
        connectionOwner = owner;
        triedPassword = false;
        pendingNetwork = network;
        connectionTimeout.restart();
        network.connect();
    }

    function submitPassword(owner: QtObject, password: string) {
        if (!pendingNetwork || connectionOwner !== owner || !awaitingPassword || !password)
            return;
        awaitingPassword = false;
        triedPassword = true;
        connectionError = "";
        connectionTimeout.restart();
        pendingNetwork.connectWithPsk(password);
    }

    function cancelPassword(owner: QtObject) {
        if (connectionOwner === owner && awaitingPassword)
            finishConnection("");
    }

    function finishConnection(error: string) {
        connectionTimeout.stop();
        connectionError = error;
        connectionOwner = null;
        awaitingPassword = false;
        pendingNetwork = null;
    }

    Timer {
        id: connectionTimeout
        interval: 45000
        onTriggered: root.finishConnection("The connection timed out. Try again.")
    }

    Connections {
        target: root.pendingNetwork

        function onConnectedChanged() {
            if (root.pendingNetwork?.connected)
                root.finishConnection("");
        }

        function onConnectionFailed(reason) {
            const network = root.pendingNetwork;
            if (!network)
                return;
            if (reason === ConnectionFailReason.NoSecrets) {
                const security = network.security;
                const supported = security === WifiSecurityType.WpaPsk
                    || security === WifiSecurityType.Wpa2Psk || security === WifiSecurityType.Sae;
                if (supported && root.connectionOwner) {
                    connectionTimeout.stop();
                    root.connectionError = root.triedPassword ? "The network did not accept that password." : "";
                    root.awaitingPassword = true;
                    root.passwordRequired(root.connectionOwner);
                    return;
                }
                if (!supported) {
                    root.finishConnection("Set up this network's authentication in NetworkManager.");
                    return;
                }
            }
            root.finishConnection("Could not connect to " + network.name + " (" + ConnectionFailReason.toString(reason) + ").");
        }
    }

    // --- INTERNAL: Build accessPoints from native API ---

    function _scheduleAccessPointsUpdate() {
        if (wifiViews > 0)
            Qt.callLater(root._rebuildAccessPoints);
    }

    function _rebuildAccessPoints() {
        if (wifiViews === 0)
            return;
        const networks = liveWifiNetworks;
        const rows = [];
        for (let i = 0; i < networks.length; i++) {
            const net = networks[i];
            const ssid = net.name;

            if (!ssid)
                continue;
            rows.push({
                network: net,
                ssid: ssid,
                signal: net.signalStrength ?? 0,
                active: net.connected,
                secure: net.security !== WifiSecurityType.Open,
                saved: net.known,
            });
        }

        // Sort: Connected > Saved > Signal
        rows.sort((a, b) => {
            if (a.active !== b.active)
                return a.active ? -1 : 1;
            if (a.saved && !b.saved)
                return -1;
            if (!a.saved && b.saved)
                return 1;
            return b.signal - a.signal;
        });

        root.accessPoints = rows;
    }

    // Rebuild whenever the wifi networks list changes
    onLiveWifiNetworksChanged: {
        if (pendingNetwork && !liveWifiNetworks.includes(pendingNetwork))
            finishConnection("The network is no longer available.");
        _scheduleAccessPointsUpdate();
    }

    Instantiator {
        active: root.wifiViews > 0
        model: root.liveWifiDevice?.networks ?? null
        delegate: Connections {
            required property WifiNetwork modelData
            target: modelData
            function onNameChanged() { root._scheduleAccessPointsUpdate(); }
            function onSignalStrengthChanged() { root._scheduleAccessPointsUpdate(); }
            function onConnectedChanged() { root._scheduleAccessPointsUpdate(); }
            function onKnownChanged() { root._scheduleAccessPointsUpdate(); }
            function onSecurityChanged() { root._scheduleAccessPointsUpdate(); }
        }
    }
}
