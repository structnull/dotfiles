pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // =========================================================================
    // PUBLIC API
    // =========================================================================

    // Current scheme mode: "dark" or "light"
    property string mode: "dark"
    readonly property bool isDarkMode: mode === "dark"

    // Resolved color palette for the active mode
    readonly property var colors: {
        if (!_loaded || !_palette)
            return _fallback;

        const scheme = _palette[mode];
        if (!scheme)
            return _fallback;

        return scheme;
    }

    // Whether matugen-generated colors are loaded
    readonly property bool loaded: _loaded

    function generateFromImage(imagePath: string) {
        _genProc.command = ["matugen", "image", "--mode", mode, "--source-color-index", "0", imagePath];
        _genProc.running = true;
    }

    function generateFromColor(hex: string) {
        _genProc.command = ["matugen", "color", "hex", hex];
        _genProc.running = true;
    }

    // =========================================================================
    // INTERNALS
    // =========================================================================

    readonly property string _colorsPath: Quickshell.env("HOME") + "/.cache/quickshell/colors.json"

    property var _palette: null
    property bool _loaded: false

    // Fallback colors matching the original hardcoded Config palette
    readonly property var _fallback: ({
        "primary": "#7eb8e8",
        "onPrimary": "#000000",
        "primaryContainer": "#243141",
        "onPrimaryContainer": "#d7dfeb",
        "secondary": "#7eb8e8",
        "onSecondary": "#000000",
        "secondaryContainer": "#273447",
        "tertiary": "#7eb8e8",
        "tertiaryContainer": "#273447",
        "surface": "#0c1118",
        "surfaceDim": "#0d141d",
        "surfaceContainer": "#273447",
        "surfaceContainerHigh": "#33465e",
        "surfaceContainerHighest": "#33465e",
        "surfaceContainerLow": "#1a2430",
        "onSurface": "#ffffff",
        "onSurfaceVariant": "#d7dfeb",
        "outline": "#9aa8bc",
        "outlineVariant": "#33465e",
        "error": "#ff5f57",
        "background": "#0c1118"
    })

    Connections {
        target: StateService
        function onStateLoaded() {
            root.mode = StateService.get("theme.mode", "dark");
        }
    }

    Component.onCompleted: _loadColors()

    // --- File Watcher ---
    FileView {
        id: _colorFileWatcher
        path: root._colorsPath
        watchChanges: true

        onFileChanged: _reloadDebounce.restart()
    }

    Timer {
        id: _reloadDebounce
        interval: 200
        onTriggered: {
            if (!_loadProc.running)
                root._loadColors();
        }
    }

    // --- Load Process (reads JSON via cat, same pattern as StateService) ---
    function _loadColors() {
        _loadProc.running = true;
    }

    Process {
        id: _loadProc
        command: ["cat", root._colorsPath]

        property string buffer: ""
        stdout: SplitParser {
            onRead: data => _loadProc.buffer += data
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("[ThemeService] No colors.json found, using fallbacks");
                root._loaded = false;
                _loadProc.buffer = "";
                return;
            }

            try {
                const parsed = JSON.parse(_loadProc.buffer.trim());
                root._palette = parsed;
                root._loaded = true;
            } catch (e) {
                console.error("[ThemeService] JSON parse error:", e);
                root._loaded = false;
            }
            _loadProc.buffer = "";
        }
    }

    // --- Generation Process ---
    Process {
        id: _genProc

        stderr: SplitParser {
            onRead: data => console.warn("[ThemeService matugen]:", data)
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                console.log("[ThemeService] Matugen generation complete");
                // File watcher will pick up the change and reload
            } else {
                console.error("[ThemeService] Matugen failed with exit code:", exitCode);
            }
        }
    }
}
