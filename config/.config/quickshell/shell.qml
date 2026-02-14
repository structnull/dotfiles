//@ pragma Env QS_NO_RELOAD_POPUP=1
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import "./modules/bar/"

ShellRoot {
    id: root

    // =========================================================================
    // GLOBAL MODULE STATE
    // =========================================================================

    property real osdTrackedVolume: 0
    property bool osdTrackedMuted: false
    property real osdTrackedBrightness: 1.0
    property bool osdAudioReady: false
    property bool osdBrightnessReady: false
    readonly property bool suppressOsdInQuickSettings: OsdService.suppressed

    function maybeShowVolumeOsd() {
        const volumeNow = Math.max(0, Math.min(1.5, AudioService.volumeForOsd));
        const mutedNow = AudioService.muted;

        if (!osdAudioReady) {
            osdTrackedVolume = volumeNow;
            osdTrackedMuted = mutedNow;
            return;
        }

        const volumeChanged = Math.abs(volumeNow - osdTrackedVolume) > 0.003;
        const muteChanged = mutedNow !== osdTrackedMuted;

        osdTrackedVolume = volumeNow;
        osdTrackedMuted = mutedNow;

        if (!volumeChanged && !muteChanged)
            return;
        if (suppressOsdInQuickSettings)
            return;

        OsdService.showVolume(volumeNow, mutedNow);
    }

    function maybeShowBrightnessOsd() {
        const brightnessNow = Math.max(0.05, Math.min(1.0, BrightnessService.brightness));

        if (!osdBrightnessReady) {
            osdTrackedBrightness = brightnessNow;
            return;
        }

        const brightnessChanged = Math.abs(brightnessNow - osdTrackedBrightness) > 0.003;
        osdTrackedBrightness = brightnessNow;

        if (!brightnessChanged)
            return;
        if (suppressOsdInQuickSettings)
            return;

        OsdService.showBrightness(brightnessNow);
    }

    Timer {
        id: osdStateArmTimer
        interval: 800
        running: true
        repeat: false
        onTriggered: {
            root.osdTrackedVolume = Math.max(0, Math.min(1.5, AudioService.volumeForOsd));
            root.osdTrackedMuted = AudioService.muted;
            root.osdTrackedBrightness = Math.max(0.05, Math.min(1.0, BrightnessService.brightness));
            root.osdAudioReady = true;
            root.osdBrightnessReady = true;
        }
    }

    Connections {
        target: AudioService

        function onVolumeForOsdChanged() {
            root.maybeShowVolumeOsd();
        }

        function onMutedChanged() {
            root.maybeShowVolumeOsd();
        }
    }

    Connections {
        target: BrightnessService

        function onBrightnessChanged() {
            root.maybeShowBrightnessOsd();
        }
    }

    // =========================================================================
    // BLUETOOTH AGENT
    // =========================================================================

    readonly property string bluetoothAgentScriptPath: Qt.resolvedUrl("./scripts/bluetooth-agent.py").toString().replace("file://", "")

    Process {
        id: bluetoothAgent
        command: ["python3", root.bluetoothAgentScriptPath]
        running: true

        stderr: SplitParser {
            onRead: data => console.error("[BluetoothAgent]: " + data)
        }
    }

    // =========================================================================
    // UI COMPONENTS - LAZY LOADING
    // =========================================================================

    // Bar - always active (main component)
    Bar {}

    // Notifications
    Loader {
        id: notificationLoader
        active: NotificationService.activePopupCount > 0 || NotificationService.popups.length > 0
        source: "./modules/notifications/NotificationOverlay.qml"
    }

    // Power Overlay
    Loader {
        id: powerLoader
        active: PowerService.overlayVisible
        source: "./modules/power/PowerOverlay.qml"
    }
    // OSD
    Loader {
        active: true
        source: "./modules/osd/OsdOverlay.qml"
    }

    // Keybinds Overlay
    Loader {
        id: keybindsLoader
        active: false
        source: "./modules/keybinds/KeybindsOverlay.qml"

        function toggle() {
            if (active && item) {
                item.hide();
                active = false;
            } else {
                active = true;
            }
        }

        Connections {
            target: keybindsLoader.item
            enabled: keybindsLoader.status === Loader.Ready

            function onShowingChanged() {
                if (keybindsLoader.item && !keybindsLoader.item.showing)
                    keybindsLoader.active = false;
            }
        }

        onStatusChanged: {
            if (status === Loader.Ready && item)
                item.showing = true;
        }
    }

    // Shortcut: Power Menu
    GlobalShortcut {
        name: "power_menu"
        description: "Power menu"

        onPressed: PowerService.showOverlay()
    }
    // Shortcut: Volume Up
    GlobalShortcut {
        name: "volume_up"
        description: "Increase volume"

        onPressed: {
            const nextVolume = Math.max(0, Math.min(1.5, AudioService.volume + 0.05));
            AudioService.setVolume(nextVolume);
        }
    }

    // Shortcut: Volume Down
    GlobalShortcut {
        name: "volume_down"
        description: "Decrease volume"

        onPressed: {
            const nextVolume = Math.max(0, Math.min(1.5, AudioService.volume - 0.05));
            AudioService.setVolume(nextVolume);
        }
    }

    // Shortcut: Volume Mute
    GlobalShortcut {
        name: "volume_mute"
        description: "Mute volume"

        onPressed: {
            AudioService.toggleMute();
        }
    }

    // Shortcut: Brightness Up
    GlobalShortcut {
        name: "brightness_up"
        description: "Increase brightness"

        onPressed: {
            const nextBrightness = Math.max(0.05, Math.min(1.0, BrightnessService.brightness + 0.05));
            BrightnessService.setBrightness(nextBrightness);
        }
    }

    // Shortcut: Brightness Down
    GlobalShortcut {
        name: "brightness_down"
        description: "Decrease brightness"

        onPressed: {
            const nextBrightness = Math.max(0.05, Math.min(1.0, BrightnessService.brightness - 0.05));
            BrightnessService.setBrightness(nextBrightness);
        }
    }

    // Shortcut: Keybinds Help
    GlobalShortcut {
        name: "keybinds_help"
        description: "Keybinds help"

        onPressed: keybindsLoader.toggle()
    }
}
