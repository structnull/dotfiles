pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services

Singleton {
    id: root

    // Helper function to shorten the service call
    function getState(path, fallback) {
        return StateService.get(path, fallback);
    }

    // ========================================================================
    // PALETTE (from ThemeService — defined in .data/themes/<name>.json)
    // ========================================================================
    readonly property color backgroundColor: ThemeService.color("background", "#0c1118")
    readonly property real backgroundOpacity: getState("opacity.background", 0.48)
    readonly property color backgroundTransparentColor: Qt.alpha(backgroundColor, backgroundOpacity)
    readonly property color surface0Color: ThemeService.color("surface0", "#121923")
    readonly property color surface1Color: ThemeService.color("surface1", "#1a2430")
    readonly property color surface2Color: ThemeService.color("surface2", "#273447")
    readonly property color surface3Color: ThemeService.color("surface3", "#33465e")

    readonly property color textColor: ThemeService.color("text", "#ffffff")
    readonly property color textReverseColor: ThemeService.color("textReverse", "#000000")
    readonly property color subtextColor: ThemeService.color("subtext", "#d7dfeb")
    readonly property color subtextReverseColor: ThemeService.color("subtextReverse", "#7b8798")

    readonly property color accentColor: ThemeService.color("accent", "#d6e9ff")
    readonly property color successColor: ThemeService.color("success", "#7ee2a8")
    readonly property color warningColor: ThemeService.color("warning", "#ffcc66")
    readonly property color errorColor: ThemeService.color("error", "#ff5f57")

    readonly property color mutedColor: ThemeService.color("muted", "#9aa8bc")
    readonly property color greyBlueColor: ThemeService.color("greyBlue", "#243141")
    readonly property color blueDarkColor: ThemeService.color("blueDark", "#0d141d")

    // ========================================================================
    // WALLPAPER
    // ========================================================================
    readonly property bool dynamicWallpaper: getState("wallpaper.dynamic", true)

    // ========================================================================
    // GEOMETRY & LAYOUT
    // ========================================================================
    readonly property int barHeight: getState("bar.height", 32)
    readonly property bool barAutoHide: getState("bar.autoHide", true)

    readonly property int radiusSmall: getState("geometry.radiusSmall", 5)
    readonly property int radius: getState("geometry.radius", 10)
    readonly property int radiusLarge: getState("geometry.radiusLarge", 15)
    readonly property int spacing: getState("geometry.spacing", 8)
    readonly property int padding: getState("geometry.padding", 6)

    // ========================================================================
    // TYPOGRAPHY
    // ========================================================================
    readonly property string font: getState("typography.font", "Product Sans")

    readonly property int fontSizeSmall: getState("typography.sizeSmall", 12)
    readonly property int fontSizeNormal: getState("typography.sizeNormal", 14)
    readonly property int fontSizeLarge: getState("typography.sizeLarge", 16)
    readonly property int fontSizeIconSmall: getState("typography.iconSmall", 18)
    readonly property int fontSizeIcon: getState("typography.icon", 22)
    readonly property int fontSizeIconLarge: getState("typography.iconLarge", 28)

    // ========================================================================
    // ANIMATIONS
    // ========================================================================
    readonly property int animDurationShort: getState("animations.short", 100)
    readonly property int animDuration: getState("animations.normal", 200)
    readonly property int animDurationLong: getState("animations.long", 400)

    readonly property bool screenshotAnimations: getState("animations.screenshot", true)

    // ========================================================================
    // NOTIFICATIONS
    // ========================================================================
    readonly property int notifWidth: getState("notifications.width", 350)
    readonly property int notifImageSize: getState("notifications.imageSize", 40)
    readonly property int notifTimeout: getState("notifications.timeout", 5000)
    readonly property int notifSpacing: getState("notifications.spacing", 10)
}
