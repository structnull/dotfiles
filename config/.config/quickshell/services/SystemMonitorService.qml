pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    // ========================================================================
    // CPU PROPERTIES
    // ========================================================================

    readonly property int cpuUsage: internal.cpuUsage
    readonly property int cpuTemp: internal.cpuTemp
    property bool active: false
    property int visibleWindows: 0

    function acquireWindow() {
        visibleWindows++;
        if (visibleWindows === 1)
            active = true;
    }

    function releaseWindow() {
        visibleWindows = Math.max(0, visibleWindows - 1);
        if (visibleWindows === 0)
            active = false;
    }

    // ========================================================================
    // GPU PROPERTIES
    // ========================================================================

    readonly property int gpuUsage: internal.gpuUsage
    readonly property int gpuTemp: internal.gpuTemp
    readonly property bool gpuUsageKnown: internal.gpuUsageKnown
    readonly property bool gpuTempKnown: internal.gpuTempKnown
    readonly property string gpuType: internal.gpuType // "nvidia", "amd", "intel", "unknown"
    property bool gpuMonitorEnabled: StateService.get("gpuMonitor.enabled", false)

    Connections {
        target: StateService
        function onStateLoaded() {
            root.gpuMonitorEnabled = StateService.get("gpuMonitor.enabled", false);
        }
    }

    function toggleGpuMonitor() {
        gpuMonitorEnabled = !gpuMonitorEnabled;
        StateService.set("gpuMonitor.enabled", gpuMonitorEnabled);
    }

    onGpuMonitorEnabledChanged: {
        internal.gpuUsageKnown = false;
        internal.gpuTempKnown = false;
        if (!gpuMonitorEnabled) {
            internal.gpuUsage = 0;
            internal.gpuTemp = 0;
        } else if (internal.gpuType !== "unknown") {
            _triggerGpuUpdate();
        }
    }

    function _triggerGpuUpdate() {
        if (!active)
            return;
        if (internal.gpuType === "nvidia" && internal.nvidiaId && !updateNvidiaGpu.running) {
            updateNvidiaGpu.running = true;
        } else if (internal.gpuType === "amd") {
            gpuUsageFile.reload();
            gpuTempFile.reload();
        } else if (internal.gpuType === "intel") {
            gpuTempFile.reload();
        }
    }

    // ========================================================================
    // RAM PROPERTIES
    // ========================================================================

    readonly property int ramUsage: internal.ramUsage
    readonly property string ramUsed: internal.ramUsed   // GiB, e.g. "5.2"
    readonly property string ramTotal: internal.ramTotal  // GiB, e.g. "15.8"

    // ========================================================================
    // DISK PROPERTIES
    // ========================================================================

    readonly property int diskUsage: internal.diskUsage
    readonly property string diskUsed: internal.diskUsed   // GiB
    readonly property string diskTotal: internal.diskTotal  // GiB

    // ========================================================================
    // NETWORK PROPERTIES
    // ========================================================================

    readonly property string networkDown: internal.networkDown // e.g. "1.2 MB/s"
    readonly property string networkUp: internal.networkUp     // e.g. "340 KB/s"

    // ========================================================================
    // UPTIME
    // ========================================================================

    readonly property string uptime: internal.uptime // e.g. "2d 5h" or "3h 12m"

    // ========================================================================
    // INTERNAL STATE
    // ========================================================================

    QtObject {
        id: internal

        // CPU
        property int cpuUsage: 0
        property int cpuTemp: 0

        // GPU
        property int gpuUsage: 0
        property int gpuTemp: 0
        property bool gpuUsageKnown: false
        property bool gpuTempKnown: false
        property string nvidiaId: ""
        property string gpuType: "unknown"

        // CPU calculation state
        property real prevTotal: 0
        property real prevIdle: 0

        // RAM
        property int ramUsage: 0
        property string ramUsed: "0"
        property string ramTotal: "0"

        // Disk
        property int diskUsage: 0
        property string diskUsed: "0"
        property string diskTotal: "0"

        // Network
        property string networkDown: "0 B/s"
        property string networkUp: "0 B/s"
        property var previousInterfaces: new Map()
        property double prevNetworkSampleMs: 0

        // Uptime
        property string uptime: "0m"
    }

    // ========================================================================
    // INITIALIZATION
    // ========================================================================

    property string cpuTempPath: ""
    property string gpuUsagePath: ""
    property string gpuTempPath: ""

    Component.onCompleted: detectSensors.running = true

    onActiveChanged: {
        internal.prevNetworkSampleMs = 0;
        internal.previousInterfaces = new Map();
        internal.prevTotal = 0;
        internal.prevIdle = 0;
        if (active)
            triggerFullUpdate();
    }

    function triggerFullUpdate() {
        _readCpuStats();
        _readCoreStats();
        updateDisk.running = true;
        if (gpuMonitorEnabled)
            _triggerGpuUpdate();
    }

    // ========================================================================
    // UPDATE TIMER
    // ========================================================================

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        onTriggered: root._readCpuStats()
    }

    Timer {
        interval: 4000
        running: root.active
        repeat: true
        onTriggered: {
            root._readCoreStats();

            if (root.gpuMonitorEnabled) {
                root._triggerGpuUpdate();
            }
        }
    }

    // Disk updates less frequently
    Timer {
        interval: 60000
        running: root.active
        repeat: true
        onTriggered: updateDisk.running = true
    }

    // ========================================================================
    // HELPER FUNCTIONS
    // ========================================================================

    function _formatBytes(bytes) {
        if (bytes >= 1073741824) {
            return (bytes / 1073741824).toFixed(1) + " GB/s";
        } else if (bytes >= 1048576) {
            return (bytes / 1048576).toFixed(1) + " MB/s";
        } else if (bytes >= 1024) {
            return (bytes / 1024).toFixed(0) + " KB/s";
        }
        return bytes.toFixed(0) + " B/s";
    }

    function _formatGiB(bytes) {
        return (bytes / 1073741824).toFixed(1);
    }

    // ========================================================================
    // GPU DETECTION
    // ========================================================================

    // Discover sensor paths once; all recurring reads below stay in-process.
    Process {
        id: detectSensors
        command: ["bash", "-c", `
            cpu_temp=""
            for zone in /sys/class/thermal/thermal_zone*/temp; do
                [ -f "$zone" ] || continue
                IFS= read -r type < "\${zone%/temp}/type"
                case "$type" in
                    *cpu*|*x86_pkg*|*coretemp*) [ -n "$cpu_temp" ] || cpu_temp="$zone" ;;
                esac
            done
            if [ -z "$cpu_temp" ]; then
                for hwmon in /sys/class/hwmon/hwmon*; do
                    [ -f "$hwmon/name" ] || continue
                    IFS= read -r name < "$hwmon/name"
                    case "$name" in
                        k10temp|coretemp|zenpower) cpu_temp="$hwmon/temp1_input"; break ;;
                    esac
                done
            fi
            [ -n "$cpu_temp" ] || cpu_temp=/sys/class/thermal/thermal_zone0/temp
            printf 'cpu %s\n' "$cpu_temp"
            for card in /sys/class/drm/card*/device; do
                [ -f "$card/vendor" ] || continue
                IFS= read -r vendor < "$card/vendor"
                if [ "$vendor" = 0x10de ] && command -v nvidia-smi >/dev/null; then
                    printf '%s\\n' 'gpu nvidia' "nvidia $(basename "$(readlink -f "$card")")"
                    exit
                fi
            done
            for card in /sys/class/drm/card*/device; do
                [ -f "$card/vendor" ] || continue
                IFS= read -r vendor < "$card/vendor"
                if [ "$vendor" = 0x1002 ] && [ -f "$card/gpu_busy_percent" ]; then
                    printf 'gpu amd\\nusage %s\\n' "$card/gpu_busy_percent"
                    for temp in "$card"/hwmon/hwmon*/temp1_input; do
                        [ -f "$temp" ] && { printf 'temp %s\\n' "$temp"; break; }
                    done
                    exit
                fi
            done
            for card in /sys/class/drm/card*/device; do
                [ -f "$card/vendor" ] || continue
                IFS= read -r vendor < "$card/vendor"
                if [ "$vendor" = 0x8086 ]; then
                    printf 'gpu intel\\n'
                    for temp in "$card"/hwmon/hwmon*/temp1_input; do
                        [ -f "$temp" ] && { printf 'temp %s\\n' "$temp"; break; }
                    done
                    exit
                fi
            done
            printf 'gpu unknown\\n'
        `]
        stdout: SplitParser {
            onRead: data => {
                const split = data.indexOf(" ");
                const key = data.slice(0, split);
                const value = data.slice(split + 1).trim();
                if (key === "cpu") root.cpuTempPath = value;
                else if (key === "usage") root.gpuUsagePath = value;
                else if (key === "temp") root.gpuTempPath = value;
                else if (key === "gpu") internal.gpuType = value;
                else if (key === "nvidia") internal.nvidiaId = value;
            }
        }
        onExited: {
            if (root.active) {
                cpuTempFile.reload();
                if (root.gpuMonitorEnabled)
                    root._triggerGpuUpdate();
            }
        }
    }

    function _applyCpuSnapshot(parts) {
        const offset = parts[1] === "cpu" ? 2 : 1;
        if (parts.length < offset + 8)
            return;

        const user = parseFloat(parts[offset]) || 0;
        const nice = parseFloat(parts[offset + 1]) || 0;
        const system = parseFloat(parts[offset + 2]) || 0;
        const idle = parseFloat(parts[offset + 3]) || 0;
        const iowait = parseFloat(parts[offset + 4]) || 0;
        const irq = parseFloat(parts[offset + 5]) || 0;
        const softirq = parseFloat(parts[offset + 6]) || 0;
        const steal = parseFloat(parts[offset + 7]) || 0;

        const total = user + nice + system + idle + iowait + irq + softirq + steal;
        const idleTime = idle + iowait;

        if (internal.prevTotal > 0) {
            const totalDiff = total - internal.prevTotal;
            const idleDiff = idleTime - internal.prevIdle;

            if (totalDiff > 0) {
                const usage = Math.round(((totalDiff - idleDiff) / totalDiff) * 100);
                internal.cpuUsage = Math.max(0, Math.min(100, usage));
            }
        }

        internal.prevTotal = total;
        internal.prevIdle = idleTime;
    }

    function _applyRamSnapshot(parts) {
        if (parts.length < 3)
            return;

        const total = parseFloat(parts[1]);
        const used = parseFloat(parts[2]);
        if (total > 0) {
            internal.ramUsage = Math.round((used / total) * 100);
            internal.ramUsed = root._formatGiB(used);
            internal.ramTotal = root._formatGiB(total);
        }
    }

    function _applyNetworkSnapshot(interfaces) {
        const nowMs = networkClock.elapsedMs();
        if (internal.prevNetworkSampleMs > 0) {
            let rx = 0;
            let tx = 0;
            for (const [name, counters] of interfaces) {
                const previous = internal.previousInterfaces.get(name);
                if (previous) {
                    rx += Math.max(0, counters[0] - previous[0]);
                    tx += Math.max(0, counters[1] - previous[1]);
                }
            }
            const seconds = Math.max(0.001, (nowMs - internal.prevNetworkSampleMs) / 1000);
            internal.networkDown = root._formatBytes(rx / seconds);
            internal.networkUp = root._formatBytes(tx / seconds);
        }
        internal.previousInterfaces = interfaces;
        internal.prevNetworkSampleMs = nowMs;
    }

    function _applyUptimeSnapshot(parts) {
        if (parts.length < 2)
            return;

        const totalSeconds = parseInt(parts[1]);
        if (isNaN(totalSeconds))
            return;

        const days = Math.floor(totalSeconds / 86400);
        const hours = Math.floor((totalSeconds % 86400) / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);

        if (days > 0) {
            internal.uptime = days + "d " + hours + "h";
        } else if (hours > 0) {
            internal.uptime = hours + "h " + minutes + "m";
        } else {
            internal.uptime = minutes + "m";
        }
    }

    function _readCpuStats() {
        cpuFile.reload();
        if (cpuTempPath !== "")
            cpuTempFile.reload();
    }

    function _readCoreStats() {
        memFile.reload();
        uptimeFile.reload();
        networkFile.reload();
    }

    ElapsedTimer { id: networkClock }

    FileView {
        preload: root.active
        printErrors: false
        id: cpuFile
        path: "/proc/stat"
        onLoaded: {
            if (root.active)
                root._applyCpuSnapshot(text().split("\n")[0].trim().split(/\s+/));
        }
    }

    FileView {
        preload: root.active
        printErrors: false
        id: memFile
        path: "/proc/meminfo"
        onLoaded: {
            const data = text();
            const total = /^MemTotal:\s+(\d+)/m.exec(data);
            const available = /^MemAvailable:\s+(\d+)/m.exec(data);
            if (total && available)
                root._applyRamSnapshot(["ram", Number(total[1]) * 1024, (Number(total[1]) - Number(available[1])) * 1024]);
        }
    }

    FileView {
        preload: root.active
        printErrors: false
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root._applyUptimeSnapshot(["uptime", text().trim().split(/\s+/)[0]])
    }

    // /proc/net/dev exposes the same counters as sysfs and includes hotplugged
    // interfaces automatically, without discovery or one reader per interface.
    FileView {
        preload: root.active
        printErrors: false
        id: networkFile
        path: "/proc/net/dev"
        onLoaded: {
            const interfaces = new Map();
            for (const line of text().split("\n")) {
                const colon = line.indexOf(":");
                if (colon < 0)
                    continue;
                const name = line.slice(0, colon).trim();
                const counters = line.slice(colon + 1).trim().split(/\s+/);
                if (name !== "lo" && counters.length >= 9)
                    interfaces.set(name, [Number(counters[0]), Number(counters[8])]);
            }
            root._applyNetworkSnapshot(interfaces);
        }
    }

    FileView {
        preload: root.active
        printErrors: false
        id: cpuTempFile
        path: root.cpuTempPath
        onLoaded: {
            const value = parseInt(text());
            if (root.active && !isNaN(value))
                internal.cpuTemp = Math.round(value / 1000);
        }
    }

    FileView {
        preload: root.active && root.gpuMonitorEnabled
        printErrors: false
        id: gpuUsageFile
        path: root.gpuUsagePath
        onLoaded: {
            const value = parseInt(text());
            if (root.active && root.gpuMonitorEnabled) {
                internal.gpuUsageKnown = !isNaN(value);
                if (internal.gpuUsageKnown)
                    internal.gpuUsage = value;
            }
        }
    }

    FileView {
        preload: root.active && root.gpuMonitorEnabled
        printErrors: false
        id: gpuTempFile
        path: root.gpuTempPath
        onLoaded: {
            const value = parseInt(text());
            if (root.active && root.gpuMonitorEnabled) {
                internal.gpuTempKnown = !isNaN(value);
                if (internal.gpuTempKnown)
                    internal.gpuTemp = Math.round(value / 1000);
            }
        }
    }

    // ========================================================================
    // DISK MONITORING
    // ========================================================================

    Process {
        id: updateDisk
        command: ["df", "-B1", "/"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/);
                if (parts.length >= 6) {
                    const total = parseFloat(parts[1]);
                    const used = parseFloat(parts[2]);
                    if (total > 0) {
                        internal.diskUsage = Math.round((used / total) * 100);
                        internal.diskUsed = root._formatGiB(used);
                        internal.diskTotal = root._formatGiB(total);
                    }
                }
            }
        }
    }

    // ========================================================================
    // NVIDIA GPU MONITORING
    // ========================================================================

    Process {
        id: updateNvidiaGpu
        command: ["nvidia-smi", "--id=" + internal.nvidiaId,
            "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector { id: nvidiaOutput }
        onExited: code => {
            if (!root.active || !root.gpuMonitorEnabled)
                return;
            const parts = code === 0 ? nvidiaOutput.text.trim().split(",") : [];
            const usage = parseInt(parts[0]);
            const temp = parseInt(parts[1]);
            internal.gpuUsageKnown = !isNaN(usage);
            internal.gpuTempKnown = !isNaN(temp);
            if (internal.gpuUsageKnown)
                internal.gpuUsage = usage;
            if (internal.gpuTempKnown)
                internal.gpuTemp = temp;
        }
    }
}
