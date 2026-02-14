pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    readonly property bool sinkReady: sink !== null && sink.audio !== null
    readonly property bool sourceReady: source !== null && source.audio !== null

    readonly property bool muted: sinkReady ? (sink.audio.muted ?? false) : false
    property real lastKnownVolume: 0
    readonly property real liveVolume: {
        if (!sinkReady)
            return NaN;
        const vol = sink.audio.volume;
        if (vol === undefined || vol === null || isNaN(vol))
            return NaN;
        return Math.max(0, Math.min(1.5, vol));
    }
    readonly property bool volumeKnown: !isNaN(liveVolume)
    readonly property real volume: volumeKnown ? liveVolume : lastKnownVolume
    readonly property bool outputSilent: muted || (volumeKnown && volume <= 0.001)
    readonly property real volumeForOsd: volume

    readonly property bool sourceMuted: sourceReady ? (source.audio.muted ?? false) : false
    property real lastKnownSourceVolume: 0
    readonly property real liveSourceVolume: {
        if (!sourceReady)
            return NaN;
        const vol = source.audio.volume;
        if (vol === undefined || vol === null || isNaN(vol))
            return NaN;
        return Math.max(0, Math.min(1.5, vol));
    }
    readonly property bool sourceVolumeKnown: !isNaN(liveSourceVolume)
    readonly property real sourceVolume: sourceVolumeKnown ? liveSourceVolume : lastKnownSourceVolume
    readonly property int sourcePercentage: Math.round(sourceVolume * 100)
    property string outputPortHint: ""
    readonly property var sinkProps: sink?.properties ?? ({})
    readonly property string sinkPropsDescriptor: [
        (sinkProps["device.icon-name"] ?? "") + "",
        (sinkProps["device.icon_name"] ?? "") + "",
        (sinkProps["device.form_factor"] ?? "") + "",
        (sinkProps["card.profile.name"] ?? "") + "",
        (sinkProps["device.profile.name"] ?? "") + "",
        (sinkProps["api.alsa.path"] ?? "") + "",
        (sinkProps["api.alsa.pcm.stream"] ?? "") + "",
        (sinkProps["media.class"] ?? "") + ""
    ].join(" ").trim()

    readonly property string outputDescriptor: {
        const parts = [];
        parts.push((sink?.description ?? "") + "");
        parts.push((sink?.nickname ?? "") + "");
        parts.push((sink?.name ?? "") + "");
        parts.push((sink?.iconName ?? "") + "");
        parts.push((sink?.mediaClass ?? "") + "");
        parts.push((sink?.objectName ?? "") + "");
        parts.push((sink?.activePort?.name ?? "") + "");
        parts.push((sink?.activePort?.description ?? "") + "");
        parts.push((sink?.audio?.activePort?.name ?? "") + "");
        parts.push((sink?.audio?.activePort?.description ?? "") + "");
        parts.push((sink?.audio?.port?.name ?? "") + "");
        parts.push((sink?.audio?.port?.description ?? "") + "");
        return parts.join(" ").trim();
    }
    property string outputDeviceType: "speaker"

    property var outputDevices: []
    property var inputDevices: []
    property var sinksRaw: []
    property var sourcesRaw: []
    property string defaultOutputName: ""
    property string defaultInputName: ""
    property string switchingOutputName: ""
    property string switchingInputName: ""
    property string switchingInputPortName: ""
    property string activeInputPortName: ""
    property var inputPorts: []

    readonly property bool refreshingDevices: defaultsProc.running || listSinksProc.running || listSourcesProc.running
    readonly property var activeOutputDevice: outputDevices.find(device => device.isDefault) ?? null
    readonly property var activeInputDevice: inputDevices.find(device => device.isDefault) ?? null

    readonly property string outputStatusText: {
        if (activeOutputDevice)
            return activeOutputDevice.name;
        const fallback = (sink?.description ?? "") + "";
        return fallback.trim() !== "" ? fallback : "Unavailable";
    }

    readonly property string inputStatusText: {
        if (activeInputDevice)
            return activeInputDevice.name;
        const fallback = (source?.description ?? "") + "";
        return fallback.trim() !== "" ? fallback : "Unavailable";
    }

    function inferOutputType(descriptor: string): string {
        const text = descriptor.toLowerCase().trim();
        if (!text)
            return outputDeviceType;

        const hasBluetooth = text.includes("bluez") || text.includes("bluetooth") || text.includes("a2dp");
        const hasHeadphones = text.includes("headphone") || text.includes("headset") || text.includes("earbud") || text.includes("earphone") || text.includes("audio-head") || text.includes("analog-output-headphones");
        const hasSpeakerWord = text.includes("speaker");
        const hasStrongSpeaker = text.includes("hdmi") || text.includes("displayport") || text.includes("line out") || text.includes("iec958") || text.includes("spdif") || text.includes("analog-output-speaker");

        if (hasBluetooth)
            return "bluetooth";
        if (hasHeadphones)
            return "headphones";
        if (hasStrongSpeaker)
            return "speaker";
        if (hasSpeakerWord)
            return outputDeviceType === "speaker" ? "speaker" : outputDeviceType;

        // For generic analog descriptors, preserve the previous non-speaker type.
        if (text.includes("analog") || text.includes("alsa_output"))
            return outputDeviceType;

        // Keep previous type for unknown/unstable descriptors to avoid icon flicker.
        return outputDeviceType;
    }

    function hasBluetoothTransport(descriptor: string): bool {
        const text = descriptor.toLowerCase().trim();
        if (!text)
            return false;
        return text.includes("bluez") || text.includes("bluetooth") || text.includes("a2dp") || text.includes("api.bluez5") || text.includes("bluez_output.");
    }

    function inferOutputTypeForDevice(descriptor: string): string {
        const text = descriptor.toLowerCase().trim();
        if (!text)
            return "speaker";
        if (text.includes("bluez") || text.includes("bluetooth") || text.includes("a2dp"))
            return "bluetooth";
        if (text.includes("headphone") || text.includes("headset") || text.includes("earbud") || text.includes("earphone") || text.includes("audio-head") || text.includes("analog-output-headphones"))
            return "headphones";
        return "speaker";
    }

    function inferInputTypeForDevice(descriptor: string): string {
        const text = descriptor.toLowerCase().trim();
        if (!text)
            return "microphone";
        if (text.includes("bluez") || text.includes("bluetooth") || text.includes("a2dp"))
            return "bluetooth";
        if (text.includes("headset") || text.includes("headphone") || text.includes("earbud"))
            return "headset";
        return "microphone";
    }

    function outputTypeIcon(type: string): string {
        if (type === "bluetooth")
            return "";
        if (type === "headphones")
            return "";
        return "󰕾";
    }

    function outputTypeLabel(type: string): string {
        if (type === "bluetooth")
            return "Bluetooth";
        if (type === "headphones")
            return "Headphones";
        return "Speakers";
    }

    function inputTypeIcon(type: string): string {
        if (type === "bluetooth")
            return "";
        if (type === "headset")
            return "";
        return "";
    }

    function inputTypeLabel(type: string): string {
        if (type === "bluetooth")
            return "Bluetooth Mic";
        if (type === "headset")
            return "Headset Mic";
        return "Microphone";
    }

    function inferInputPortType(portName: string, description: string): string {
        const text = (portName + " " + description).toLowerCase().trim();
        if (text.includes("headset") || text.includes("headphone") || text.includes("analog-input-headset-mic"))
            return "headset";
        if (text.includes("internal") || text.includes("built-in") || text.includes("builtin") || text.includes("analog-input-internal-mic"))
            return "internal";
        if (text.includes("front") || text.includes("rear") || text.includes("dock") || text.includes("line"))
            return "external";
        return "microphone";
    }

    function inputPortIcon(type: string): string {
        if (type === "headset")
            return "";
        if (type === "internal")
            return "󰍬";
        if (type === "external")
            return "";
        return "";
    }

    function inputPortLabel(type: string, description: string): string {
        if (type === "headset")
            return "Headset mic";
        if (type === "internal")
            return "Internal mic";
        const safeDescription = sanitizeText(description, "");
        return safeDescription !== "" ? safeDescription : "Microphone";
    }

    function normalizePorts(rawPorts): var {
        const ports = [];
        if (Array.isArray(rawPorts)) {
            rawPorts.forEach(portItem => {
                if (!portItem)
                    return;
                ports.push(portItem);
            });
            return ports;
        }
        if (rawPorts && typeof rawPorts === "object") {
            Object.keys(rawPorts).forEach(key => {
                const portItem = rawPorts[key];
                if (portItem && typeof portItem === "object") {
                    ports.push({
                        name: sanitizeText(portItem.name, key),
                        description: sanitizeText(portItem.description, key),
                        availability: sanitizeText(portItem.availability, "")
                    });
                } else {
                    ports.push({
                        name: key,
                        description: key
                    });
                }
            });
        }
        return ports;
    }

    function sanitizeText(value, fallback): string {
        const fallbackText = ((fallback ?? "") + "").trim();
        const text = ((value ?? "") + "").trim();
        if (text !== "")
            return text;
        return fallbackText;
    }

    function buildDescriptor(item): string {
        const props = item?.properties ?? ({});
        return [
            sanitizeText(item?.description),
            sanitizeText(item?.name),
            sanitizeText(item?.active_port),
            sanitizeText(item?.driver),
            sanitizeText(props["device.description"]),
            sanitizeText(props["node.description"]),
            sanitizeText(props["node.nick"]),
            sanitizeText(props["device.icon_name"]),
            sanitizeText(props["device.icon-name"]),
            sanitizeText(props["device.form_factor"]),
            sanitizeText(props["card.profile.name"]),
            sanitizeText(props["device.profile.name"]),
            sanitizeText(props["api.alsa.path"]),
            sanitizeText(props["api.alsa.pcm.stream"]),
            sanitizeText(props["media.class"])
        ].join(" ").trim();
    }

    function parseJsonArray(raw) {
        const text = ((raw ?? "") + "").trim();
        if (text === "")
            return [];
        try {
            const parsed = JSON.parse(text);
            return Array.isArray(parsed) ? parsed : [];
        } catch (_error) {
            return [];
        }
    }

    function rebuildDeviceLists() {
        const sinkList = Array.isArray(sinksRaw) ? sinksRaw : [];
        const sourceList = Array.isArray(sourcesRaw) ? sourcesRaw : [];
        const defaultSink = sanitizeText(defaultOutputName, sanitizeText(sink?.name));
        const defaultSource = sanitizeText(defaultInputName, sanitizeText(source?.name));
        let selectedSource = null;

        const outputs = sinkList.map(item => {
            const nodeName = sanitizeText(item?.name);
            if (nodeName === "")
                return null;

            const descriptor = buildDescriptor(item);
            const type = inferOutputTypeForDevice(descriptor);
            const displayName = sanitizeText(item?.description, nodeName);

            return {
                nodeName: nodeName,
                name: displayName,
                subtitle: outputTypeLabel(type),
                icon: outputTypeIcon(type),
                isDefault: nodeName === defaultSink
            };
        }).filter(item => item !== null);

        outputs.sort((a, b) => {
            if (a.isDefault && !b.isDefault)
                return -1;
            if (!a.isDefault && b.isDefault)
                return 1;
            return a.name.localeCompare(b.name);
        });

        const nonMonitorSources = [];
        const monitorSources = [];

        sourceList.forEach(item => {
            const nodeName = sanitizeText(item?.name);
            if (nodeName === "")
                return;
            if (!selectedSource && nodeName === defaultSource)
                selectedSource = item;

            const displayName = sanitizeText(item?.description, nodeName);
            const descriptor = buildDescriptor(item);
            const type = inferInputTypeForDevice(descriptor);
            const device = {
                nodeName: nodeName,
                name: displayName,
                subtitle: inputTypeLabel(type),
                icon: inputTypeIcon(type),
                isDefault: nodeName === defaultSource
            };

            const lowerDescription = displayName.toLowerCase();
            const isMonitor = nodeName.endsWith(".monitor") || lowerDescription.startsWith("monitor of ");

            if (isMonitor)
                monitorSources.push(device);
            else
                nonMonitorSources.push(device);
        });

        const finalInputs = nonMonitorSources.length > 0 ? nonMonitorSources : monitorSources;

        finalInputs.sort((a, b) => {
            if (a.isDefault && !b.isDefault)
                return -1;
            if (!a.isDefault && b.isDefault)
                return 1;
            return a.name.localeCompare(b.name);
        });

        if (!selectedSource) {
            const runtimeSourceName = sanitizeText(source?.name);
            if (runtimeSourceName !== "")
                selectedSource = sourceList.find(item => sanitizeText(item?.name) === runtimeSourceName) ?? null;
        }

        const nextInputPorts = [];
        let nextActiveInputPortName = "";

        if (selectedSource) {
            const rawActivePort = selectedSource?.active_port;
            if (typeof rawActivePort === "string")
                nextActiveInputPortName = sanitizeText(rawActivePort, "");
            else
                nextActiveInputPortName = sanitizeText(rawActivePort?.name, "");

            normalizePorts(selectedSource?.ports).forEach(portItem => {
                const portName = sanitizeText(portItem?.name, "");
                if (portName === "")
                    return;

                const description = sanitizeText(portItem?.description, portName);
                const type = inferInputPortType(portName, description);
                nextInputPorts.push({
                    portName: portName,
                    name: inputPortLabel(type, description),
                    subtitle: description,
                    icon: inputPortIcon(type),
                    isActive: portName === nextActiveInputPortName
                });
            });

            if (nextInputPorts.length > 0 && nextActiveInputPortName === "") {
                nextActiveInputPortName = nextInputPorts[0].portName;
                nextInputPorts[0].isActive = true;
            }

            // Preserve backend port order so the selected pill does not jump position.
        }

        outputDevices = outputs;
        inputDevices = finalInputs;
        inputPorts = nextInputPorts;
        activeInputPortName = nextActiveInputPortName;
    }

    function refreshOutputType() {
        const descriptorType = inferOutputType(outputDescriptor + " " + sinkPropsDescriptor);

        // Active-port hint from pactl/wpctl is preferred, but descriptor wins when it clearly indicates bluetooth.
        if (outputPortHint === "bluetooth" || (outputPortHint === "speaker" && descriptorType === "bluetooth")) {
            outputDeviceType = "bluetooth";
            return;
        }
        if (outputPortHint === "headphones") {
            outputDeviceType = "headphones";
            return;
        }
        if (outputPortHint === "speaker") {
            outputDeviceType = descriptorType === "headphones" ? "headphones" : "speaker";
            return;
        }

        outputDeviceType = descriptorType;
    }

    function refreshDevices() {
        if (!defaultsProc.running)
            defaultsProc.running = true;
        if (!listSinksProc.running)
            listSinksProc.running = true;
        if (!listSourcesProc.running)
            listSourcesProc.running = true;
    }

    function setDefaultOutput(nodeName: string) {
        if (!nodeName || setDefaultOutputProc.running)
            return;
        if (nodeName === defaultOutputName && nodeName !== "")
            return;

        switchingOutputName = nodeName;
        setDefaultOutputProc.command = ["pactl", "set-default-sink", nodeName];
        setDefaultOutputProc.running = true;
    }

    function setDefaultInput(nodeName: string) {
        if (!nodeName || setDefaultInputProc.running)
            return;
        if (nodeName === defaultInputName && nodeName !== "")
            return;

        switchingInputName = nodeName;
        setDefaultInputProc.command = ["pactl", "set-default-source", nodeName];
        setDefaultInputProc.running = true;
    }

    function setInputPort(portName: string) {
        if (!portName || setInputPortProc.running)
            return;

        const sourceName = sanitizeText(defaultInputName, sanitizeText(source?.name, ""));
        if (sourceName === "")
            return;
        if (portName === activeInputPortName)
            return;

        switchingInputPortName = portName;
        setInputPortProc.command = ["pactl", "set-source-port", sourceName, portName];
        setInputPortProc.running = true;
    }

    function schedulePortProbe() {
        if (!sinkReady)
            return;
        sinkProbeTimer.restart();
    }

    readonly property string systemIcon: {
        if (!sinkReady || muted)
            return "";

        if (!volumeKnown)
            return "";

        if (volume <= 0)
            return "";

        if (volume < 0.33)
            return "";

        if (volume < 0.67)
            return "";

        return "";
    }

    function setVolume(newVolume) {
        if (sinkReady && sink.audio) {
            const clamped = Math.max(0, Math.min(1.5, newVolume));
            sink.audio.muted = false;
            sink.audio.volume = clamped;
            lastKnownVolume = clamped;
        }
    }

    function setSourceVolume(newVolume) {
        if (sourceReady && source.audio) {
            const clamped = Math.max(0, Math.min(1.5, newVolume));
            source.audio.muted = false;
            source.audio.volume = clamped;
            lastKnownSourceVolume = clamped;
        }
    }

    function toggleMute() {
        if (sinkReady && sink.audio) {
            sink.audio.muted = !sink.audio.muted;
        }
    }

    function increaseVolume() {
        setVolume(volume + 0.05);
    }

    function decreaseVolume() {
        setVolume(volume - 0.05);
    }

    onSinkChanged: {
        refreshOutputType();
        schedulePortProbe();
        Qt.callLater(rebuildDeviceLists);
    }
    onLiveVolumeChanged: {
        if (!isNaN(liveVolume))
            lastKnownVolume = liveVolume;
    }
    onLiveSourceVolumeChanged: {
        if (!isNaN(liveSourceVolume))
            lastKnownSourceVolume = liveSourceVolume;
    }
    onSourceChanged: Qt.callLater(rebuildDeviceLists)
    onOutputDescriptorChanged: refreshOutputType()
    onSinkPropsDescriptorChanged: refreshOutputType()

    Component.onCompleted: {
        refreshOutputType();
        schedulePortProbe();
        refreshDevices();
    }

    Timer {
        id: sinkProbeTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (!inspectSinkProc.running)
                inspectSinkProc.running = true;
        }
    }

    Timer {
        id: periodicProbeTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: schedulePortProbe()
    }

    Timer {
        id: periodicDeviceRefreshTimer
        interval: 8000
        repeat: true
        running: true
        onTriggered: root.refreshDevices()
    }

    Timer {
        id: deviceRefreshDebounceTimer
        interval: 180
        repeat: false
        onTriggered: root.refreshDevices()
    }

    Timer {
        id: subscribeRestartTimer
        interval: 800
        repeat: false
        onTriggered: {
            if (!sinkEventsProc.running)
                sinkEventsProc.running = true;
        }
    }

    Process {
        id: defaultsProc
        command: ["/bin/sh", "-c", "printf 'sink=%s\\nsource=%s\\n' \"$(pactl get-default-sink 2>/dev/null || true)\" \"$(pactl get-default-source 2>/dev/null || true)\""]

        stdout: StdioCollector {
            onStreamFinished: {
                const sinkMatch = text.match(/^sink=(.*)$/m);
                const sourceMatch = text.match(/^source=(.*)$/m);
                root.defaultOutputName = root.sanitizeText(sinkMatch ? sinkMatch[1] : "");
                root.defaultInputName = root.sanitizeText(sourceMatch ? sourceMatch[1] : "");
            }
        }

        onExited: _exitCode => root.rebuildDeviceLists()
    }

    Process {
        id: listSinksProc
        command: ["pactl", "-f", "json", "list", "sinks"]

        stdout: StdioCollector {
            onStreamFinished: root.sinksRaw = root.parseJsonArray(text)
        }

        onExited: _exitCode => {
            root.rebuildDeviceLists();
            root.refreshOutputType();
        }
    }

    Process {
        id: listSourcesProc
        command: ["pactl", "-f", "json", "list", "sources"]

        stdout: StdioCollector {
            onStreamFinished: root.sourcesRaw = root.parseJsonArray(text)
        }

        onExited: _exitCode => root.rebuildDeviceLists()
    }

    Process {
        id: setDefaultOutputProc

        stderr: SplitParser {
            onRead: data => console.error("[AudioService] " + data)
        }

        onExited: code => {
            const targetNode = root.switchingOutputName;
            root.switchingOutputName = "";
            if (code !== 0)
                return;
            root.defaultOutputName = targetNode;
            root.refreshDevices();
            root.schedulePortProbe();
        }
    }

    Process {
        id: setDefaultInputProc

        stderr: SplitParser {
            onRead: data => console.error("[AudioService] " + data)
        }

        onExited: code => {
            const targetNode = root.switchingInputName;
            root.switchingInputName = "";
            if (code !== 0)
                return;
            root.defaultInputName = targetNode;
            root.refreshDevices();
        }
    }

    Process {
        id: setInputPortProc

        stderr: SplitParser {
            onRead: data => console.error("[AudioService] " + data)
        }

        onExited: code => {
            const targetPort = root.switchingInputPortName;
            root.switchingInputPortName = "";
            if (code !== 0)
                return;
            root.activeInputPortName = targetPort;
            root.refreshDevices();
        }
    }

    Process {
        id: inspectSinkProc
        command: ["/bin/sh", "-c",
            "default_sink=$(pactl get-default-sink 2>/dev/null || true); " +
            "if [ -n \"$default_sink\" ]; then " +
            "  pactl list sinks 2>/dev/null | awk -v ds=\"$default_sink\" '" +
            "    /^Sink #[0-9]+/ {in_sink=1; next} " +
            "    in_sink && /^[[:space:]]*Name:[[:space:]]*/ {name=$0; sub(/^[^:]*:[[:space:]]*/, \"\", name); target=(name==ds); next} " +
            "    in_sink && target && /^[[:space:]]*Active Port:[[:space:]]*/ {port=$0; sub(/^[^:]*:[[:space:]]*/, \"\", port); print \"active_port=\" port; exit} " +
            "  '; " +
            "fi; " +
            "wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null || true"
        ]
        property string buffer: ""

        onStarted: buffer = ""

        stdout: SplitParser {
            onRead: data => inspectSinkProc.buffer += data + "\n"
        }

        onExited: _exitCode => {
            const text = inspectSinkProc.buffer.toLowerCase();
            const taggedActivePortMatch = text.match(/active_port=([^\n]+)/);
            const wpctlActivePortMatch = text.match(/active port[^:\n]*:\s*([^\n]+)/);
            const pactlActivePortMatch = text.match(/^\s*active port:\s*([^\n]+)$/m);
            const activePort = (
                taggedActivePortMatch ? taggedActivePortMatch[1] :
                (pactlActivePortMatch ? pactlActivePortMatch[1] :
                 (wpctlActivePortMatch ? wpctlActivePortMatch[1] : ""))
            ).trim();

            const hasHeadphones = activePort.includes("headphone") || activePort.includes("headset") || activePort.includes("earbud") || activePort.includes("analog-output-headphones");
            const hasBluetooth = activePort.includes("bluetooth") || activePort.includes("bluez") || activePort.includes("a2dp") || root.hasBluetoothTransport(text) || root.hasBluetoothTransport(root.defaultOutputName);
            const hasSpeaker = activePort.includes("speaker") || activePort.includes("speakers") || activePort.includes("line out") || activePort.includes("lineout") || activePort.includes("analog-output-speaker") || activePort.includes("hdmi") || activePort.includes("displayport") || activePort.includes("spdif") || activePort.includes("iec958");

            if (hasHeadphones) {
                root.outputPortHint = "headphones";
            } else if (hasBluetooth) {
                root.outputPortHint = "bluetooth";
            } else if (hasSpeaker) {
                root.outputPortHint = "speaker";
            } else {
                root.outputPortHint = (text.includes("analog-stereo") || text.includes("built-in audio analog stereo")) ? "speaker" : "";
            }
            root.refreshOutputType();
        }
    }

    Process {
        id: sinkEventsProc
        command: ["/bin/sh", "-c", "pactl subscribe 2>/dev/null"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const event = (data + "").toLowerCase();
                if (event.includes("on sink") || event.includes("on source") || event.includes("on server") || event.includes("on card")) {
                    root.schedulePortProbe();
                    deviceRefreshDebounceTimer.restart();
                }
            }
        }

        onExited: _exitCode => subscribeRestartTimer.restart()
    }
}
