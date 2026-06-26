pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var mainBattery: UPower.displayDevice
    readonly property bool hasBattery: (mainBattery && mainBattery.isLaptopBattery && (mainBattery.isPresent ?? true)) === true
    readonly property int historyWindowMinutes: Math.max(1, Math.round((internal.maxHistoryPoints * internal.sampleIntervalMs) / 60000))

    // Percentage (0 to 100)
    readonly property int percentage: hasBattery ? Math.round(Math.max(0, Math.min(100, mainBattery.percentage * 100))) : 0

    // State (Charging, Discharging, Full...)
    readonly property int state: mainBattery ? mainBattery.state : UPowerDeviceState.Unknown

    readonly property bool isCharging: state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge
    readonly property bool isDischarging: state === UPowerDeviceState.Discharging || state === UPowerDeviceState.PendingDischarge
    readonly property bool isFull: state === UPowerDeviceState.FullyCharged
    readonly property bool isPlugged: UPower.onBattery === false
    readonly property bool isLow: hasBattery && percentage < 20 && !isCharging

    // Quickshell maps UPower's `energy-rate` to `changeRate`.
    readonly property real upowerEnergyRateW: hasBattery ? Math.abs(mainBattery.changeRate) : 0
    readonly property real chargeRateW: upowerEnergyRateW
    readonly property real sysfsBatteryRateW: internal.sysfsBatteryRateW
    readonly property real adapterRateW: internal.adapterRateW
    readonly property real powerRateW: {
        if (isCharging && upowerEnergyRateW > 0.05)
            return upowerEnergyRateW;
        if (isDischarging && upowerEnergyRateW > 0.05)
            return upowerEnergyRateW;
        if (chargeRateW > 0.05)
            return chargeRateW;
        if (sysfsBatteryRateW > 0.05)
            return sysfsBatteryRateW;
        if (adapterRateW > 0.05)
            return adapterRateW;
        return 0;
    }
    readonly property string powerRateLabel: {
        if (isCharging)
            return "Charge Input";
        if (isDischarging)
            return "Battery Draw";
        if (isPlugged && isFull)
            return "System Draw";
        if (isPlugged)
            return "AC Draw";
        return "Power Flow";
    }
    readonly property string powerRateSource: {
        if ((isCharging || isDischarging) && upowerEnergyRateW > 0.05)
            return "UPower energy-rate";
        if (chargeRateW > 0.05)
            return "UPower";
        if (sysfsBatteryRateW > 0.05)
            return "Battery sensor";
        if (adapterRateW > 0.05)
            return "Adapter sensor";
        if (isPlugged)
            return "No active flow reported";
        return "Waiting for sensor data";
    }
    readonly property string powerRateText: {
        if (!hasBattery && !isPlugged)
            return "--";
        return powerRateW.toFixed(1) + " W";
    }
    readonly property int timeToFullSeconds: hasBattery ? Math.round(mainBattery.timeToFull) : 0
    readonly property int timeToEmptySeconds: hasBattery ? Math.round(mainBattery.timeToEmpty) : 0
    readonly property var powerHistory: internal.powerHistory
    readonly property var percentageHistory: internal.percentageHistory
    readonly property real maxObservedPowerW: internal.maxObservedPowerW

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

    function _pushHistoryValue(values, nextValue) {
        const updated = values.slice(0);
        updated.push(nextValue);
        while (updated.length > internal.maxHistoryPoints)
            updated.shift();
        return updated;
    }

    function captureHistorySample() {
        const nextPowerHistory = _pushHistoryValue(internal.powerHistory, powerRateW);
        const nextPercentageHistory = _pushHistoryValue(internal.percentageHistory, percentage);
        internal.powerHistory = nextPowerHistory;
        internal.percentageHistory = nextPercentageHistory;
        internal.maxObservedPowerW = Math.max(20, Math.max.apply(Math, nextPowerHistory));
        historyChanged();
    }

    QtObject {
        id: internal

        property int sampleIntervalMs: 5000
        property int maxHistoryPoints: 48
        property real sysfsBatteryRateW: 0
        property real adapterRateW: 0
        property real maxObservedPowerW: 20
        property var powerHistory: []
        property var percentageHistory: []
    }

    Timer {
        id: sampleTimer
        interval: internal.sampleIntervalMs
        running: true
        repeat: true
        onTriggered: {
            root.captureHistorySample();
        }
    }



    signal historyChanged
}
