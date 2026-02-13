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
    readonly property real volume: {
        if (!sinkReady)
            return 0;
        const vol = sink.audio.volume;
        if (vol === undefined || vol === null || isNaN(vol))
            return 0;
        return Math.max(0, Math.min(1.5, vol));
    }
    readonly property real volumeForOsd: volume
    readonly property int percentage: Math.round(volume * 100)

    readonly property bool sourceMuted: sourceReady ? (source.audio.muted ?? false) : false
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

    function refreshOutputType() {
        // Active-port hint from pactl/wpctl is authoritative when available.
        if (outputPortHint === "headphones" || outputPortHint === "bluetooth" || outputPortHint === "speaker") {
            outputDeviceType = outputPortHint;
            return;
        }
        outputDeviceType = inferOutputType(outputDescriptor + " " + sinkPropsDescriptor);
    }

    function schedulePortProbe() {
        if (!sinkReady)
            return;
        sinkProbeTimer.restart();
    }

    readonly property string systemIcon: {
        if (!sinkReady || muted || volume <= 0)
            return "";

        if (volume < 0.33)
            return "";

        if (volume < 0.67)
            return "";

        return "";
    }

    function setVolume(newVolume) {
        if (sinkReady && sink.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1.5, newVolume));
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
    }
    onOutputDescriptorChanged: refreshOutputType()
    onSinkPropsDescriptorChanged: refreshOutputType()

    Component.onCompleted: {
        refreshOutputType();
        schedulePortProbe();
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
        id: subscribeRestartTimer
        interval: 800
        repeat: false
        onTriggered: {
            if (!sinkEventsProc.running)
                sinkEventsProc.running = true;
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
            const hasBluetooth = activePort.includes("bluetooth") || activePort.includes("bluez") || activePort.includes("a2dp");
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
                if (event.includes("on sink") || event.includes("on server") || event.includes("on card"))
                    root.schedulePortProbe();
            }
        }

        onExited: _exitCode => subscribeRestartTimer.restart()
    }
}
