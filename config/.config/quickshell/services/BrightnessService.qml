pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real brightness: 0.5

    property string backlightDevice: "amdgpu_bl1"
    readonly property string backlightPath: "/sys/class/backlight/" + backlightDevice + "/brightness"
    readonly property string maxBrightnessPath: "/sys/class/backlight/" + backlightDevice + "/max_brightness"

    property string lastWrittenRaw: ""
    property bool brightnessKnown: false
    property int maxValue: 0
    property bool hasBacklight: false
    property real pendingBrightness: NaN
    property real targetBrightness: NaN
    readonly property bool available: hasBacklight && maxValue > 0
    onAvailableChanged: {
        if (available && hasTargetBrightness)
            scheduleBrightnessApply();
    }

    readonly property bool hasPendingBrightness: !isNaN(pendingBrightness)
    readonly property bool hasTargetBrightness: !isNaN(targetBrightness)

    readonly property string icon: {
        if (brightness <= 0.1)
            return "󰃞";
        if (brightness <= 0.3)
            return "󰃟";
        if (brightness <= 0.6)
            return "󰃝";
        return "󰃠";
    }

    property real lastBrightness: 0.5

    property bool nightLightEnabled: StateService.get("nightLight.enabled", false)
    property int nightLightTemperature: 4000
    property bool nightLightDaemonRequested: false
    property real nightLightIntensity: StateService.get("nightLight.intensity", 0.5)

    Component.onCompleted: {
        updateTemperatureFromIntensity();
        detectBacklightDevice.running = true;
        // State now loads synchronously, so its initial signal may precede us.
        if (!StateService.isLoading)
            applyStateTimer.restart();
    }

    function updateTemperatureFromIntensity() {
        nightLightTemperature = Math.round(2500 + (nightLightIntensity * 3000));
    }

    function updateIntensityFromTemperature() {
        nightLightIntensity = (nightLightTemperature - 2500) / 3000;
    }

    function readMaxBrightness() {
        maxBrightnessFile.reload();
    }

    function readBrightness() {
        brightnessFile.reload();
    }

    function clampBrightness(value) {
        return Math.max(0.05, Math.min(1.0, value));
    }

    function applyBrightnessReading(rawValue) {
        if (isNaN(rawValue) || root.maxValue <= 0)
            return;

        const nextBrightness = clampBrightness(root.maxValue > 0 ? rawValue / root.maxValue : root.brightness);

        if (hasPendingBrightness) {
            if (Math.abs(nextBrightness - pendingBrightness) <= 0.01) {
                pendingBrightness = NaN;
                brightnessSettleTimer.stop();
            } else if (brightnessSettleTimer.running) {
                return;
            } else {
                pendingBrightness = NaN;
            }
        }

        root.brightness = nextBrightness;
        root.brightnessKnown = true;
    }

    function setBrightness(value) {
        const newValue = clampBrightness(value);

        root.pendingBrightness = newValue;
        root.targetBrightness = newValue;
        root.brightness = newValue;
        brightnessSettleTimer.restart();
        scheduleBrightnessApply();
    }

    function scheduleBrightnessApply() {
        if (!setBrightnessProcess.running && !applyBrightnessTimer.running)
            applyBrightnessTimer.start();
    }

    function applyTargetBrightness() {
        if (!available || !hasTargetBrightness || setBrightnessProcess.running)
            return;

        const rawValue = root.maxValue > 0
            ? Math.round(clampBrightness(targetBrightness) * root.maxValue)
            : Math.round(clampBrightness(targetBrightness) * 100) + "%";
        root.targetBrightness = NaN;
        if (rawValue.toString() === lastWrittenRaw)
            return;
        lastWrittenRaw = rawValue.toString();
        setBrightnessProcess.command = ["brightnessctl", "--class", "backlight", "--device", root.backlightDevice, "set", rawValue.toString()];
        setBrightnessProcess.running = true;
    }

    function toggleBrightness() {
        if (brightness > 0.1) {
            lastBrightness = brightness;
            setBrightness(0.05);
        } else {
            setBrightness(lastBrightness);
        }
    }

    function enableNightLight() {
        nightLightEnabled = true;
        StateService.set("nightLight.enabled", true);
        applyNightLight();
    }

    function disableNightLight() {
        nightLightEnabled = false;
        StateService.set("nightLight.enabled", false);
        nightLightDebounce.stop();
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
            Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"]);
    }

    function setNightLightIntensity(intensity) {
        nightLightIntensity = Math.max(0.0, Math.min(1.0, intensity));
        updateTemperatureFromIntensity();
        StateService.set("nightLight.intensity", nightLightIntensity);

        if (nightLightEnabled)
            applyNightLight();
    }

    function setNightLightTemperature(temp) {
        nightLightTemperature = Math.max(2500, Math.min(5500, temp));
        updateIntensityFromTemperature();
        StateService.set("nightLight.intensity", nightLightIntensity);

        if (nightLightEnabled)
            applyNightLight();
    }

    function applyNightLight() {
        if (!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
            return;
        if (nightLightDaemonRequested)
            nightLightDebounce.restart();
        else if (!ensureHyprsunsetRunning.running)
            ensureHyprsunsetRunning.running = true;
    }

    Timer {
        id: nightLightDebounce
        interval: 100
        onTriggered: {
            if (root.nightLightEnabled)
                Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", root.nightLightTemperature.toString()]);
        }
    }

    Connections {
        target: StateService

        function onStateLoaded() {
            root.nightLightEnabled = StateService.get("nightLight.enabled", false);
            root.nightLightIntensity = StateService.get("nightLight.intensity", 0.5);
            root.updateTemperatureFromIntensity();
            applyStateTimer.restart();
        }
    }

    Timer {
        id: applyStateTimer
        interval: 1000
        onTriggered: {
            if (root.nightLightEnabled) {
                root.applyNightLight();
                return;
            }
            root.disableNightLight();
        }
    }

    Process {
        id: detectBacklightDevice
        command: ["/bin/sh", "-c", "if [ -d /sys/class/backlight/amdgpu_bl1 ]; then echo amdgpu_bl1; else ls /sys/class/backlight/ 2>/dev/null | head -1; fi"]
        stdout: SplitParser {
            onRead: data => {
                const device = data.trim();
                if (device === "")
                    return;

                if (root.backlightDevice !== device) {
                    root.brightnessKnown = false;
                    root.maxValue = 0;
                }
                root.backlightDevice = device;
                root.hasBacklight = true;
                root.readMaxBrightness();
                root.readBrightness();
            }
        }
    }

    FileView {
        id: maxBrightnessFile
        path: root.maxBrightnessPath
        printErrors: false
        onLoaded: {
            const value = parseInt(text().trim());
            if (!isNaN(value) && value > 0) {
                root.maxValue = value;
                root.hasBacklight = true;
                brightnessFile.reload();
            }
        }
    }

    FileView {
        id: brightnessFile
        path: root.backlightPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const value = parseInt(text().trim());
            // A subsequent external change must allow writing a previous target again.
            if (!isNaN(value) && !root.hasPendingBrightness && !setBrightnessProcess.running)
                root.lastWrittenRaw = value.toString();
            root.applyBrightnessReading(value);
        }
    }

    Process {
        id: setBrightnessProcess
        stdout: StdioCollector {
        }
        stderr: StdioCollector { id: setBrightnessError }
        onExited: code => {
            if (code !== 0) {
                root.lastWrittenRaw = "";
                console.warn("[BrightnessService]", setBrightnessError.text.trim());
            }
            if (root.hasTargetBrightness) {
                applyBrightnessTimer.restart();
            } else {
                brightnessSettleTimer.restart();
            }
        }
    }

    // Some sysfs changes do not emit inotify events.
    Timer {
        interval: 10000
        repeat: true
        running: root.available
        onTriggered: brightnessFile.reload()
    }

    Timer {
        id: brightnessSettleTimer
        interval: 160
        onTriggered: {
            root.pendingBrightness = NaN;
            root.readBrightness();
        }
    }

    Timer {
        id: applyBrightnessTimer
        interval: 40
        onTriggered: root.applyTargetBrightness()
    }

    Process {
        id: ensureHyprsunsetRunning
        command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null || systemctl --user start hyprsunset.service"]
        onExited: code => {
            if (code !== 0 && root.nightLightEnabled)
                Quickshell.execDetached(["hyprsunset"]);
            root.nightLightDaemonRequested = code === 0 || root.nightLightEnabled;
            if (root.nightLightEnabled)
                nightLightDebounce.restart();
        }
    }
}
