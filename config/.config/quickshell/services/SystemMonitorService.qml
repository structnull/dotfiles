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

    // ========================================================================
    // GPU PROPERTIES
    // ========================================================================

    readonly property int gpuUsage: internal.gpuUsage
    readonly property int gpuTemp: internal.gpuTemp
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
        if (!gpuMonitorEnabled) {
            internal.gpuUsage = 0;
            internal.gpuTemp = 0;
        } else if (internal.gpuType !== "unknown") {
            _triggerGpuUpdate();
        }
    }

    function _triggerGpuUpdate() {
        if (internal.gpuType === "nvidia") {
            updateNvidiaGpu.running = true;
        } else if (internal.gpuType === "amd") {
            updateAmdGpuUsage.running = true;
            updateAmdGpuTemp.running = true;
        } else if (internal.gpuType === "intel") {
            updateIntelGpuTemp.running = true;
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
        property real prevRx: 0
        property real prevTx: 0
        property double prevNetworkSampleMs: 0

        // Uptime
        property string uptime: "0m"
    }

    // ========================================================================
    // INITIALIZATION
    // ========================================================================

    Component.onCompleted: detectGpu.running = true

    onActiveChanged: {
        if (active)
            triggerFullUpdate();
    }

    function triggerFullUpdate() {
        detectGpu.running = true;
        updateCoreStats.running = true;
        updateCpuTemp.running = true;
        updateDisk.running = true;
    }

    // ========================================================================
    // UPDATE TIMER
    // ========================================================================

    Timer {
        interval: 4000
        running: root.active
        repeat: true
        onTriggered: {
            updateCoreStats.running = true;
            updateCpuTemp.running = true;

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

    Process {
        id: detectGpu
        command: ["bash", "-c", `
            if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
                echo "nvidia"
            elif [ -f /sys/class/drm/card0/device/gpu_busy_percent ] || [ -f /sys/class/drm/card1/device/gpu_busy_percent ]; then
                echo "amd"
            elif [ -d /sys/class/drm/card0/gt ] || ls /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1; then
                echo "intel"
            else
                echo "unknown"
            fi
        `]
        stdout: SplitParser {
            onRead: data => {
                const type = data.trim();
                internal.gpuType = type;

                if (root.gpuMonitorEnabled) {
                    root._triggerGpuUpdate();
                }
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

    function _applyNetworkSnapshot(parts) {
        if (parts.length < 3)
            return;

        const rx = parseFloat(parts[1]);
        const tx = parseFloat(parts[2]);
        const nowMs = Date.now();

        if (internal.prevRx > 0 && internal.prevNetworkSampleMs > 0) {
            const elapsedSeconds = Math.max(0.001, (nowMs - internal.prevNetworkSampleMs) / 1000.0);
            const rxDelta = (rx - internal.prevRx) / elapsedSeconds;
            const txDelta = (tx - internal.prevTx) / elapsedSeconds;
            internal.networkDown = root._formatBytes(Math.max(0, rxDelta));
            internal.networkUp = root._formatBytes(Math.max(0, txDelta));
        }

        internal.prevRx = rx;
        internal.prevTx = tx;
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

    // ========================================================================
    // CORE MONITORING
    // ========================================================================

    Process {
        id: updateCoreStats
        command: ["bash", "-c", `
            cpu_line=$(head -1 /proc/stat)
            set -- $(awk '/MemTotal:/ {total=$2} /MemAvailable:/ {available=$2} END {print total, available}' /proc/meminfo)
            mem_total_kib=$1
            mem_available_kib=$2
            mem_used=$(( (mem_total_kib - mem_available_kib) * 1024 ))
            mem_total=$(( mem_total_kib * 1024 ))

            rx=0
            tx=0
            for iface in /sys/class/net/*/; do
                name=$(basename "$iface")
                [ "$name" = "lo" ] && continue
                [ -f "$iface/statistics/rx_bytes" ] || continue
                rx=$((rx + $(cat "$iface/statistics/rx_bytes")))
                tx=$((tx + $(cat "$iface/statistics/tx_bytes")))
            done

            uptime_seconds=$(awk '{print int($1)}' /proc/uptime)

            printf 'cpu %s\\n' "$cpu_line"
            printf 'ram %s %s\\n' "$mem_total" "$mem_used"
            printf 'net %s %s\\n' "$rx" "$tx"
            printf 'uptime %s\\n' "$uptime_seconds"
        `]
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split("\n");
                for (const line of lines) {
                    const parts = line.trim().split(/\s+/);
                    if (parts.length === 0)
                        continue;

                    if (parts[0] === "cpu")
                        root._applyCpuSnapshot(parts);
                    else if (parts[0] === "ram")
                        root._applyRamSnapshot(parts);
                    else if (parts[0] === "net")
                        root._applyNetworkSnapshot(parts);
                    else if (parts[0] === "uptime")
                        root._applyUptimeSnapshot(parts);
                }
            }
        }
    }

    // ========================================================================
    // CPU TEMPERATURE MONITORING
    // ========================================================================

    Process {
        id: updateCpuTemp
        command: ["bash", "-c", `
            for zone in /sys/class/thermal/thermal_zone*/temp; do
                type_file="\${zone%/temp}/type"
                if [ -f "$type_file" ]; then
                    type=$(cat "$type_file" 2>/dev/null)
                    if [[ "$type" == *"cpu"* ]] || [[ "$type" == *"x86_pkg"* ]] || [[ "$type" == *"coretemp"* ]]; then
                        cat "$zone" 2>/dev/null
                        exit 0
                    fi
                fi
            done
            cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "0"
        `]
        stdout: SplitParser {
            onRead: data => {
                const temp = parseInt(data.trim());
                if (!isNaN(temp)) {
                    internal.cpuTemp = Math.round(temp / 1000);
                }
            }
        }
    }

    // ========================================================================
    // DISK MONITORING
    // ========================================================================

    Process {
        id: updateDisk
        command: ["bash", "-c", "df -B1 / | awk 'NR==2{print $2,$3}'"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/);
                if (parts.length >= 2) {
                    const total = parseFloat(parts[0]);
                    const used = parseFloat(parts[1]);
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
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(",").map(s => s.trim());
                if (parts.length >= 2) {
                    const usage = parseInt(parts[0]);
                    const temp = parseInt(parts[1]);

                    if (!isNaN(usage)) internal.gpuUsage = usage;
                    if (!isNaN(temp)) internal.gpuTemp = temp;
                }
            }
        }
    }

    // ========================================================================
    // AMD GPU MONITORING
    // ========================================================================

    Process {
        id: updateAmdGpuUsage
        command: ["bash", "-c", `
            for card in /sys/class/drm/card*/device/gpu_busy_percent; do
                if [ -f "$card" ]; then
                    cat "$card" 2>/dev/null
                    exit 0
                fi
            done
            echo "0"
        `]
        stdout: SplitParser {
            onRead: data => {
                const usage = parseInt(data.trim());
                if (!isNaN(usage)) {
                    internal.gpuUsage = usage;
                }
            }
        }
    }

    Process {
        id: updateAmdGpuTemp
        command: ["bash", "-c", `
            for hwmon in /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input; do
                if [ -f "$hwmon" ]; then
                    cat "$hwmon" 2>/dev/null
                    exit 0
                fi
            done
            cat /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input 2>/dev/null || echo "0"
        `]
        stdout: SplitParser {
            onRead: data => {
                const temp = parseInt(data.trim());
                if (!isNaN(temp)) {
                    internal.gpuTemp = Math.round(temp / 1000);
                }
            }
        }
    }

    // ========================================================================
    // INTEL GPU MONITORING
    // ========================================================================

    Process {
        id: updateIntelGpuTemp
        command: ["bash", "-c", `
            for zone in /sys/class/thermal/thermal_zone*/temp; do
                type_file="\${zone%/temp}/type"
                if [ -f "$type_file" ]; then
                    type=$(cat "$type_file" 2>/dev/null)
                    if [[ "$type" == *"gpu"* ]] || [[ "$type" == *"pch"* ]]; then
                        cat "$zone" 2>/dev/null
                        exit 0
                    fi
                fi
            done
            cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "0"
        `]
        stdout: SplitParser {
            onRead: data => {
                const temp = parseInt(data.trim());
                if (!isNaN(temp)) {
                    internal.gpuTemp = Math.round(temp / 1000);
                }
            }
        }
    }

}
