pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var mainBattery: UPower.displayDevice
    readonly property bool hasBattery: (mainBattery && mainBattery.isLaptopBattery && (mainBattery.isPresent ?? true)) === true

    // Percentage (0 to 100)
    readonly property int percentage: hasBattery ? Math.round(Math.max(0, Math.min(100, mainBattery.percentage * 100))) : 0

    // State (Charging, Discharging, Full...)
    readonly property int state: mainBattery ? mainBattery.state : UPowerDeviceState.Unknown

    readonly property bool isCharging: state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge
    readonly property bool isDischarging: state === UPowerDeviceState.Discharging || state === UPowerDeviceState.PendingDischarge
    readonly property bool isFull: state === UPowerDeviceState.FullyCharged
    readonly property bool isPlugged: UPower.onBattery === false
    readonly property bool isLow: hasBattery && percentage < 20 && !isCharging

    readonly property real chargeRateW: hasBattery ? Math.abs(mainBattery.changeRate) : 0
    readonly property int timeToFullSeconds: hasBattery ? Math.round(mainBattery.timeToFull) : 0
    readonly property int timeToEmptySeconds: hasBattery ? Math.round(mainBattery.timeToEmpty) : 0

    readonly property string statusText: {
        if (!hasBattery)
            return isPlugged ? "AC Power" : "No battery";
        if (isCharging)
            return "Charging";
        if (isFull)
            return "Fully charged";
        if (isPlugged)
            return "Plugged in";
        if (isDischarging)
            return "Discharging";
        return UPowerDeviceState.toString(state);
    }

    function formatDuration(totalSeconds) {
        const sec = Math.max(0, Math.round(totalSeconds));
        if (sec <= 0)
            return "--";
        const hours = Math.floor(sec / 3600);
        const minutes = Math.floor((sec % 3600) / 60);
        if (hours > 0)
            return hours + "h " + minutes + "m";
        return minutes + "m";
    }

    // Icon logic here.
    function getBatteryIcon() {
        if (!hasBattery)
            return isPlugged ? "" : "󱉝";
        if (isCharging)
            return "󰂄";
        if (isPlugged && !isDischarging)
            return "";

        const p = percentage;
        if (p >= 90)
            return "󰁹";
        if (p >= 60)
            return "󰂀";
        if (p >= 40)
            return "󰁾";
        if (p >= 10)
            return "󰁼";
        return "󰁺";
    }
}
