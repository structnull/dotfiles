pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    // =========================================================================
    // STATE
    // =========================================================================

    readonly property string shaderDir: Quickshell.env("HOME") + "/.config/quickshell/shaders"

    property bool stateLoaded: false
    property bool shaderActive: false
    readonly property bool enabled: stateLoaded && shaderActive

    property bool hasPendingApply: false
    property bool pendingActive: false

    // =========================================================================
    // PUBLIC API
    // =========================================================================

    function toggle() {
        setGrayscale(!enabled);
    }

    function setGrayscale(value: bool) {
        applyShader(value);
    }

    function refresh() {
        if (!statusProbe.running)
            statusProbe.running = true;
    }

    // =========================================================================
    // INTERNALS
    // =========================================================================

    function applyShader(active: bool) {
        root.shaderActive = active;
        root.stateLoaded = true;

        if (applyProcess.running) {
            root.pendingActive = active;
            root.hasPendingApply = true;
            return;
        }

        runApply(active);
    }

    function runApply(active: bool) {
        if (root.shaderDir === "")
            return;

        // Toggle between two real shaders: unsetting screen_shader and
        // setting a path again can silently do nothing. Hyprland 0.56+
        // parses via the Lua config, so set through hyprctl eval.
        const shader = active ? "grayscale.glsl" : "passthrough.glsl";
        applyProcess.command = ["bash", "-lc",
            "hyprctl eval 'hl.config({decoration = {screen_shader = \"" + root.shaderDir + "/" + shader + "\"}})'"];
        applyProcess.running = true;
    }

    // =========================================================================
    // PROCESSES
    // =========================================================================

    // Probe the current shader state from Hyprland on startup
    Process {
        id: statusProbe
        command: ["hyprctl", "getoption", "decoration:screen_shader"]

        property string buffer: ""
        stdout: SplitParser {
            onRead: data => statusProbe.buffer += data + "\n"
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.shaderActive = false;
                root.stateLoaded = true;
                statusProbe.buffer = "";
                return;
            }

            const text = statusProbe.buffer;
            statusProbe.buffer = "";

            // Check if the output contains the grayscale shader path
            const match = text.match(/^str:\s*(.+)$/m);
            const path = match ? match[1].trim() : "";
            const marker = "shaders/grayscale.glsl";
            root.shaderActive = path.length >= marker.length
                && path.indexOf(marker, path.length - marker.length) !== -1;
            root.stateLoaded = true;
        }
    }

    // Apply shader change
    Process {
        id: applyProcess
        onExited: (exitCode, exitStatus) => {
            if (root.hasPendingApply) {
                root.hasPendingApply = false;
                root.runApply(root.pendingActive);
                return;
            }
            root.refresh();
        }
    }

    Component.onCompleted: refresh()

    // =========================================================================
    // IPC — controllable via: qs ipc call grayscale <function>
    // =========================================================================

    IpcHandler {
        target: "grayscale"

        function status(): string {
            return JSON.stringify({ enabled: root.enabled });
        }

        function refresh(): void {
            root.refresh();
        }

        function enable(): string {
            root.setGrayscale(true);
            return "enabled";
        }

        function disable(): string {
            root.setGrayscale(false);
            return "disabled";
        }

        function toggle(): string {
            const enabling = !root.enabled;
            root.setGrayscale(enabling);
            return enabling ? "enabled" : "disabled";
        }
    }
}
