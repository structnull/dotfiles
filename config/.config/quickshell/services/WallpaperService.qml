pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool selectorVisible: false
    property string current: StateService.get("wallpaper.current", "")

    property string _applyingPath: ""
    property string _pendingPath: ""
    property string _palettePath: ""
    property string error: ""

    function set(path: string) {
        if (!path)
            return;
        _pendingPath = path;
        _applyPending();
    }

    function _applyPending() {
        if (_applyingPath || !_pendingPath)
            return;

        error = "";
        _applyingPath = _pendingPath;
        _pendingPath = "";
        setWallpaperProc.exec(["awww", "img", "--transition-type", "fade", "--transition-fps", "144", _applyingPath]);
    }

    function _finishApply(success: bool) {
        const path = _applyingPath;
        _applyingPath = "";
        if (success) {
            current = path;
            StateService.set("wallpaper.current", path);
            _palettePath = path;
            if (_pendingPath === path)
                _pendingPath = "";
        } else {
            error = "Could not apply " + path.split("/").pop();
            console.warn("[WallpaperService]", error);
        }
        if (!_pendingPath && _palettePath) {
            ThemeService.generateFromImage(_palettePath);
            _palettePath = "";
        }
        Qt.callLater(root._applyPending);
    }

    function _checkStartFailure() {
        if (_applyingPath && !setWallpaperProc.running)
            _finishApply(false);
    }

    function show() {
        selectorVisible = true;
    }

    function hide() {
        selectorVisible = false;
    }

    function toggle() {
        selectorVisible = !selectorVisible;
    }

    Connections {
        target: StateService

        function onStateLoaded() {
            root.current = StateService.get("wallpaper.current", "");
        }
    }

    Process {
        id: setWallpaperProc

        stderr: SplitParser {
            onRead: data => console.warn("[WallpaperService awww]: " + data)
        }

        onRunningChanged: {
            if (!running)
                Qt.callLater(root._checkStartFailure);
        }
        onExited: (exitCode, exitStatus) => root._finishApply(exitCode === 0 && exitStatus === 0)
    }
}
