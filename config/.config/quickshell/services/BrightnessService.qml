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

    property int maxValue: 0
    property bool hasBacklight: false
    property real pendingBrightness: NaN
    property real targetBrightness: NaN
    readonly property bool available: hasBacklight && maxValue > 0
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
    property real nightLightIntensity: StateService.get("nightLight.intensity", 0.5)

    Component.onCompleted: {
        detectBacklightDevice.running = true;
        ensureHyprsunsetRunning.running = true;
    }

    function updateTemperatureFromIntensity() {
        nightLightTemperature = Math.round(2500 + (nightLightIntensity * 3000));
    }

    function updateIntensityFromTemperature() {
        nightLightIntensity = (nightLightTemperature - 2500) / 3000;
    }

    function readMaxBrightness() {
        maxBrightnessProcess.command = ["/bin/cat", maxBrightnessPath];
        maxBrightnessProcess.running = true;
    }

    function readBrightness() {
        brightnessProcess.command = ["/bin/cat", backlightPath];
        brightnessProcess.running = true;
    }

    function clampBrightness(value) {
        return Math.max(0.05, Math.min(1.0, value));
    }

    function applyBrightnessReading(rawValue) {
        if (isNaN(rawValue))
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
        if (!setBrightnessProcess.running)
            applyBrightnessTimer.restart();
    }

    function applyTargetBrightness() {
        if (!hasTargetBrightness || setBrightnessProcess.running)
            return;

        const rawValue = root.maxValue > 0
            ? Math.round(clampBrightness(targetBrightness) * root.maxValue)
            : Math.round(clampBrightness(targetBrightness) * 100) + "%";
        root.targetBrightness = NaN;
        setBrightnessProcess.command = ["brightnessctl", "set", rawValue.toString()];
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
        disableNightLightProc.running = true;
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
        enableNightLightProc.command = ["hyprctl", "hyprsunset", "temperature", nightLightTemperature.toString()];
        enableNightLightProc.running = true;
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

                root.backlightDevice = device;
                root.hasBacklight = true;
                root.readMaxBrightness();
                root.readBrightness();
                watchBrightnessEvents.running = true;
                updateTimer.start();
            }
        }
    }

    Process {
        id: maxBrightnessProcess
        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim());
                if (!isNaN(value) && value > 0) {
                    root.maxValue = value;
                }
            }
        }
    }

    Process {
        id: brightnessProcess
        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim());
                root.applyBrightnessReading(value);
            }
        }
    }

    Process {
        id: setBrightnessProcess
        stdout: StdioCollector {
        }
        stderr: StdioCollector {
        }
        onExited: {
            if (root.hasTargetBrightness) {
                root.applyTargetBrightness();
            } else {
                brightnessSettleTimer.restart();
            }
        }
    }

    Process {
        id: watchBrightnessEvents
        command: ["/bin/sh", "-c", "command -v inotifywait >/dev/null 2>&1 || exit 0; inotifywait -m -q -e modify " + backlightPath]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() !== "")
                    root.readBrightness();
            }
        }
    }

    Timer {
        id: updateTimer
        interval: watchBrightnessEvents.running ? 2000 : 100
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // Adjust interval dynamically if inotifywait is not available
            if (!watchBrightnessEvents.running && interval !== 100) {
                interval = 100;
            } else if (watchBrightnessEvents.running && interval !== 2000) {
                interval = 2000;
            }
            root.readBrightness();
        }
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
        interval: 16
        onTriggered: root.applyTargetBrightness()
    }

    Process {
        id: ensureHyprsunsetRunning
        command: ["/bin/sh", "-c", "if ! pgrep -x hyprsunset >/dev/null 2>&1; then hyprsunset & disown; sleep 0.5; fi"]
        onExited: {
            if (!StateService.isLoading && root.nightLightEnabled)
                root.applyNightLight();
        }
    }

    Process {
        id: enableNightLightProc
    }

    Process {
        id: disableNightLightProc
        command: ["hyprctl", "hyprsunset", "identity"]
    }
}
