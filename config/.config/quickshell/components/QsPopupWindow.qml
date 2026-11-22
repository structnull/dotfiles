pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config

PanelWindow {
    id: root

    property int popupWidth: 380
    property int popupMaxHeight: 700
    property Item anchorItem: null
    property string anchorSide: "left"
    property real contentImplicitHeight: 0
    readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
    readonly property point anchorPosition: {
        if (!anchorItem)
            return Qt.point(0, 0);
        const transform = anchorWindow?.windowTransform;
        const x = anchorItem.x;
        const y = anchorItem.y;
        return anchorItem.mapToGlobal(anchorItem.width / 2, anchorItem.height);
    }

    default property alias content: contentContainer.data

    signal closing

    readonly property int screenMargin: 5

    WlrLayershell.namespace: "qs_modules"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: -1

    anchors {
        top: true
        left: true
    }

    screen: anchorWindow?.screen ?? Quickshell.screens[0] ?? null

    margins {
        top: {
            const y = root.anchorItem ? root.anchorPosition.y - (root.screen?.y ?? 0) + 8 : Config.barHeight + 10;
            return Math.max(0, Math.min((root.screen?.height ?? 1080) - root.implicitHeight, y));
        }
        left: {
            const width = root.screen?.width ?? 1920;
            const x = root.anchorItem ? root.anchorPosition.x - (root.screen?.x ?? 0) - root.implicitWidth / 2
                : (root.anchorSide === "right" ? width - root.implicitWidth - 10 : 10);
            return Math.max(5, Math.min(width - root.implicitWidth - 5, x));
        }
    }

    implicitWidth: Math.max(1, Math.min((screen?.width ?? 1920) - 10, popupWidth + (screenMargin * 2)))
    implicitHeight: Math.min(popupMaxHeight, Math.max(1, (screen?.height ?? 1080) - Config.barHeight - 16))
    visible: false
    color: "transparent"

    property bool isClosing: false
    property real openProgress: 0.0

    // Content opacity derived from openProgress — content fades in after
    // container is partially visible, and fades out before container fully closes.
    readonly property real contentOpacity: Math.max(0, Math.min(1, (openProgress - 0.15) / 0.65))

    function closeWindow() {
        if (!visible || isClosing)
            return;
        isClosing = true;
        openAnimation.stop();
        closeAnimation.restart();
    }

    // -- Open: smooth deceleration --
    NumberAnimation {
        id: openAnimation
        target: root
        property: "openProgress"
        from: 0
        to: 1
        duration: 380
        easing.type: Easing.OutQuart
    }

    // -- Close: natural settle-back --
    NumberAnimation {
        id: closeAnimation
        target: root
        property: "openProgress"
        to: 0
        duration: 300
        easing.type: Easing.InCubic
        onFinished: {
            if (!root.isClosing)
                return;

            root.closing();
            root.visible = false;
            root.isClosing = false;
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        active: false
        onCleared: root.closeWindow()
    }

    Timer {
        id: grabTimer
        interval: 10
        onTriggered: {
            focusGrab.active = true;
            background.forceActiveFocus();
        }
    }

    onVisibleChanged: {
        if (visible) {
            isClosing = false;
            closeAnimation.stop();
            openProgress = 0;
            openAnimation.restart();
            grabTimer.restart();
        } else {
            focusGrab.active = false;
            openAnimation.stop();
            closeAnimation.stop();
            openProgress = 0;
            isClosing = false;
        }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: background
            width: Math.min(root.popupWidth, parent.width)
            height: Math.min(root.implicitHeight, root.contentImplicitHeight + 32)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            color: Config.backgroundTransparentColor
            radius: Config.radiusLarge
            border.width: 1.0
            border.color: Qt.alpha(Config.textColor, 0.2)
            clip: true

            transformOrigin: Item.Top

            scale: 0.95 + (root.openProgress * 0.05)
            opacity: root.openProgress

            Behavior on height {
                enabled: root.openProgress >= 1.0
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuad
                }
            }

            Keys.onEscapePressed: root.closeWindow()

            Item {
                id: contentContainer
                anchors.fill: parent
                anchors.margins: 16
                opacity: root.contentOpacity
            }
        }
    }
}
