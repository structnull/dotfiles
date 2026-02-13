pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real brightness: 0.5
    property real maxBrightness: 1.0
    readonly property real level: brightness
    readonly property int percentage: Math.round(brightness * 100)

    property string backlightDevice: "amdgpu_bl1"
    readonly property string backlightPath: "/sys/class/backlight/" + backlightDevice + "/brightness"
    readonly property string maxBrightnessPath: "/sys/class/backlight/" + backlightDevice + "/max_brightness"

    property int currentValue: 0
    property int maxValue: 0
    property bool hasBacklight: false
    readonly property bool available: hasBacklight && maxValue > 0

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
    readonly property string nightLightIcon: nightLightEnabled ? "󰌵" : "󰌶"

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

    function setBrightness(value) {
        const newValue = Math.max(0.05, Math.min(1.0, value));
        const percent = Math.round(newValue * 100);

        root.brightness = newValue;
        setBrightnessProcess.command = ["/bin/sh", "-c", "brightnessctl set " + percent + "% >/dev/null 2>&1 && cat " + backlightPath];
        setBrightnessProcess.running = true;
    }

    function increaseBrightness() {
        setBrightness(brightness + 0.05);
    }

    function decreaseBrightness() {
        setBrightness(brightness - 0.05);
    }

    function toggleBrightness() {
        if (brightness > 0.1) {
            lastBrightness = brightness;
            setBrightness(0.05);
        } else {
            setBrightness(lastBrightness);
        }
    }

    function toggleNightLight() {
        if (nightLightEnabled) {
            disableNightLight();
        } else {
            enableNightLight();
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
                    root.maxBrightness = value;
                }
            }
        }
    }

    Process {
        id: brightnessProcess
        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim());
                if (!isNaN(value)) {
                    root.currentValue = value;
                    root.brightness = root.maxValue > 0 ? value / root.maxValue : 0;
                }
            }
        }
    }

    Process {
        id: setBrightnessProcess
        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim());
                if (!isNaN(value)) {
                    root.currentValue = value;
                    root.brightness = root.maxValue > 0 ? value / root.maxValue : root.brightness;
                }
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
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.readBrightness()
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
