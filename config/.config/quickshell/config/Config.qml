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
    // PALETTE (driven by ThemeService / Matugen)
    // ========================================================================
    readonly property color backgroundColor: ThemeService.colors.background || "#0c1118"
    readonly property real backgroundOpacity: getState("opacity.background", 0.48)
    readonly property color backgroundTransparentColor: Qt.alpha(backgroundColor, backgroundOpacity)
    readonly property color surface0Color: ThemeService.colors.surfaceDim || "#121923"
    readonly property color surface1Color: ThemeService.colors.surfaceContainerLow || "#1a2430"
    readonly property color surface2Color: ThemeService.colors.surfaceContainer || "#273447"
    readonly property color surface3Color: ThemeService.colors.surfaceContainerHigh || "#33465e"

    readonly property color textColor: ThemeService.colors.onSurface || "#ffffff"
    readonly property color textReverseColor: ThemeService.colors.onPrimary || "#000000"
    readonly property color subtextColor: ThemeService.colors.onSurfaceVariant || "#d7dfeb"
    readonly property color subtextReverseColor: ThemeService.colors.outline || "#7b8798"

    readonly property color accentColor: ThemeService.colors.primary || "#7eb8e8"
    readonly property color successColor: "#7ee2a8"
    readonly property color warningColor: "#ffcc66"
    readonly property color errorColor: ThemeService.colors.error || "#ff5f57"

    readonly property color mutedColor: ThemeService.colors.outline || "#9aa8bc"
    readonly property color greyBlueColor: ThemeService.colors.surfaceContainerLow || "#243141"
    readonly property color blueDarkColor: ThemeService.colors.surfaceDim || "#0d141d"

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
