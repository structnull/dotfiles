pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: root.audioPageConsumers > 0
            ? Pipewire.nodes.values.filter(node => node && !node.isStream && node.audio)
            : [root.sink, root.source].filter(node => node)
    }

    Instantiator {
        active: root.audioPageConsumers > 0
        model: ScriptModel {
            comparisonMode: ObjectComparison.Identity
            values: Pipewire.nodes.values.filter(node => node && !node.isStream && node.audio)
        }
        delegate: Connections {
            required property PwNode modelData
            target: modelData
            function onPropertiesChanged() { Qt.callLater(root.rebuildDeviceLists); }
            function onReadyChanged() { Qt.callLater(root.rebuildDeviceLists); }
        }
        onObjectAdded: Qt.callLater(root.rebuildDeviceLists)
        onObjectRemoved: Qt.callLater(root.rebuildDeviceLists)
    }

    readonly property bool sinkReady: sink?.ready === true && sink.audio !== null
    readonly property bool sourceReady: source?.ready === true && source.audio !== null

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
        return parts.join(" ").trim();
    }
    property string outputDeviceType: "speaker"

    property int audioPageConsumers: 0
    onAudioPageConsumersChanged: {
        if (audioPageConsumers === 0) {
            outputDevices = [];
            inputDevices = [];
        }
    }
    property var outputDevices: []
    property var inputDevices: []
    property string switchingOutputName: ""
    property string switchingInputName: ""

    // Default names are now derived reactively from native Pipewire bindings.
    readonly property string defaultOutputName: sanitizeText(sink?.name)
    readonly property string defaultInputName: sanitizeText(source?.name)

    readonly property bool refreshingDevices: false
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
            return "speaker";

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
            return "speaker";

        // A new generic analog/ALSA sink is the normal fallback after an audio
        // device disconnects. Do not retain the old type here: doing so leaves a
        // Bluetooth icon visible after its BlueZ sink has gone away.
        if (text.includes("analog") || text.includes("alsa_output"))
            return "speaker";

        // Unknown sink metadata should never inherit a disconnected device's icon.
        return "speaker";
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

    function sanitizeText(value, fallback): string {
        const fallbackText = ((fallback ?? "") + "").trim();
        const text = ((value ?? "") + "").trim();
        if (text !== "")
            return text;
        return fallbackText;
    }

    // Build a descriptor string from a native PwNode for type inference.
    function buildNodeDescriptor(node): string {
        if (!node)
            return "";
        const props = node.properties ?? ({});
        return [
            sanitizeText(node.description),
            sanitizeText(node.name),
            sanitizeText(node.nickname),
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

    // Collect all non-stream audio nodes from native Pipewire.nodes.
    function collectNativeNodes() {
        const sinks = [];
        const sources = [];
        const allNodes = Pipewire.nodes.values ?? [];
        for (let i = 0; i < allNodes.length; i++) {
            const node = allNodes[i];
            if (!node || node.isStream)
                continue;
            if (!node.audio)
                continue;
            if (node.isSink)
                sinks.push(node);
            else
                sources.push(node);
        }
        return { sinks: sinks, sources: sources };
    }

    function rebuildDeviceLists() {
        if (audioPageConsumers <= 0)
            return;
        const collected = collectNativeNodes();
        const sinkNodes = collected.sinks;
        const sourceNodes = collected.sources;
        const defaultSink = defaultOutputName;
        const defaultSource = defaultInputName;

        const outputs = sinkNodes.map(node => {
            const nodeName = sanitizeText(node.name);
            if (nodeName === "")
                return null;

            const descriptor = buildNodeDescriptor(node);
            const type = inferOutputTypeForDevice(descriptor);
            const displayName = sanitizeText(node.description, nodeName);

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

        sourceNodes.forEach(node => {
            const nodeName = sanitizeText(node.name);
            if (nodeName === "")
                return;

            const displayName = sanitizeText(node.description, nodeName);
            const descriptor = buildNodeDescriptor(node);
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

        if (JSON.stringify(outputDevices) !== JSON.stringify(outputs))
            outputDevices = outputs;
        if (JSON.stringify(inputDevices) !== JSON.stringify(finalInputs))
            inputDevices = finalInputs;
    }

    function refreshOutputType() {
        if (!sinkReady) {
            outputPortHint = "";
            outputDeviceType = "speaker";
            return;
        }

        const fullDescriptor = outputDescriptor + " " + sinkPropsDescriptor + " " + defaultOutputName;
        const descriptorType = inferOutputType(fullDescriptor);

        // Use outputPortHint from native property inspection when available.
        if (outputPortHint === "bluetooth") {
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

    // Refresh the output port hint from native PwNode properties instead of shelling out.
    function refreshPortHintFromProperties() {
        if (!sinkReady) {
            outputPortHint = "";
            outputDeviceType = "speaker";
            return;
        }

        // Gather all hints from node properties and descriptor.
        const props = sink.properties ?? ({});
        const descriptor = [
            sanitizeText(sink.description),
            sanitizeText(sink.name),
            sanitizeText(sink.nickname),
            sanitizeText(props["device.form_factor"]),
            sanitizeText(props["device.icon_name"]),
            sanitizeText(props["device.icon-name"]),
            sanitizeText(props["node.nick"]),
            sanitizeText(props["node.description"]),
            sanitizeText(props["api.alsa.path"]),
            sanitizeText(props["card.profile.name"]),
            sanitizeText(props["device.profile.name"])
        ].join(" ").toLowerCase();

        const hasBluetooth = descriptor.includes("bluez") || descriptor.includes("bluetooth") || descriptor.includes("a2dp") || descriptor.includes("api.bluez5") || descriptor.includes("bluez_output.");
        const hasHeadphones = descriptor.includes("headphone") || descriptor.includes("headset") || descriptor.includes("earbud") || descriptor.includes("analog-output-headphones");
        const hasSpeaker = descriptor.includes("speaker") || descriptor.includes("hdmi") || descriptor.includes("displayport") || descriptor.includes("spdif") || descriptor.includes("iec958") || descriptor.includes("analog-output-speaker") || descriptor.includes("line out") || descriptor.includes("lineout");

        if (hasHeadphones) {
            outputPortHint = "headphones";
        } else if (hasBluetooth) {
            outputPortHint = "bluetooth";
        } else if (hasSpeaker) {
            outputPortHint = "speaker";
        } else {
            outputPortHint = (descriptor.includes("analog-stereo") || descriptor.includes("built-in audio analog stereo")) ? "speaker" : "";
        }
        refreshOutputType();
    }

    function refreshDevices() {
        Qt.callLater(rebuildDeviceLists);
    }

    function setDefaultOutput(nodeName: string) {
        if (!nodeName)
            return;
        if (nodeName === defaultOutputName && nodeName !== "")
            return;

        switchingOutputName = nodeName;

        // Find the PwNode by name and set it as the preferred default sink.
        const allNodes = Pipewire.nodes.values ?? [];
        for (let i = 0; i < allNodes.length; i++) {
            const node = allNodes[i];
            if (node && node.name === nodeName && !node.isStream && node.audio && node.isSink) {
                Pipewire.preferredDefaultAudioSink = node;
                switchingOutputName = "";
                Qt.callLater(rebuildDeviceLists);
                Qt.callLater(refreshPortHintFromProperties);
                return;
            }
        }
        // Node not found — clear switching state.
        switchingOutputName = "";
    }

    function setDefaultInput(nodeName: string) {
        if (!nodeName)
            return;
        if (nodeName === defaultInputName && nodeName !== "")
            return;

        switchingInputName = nodeName;

        // Find the PwNode by name and set it as the preferred default source.
        const allNodes = Pipewire.nodes.values ?? [];
        for (let i = 0; i < allNodes.length; i++) {
            const node = allNodes[i];
            if (node && node.name === nodeName && !node.isStream && node.audio && !node.isSink) {
                Pipewire.preferredDefaultAudioSource = node;
                switchingInputName = "";
                Qt.callLater(rebuildDeviceLists);
                return;
            }
        }
        // Node not found — clear switching state.
        switchingInputName = "";
    }

    readonly property string systemIcon: {
        if (!sinkReady || muted)
            return "󰖁";

        if (!volumeKnown)
            return "󰖁";

        if (volume <= 0.001)
            return "󰖁";

        if (volume < 0.33)
            return "󰕿";

        if (volume < 0.67)
            return "󰖀";

        return "󰕾";
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

    onSinkChanged: {
        refreshOutputType();
        refreshPortHintFromProperties();
        Qt.callLater(rebuildDeviceLists);
    }
    onSinkReadyChanged: {
        refreshOutputType();
        refreshPortHintFromProperties();
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
    onSinkPropsDescriptorChanged: {
        refreshOutputType();
        refreshPortHintFromProperties();
    }

    Component.onCompleted: {
        refreshOutputType();
        refreshPortHintFromProperties();
        rebuildDeviceLists();
    }

    // Single slow timer for periodic output type refresh.
    // Native Pipewire bindings are reactive for most changes, but some property
    // updates (e.g. port changes on certain hardware) may not emit signals
    // through the PwNode binding layer. This timer catches those edge cases.
    Timer {
        id: outputTypeRefreshTimer
        interval: 30000
        repeat: true
        running: root.audioPageConsumers > 0
        onTriggered: {
            root.refreshPortHintFromProperties();
            root.rebuildDeviceLists();
        }
    }
}
