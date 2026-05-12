pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool selectorVisible: false
    property string current: StateService.get("wallpaper.current", "")

    function set(path: string) {
        if (!path)
            return;

        current = path;
        StateService.set("wallpaper.current", path);
        setWallpaperProc.command = ["awww", "img", "--transition-type", "fade",  "--transition-fps", "144", path];
        setWallpaperProc.running = true;
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

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.error("[WallpaperService] awww failed with exit code:", exitCode);
        }
    }
}
