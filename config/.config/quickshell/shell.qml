//@ pragma Env QS_NO_RELOAD_POPUP=1
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "./modules/bar/"
import "./modules/osd/"

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

    function armAudioOsd() {
        osdTrackedVolume = AudioService.volumeForOsd;
        osdTrackedMuted = AudioService.muted;
        osdAudioReady = AudioService.volumeKnown;
    }

    function armBrightnessOsd() {
        osdTrackedBrightness = BrightnessService.brightness;
        osdBrightnessReady = BrightnessService.brightnessKnown;
    }

    Component.onCompleted: {
        armAudioOsd();
        armBrightnessOsd();
    }

    Connections {
        target: AudioService
        function onVolumeKnownChanged() { root.armAudioOsd(); }
        function onSinkChanged() { root.armAudioOsd(); }
        function onVolumeForOsdChanged() { root.maybeShowVolumeOsd(); }
        function onMutedChanged() { root.maybeShowVolumeOsd(); }
    }

    Connections {
        target: BrightnessService
        function onBrightnessKnownChanged() { root.armBrightnessOsd(); }
        function onBrightnessChanged() { root.maybeShowBrightnessOsd(); }
    }

    // =========================================================================
    // IPC TARGETS
    // =========================================================================

    IpcHandler {
        target: "power"

        function showOverlay(): void {
            PowerService.showOverlay();
        }

        function hideOverlay(): void {
            PowerService.hideOverlay();
        }

        function toggleOverlay(): void {
            if (PowerService.overlayVisible)
                PowerService.hideOverlay();
            else
                PowerService.showOverlay();
        }

        function execute(actionId: string): void {
            PowerService.executeAction(actionId);
        }
    }

    IpcHandler {
        target: "theme"

        function generateFromImage(imagePath: string): void {
            ThemeService.generateFromImage(imagePath);
        }

        function generateFromColor(hex: string): void {
            ThemeService.generateFromColor(hex);
        }
    }

    IpcHandler {
        target: "wallpaper"

        function show(): void {
            WallpaperService.show();
        }

        function hide(): void {
            WallpaperService.hide();
        }

        function toggle(): void {
            WallpaperService.toggle();
        }
    }

    IpcHandler {
        target: "layout"

        function scrolling(): void { LayoutService.show("scrolling"); }
        function dwindle(): void { LayoutService.show("dwindle"); }
        function master(): void { LayoutService.show("master"); }
        function monocle(): void { LayoutService.show("monocle"); }
    }

    // =========================================================================
    // UI COMPONENTS - LAZY LOADING
    // =========================================================================

    // Bar - always active (main component)
    Bar {}
    // Notifications
    LazyLoader {
        id: notificationLoader
        active: NotificationService.activePopupCount > 0
        source: "./modules/notifications/NotificationOverlay.qml"
    }
    // Power Overlay
    LazyLoader {
        id: powerLoader
        active: PowerService.overlayLoaded
        source: "./modules/power/PowerOverlay.qml"
    }
    // OSD
    OsdOverlay {}
    // Wallpaper Selector
    LazyLoader {
        activeAsync: WallpaperService.selectorVisible
        source: "./modules/wallpaper/WallpaperSelector.qml"
    }
    // Polkit Authentication
    LazyLoader {
        active: PolkitService.isActive
        source: "./modules/polkit/PolkitOverlay.qml"
    }
}
