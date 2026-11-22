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
    property string mode: StateService.get("theme.mode", "dark")
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

    property var _pendingCommand: null
    property bool _generating: false

    function generateFromImage(imagePath: string) {
        _pendingCommand = ["matugen", "image", "--mode", mode, "--type", "scheme-vibrant", "--prefer", "saturation", imagePath];
        _generatePending();
    }

    function generateFromColor(hex: string) {
        _pendingCommand = ["matugen", "color", "hex", "--mode", mode, "--type", "scheme-vibrant", hex];
        _generatePending();
    }

    function _generatePending() {
        if (_generating || !_pendingCommand)
            return;
        const command = _pendingCommand;
        _pendingCommand = null;
        _generating = true;
        _genProc.exec(command);
    }

    function _checkStartFailure() {
        if (_generating && !_genProc.running) {
            console.warn("[ThemeService] Could not start matugen");
            _generating = false;
            _generatePending();
        }
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
        id: colorFile
        path: root._colorsPath
        watchChanges: true
        blockLoading: true
        printErrors: false
        onLoaded: root._parseColors()

        onFileChanged: _reloadDebounce.restart()
    }

    Timer {
        id: _reloadDebounce
        interval: 200
        onTriggered: root._loadColors()
    }

    function _loadColors() {
        colorFile.reload();
    }

    function _parseColors() {
        try {
            const palette = JSON.parse(colorFile.text());
            const scheme = palette?.[mode];
            if (!scheme || typeof scheme.primary !== "string" || typeof scheme.surface !== "string")
                return;
            _palette = palette;
            _loaded = true;
        } catch (error) {
            // Keep the last valid palette while Matugen is writing.
        }
    }

    // --- Generation Process ---
    Process {
        id: _genProc

        stderr: SplitParser {
            onRead: data => console.warn("[ThemeService matugen]:", data)
        }

        onRunningChanged: {
            if (!running)
                Qt.callLater(root._checkStartFailure);
        }
        onExited: (exitCode, exitStatus) => {
            root._generating = false;
            if (exitCode !== 0 || exitStatus !== 0)
                console.warn("[ThemeService] Matugen failed with exit code:", exitCode);
            Qt.callLater(root._generatePending);
        }
    }
}
