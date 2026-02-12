pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services

PanelWindow {
    id: root

    property int popupWidth: 380
    property int popupMaxHeight: 700
    property Item anchorItem: null
    property string anchorSide: "left"
    property string moduleName: ""
    property real contentImplicitHeight: 0
    property real resolvedLeftMargin: 10
    property real resolvedTopMargin: Config.barHeight + 10

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

    function recalculatePosition() {
        const screenWidth = screen ? screen.width : 1920;
        const screenHeight = screen ? screen.height : 1080;

        let centerX = 0;
        let popupTop = Config.barHeight + 10;

        if (anchorItem) {
            const centerPos = anchorItem.mapToGlobal(anchorItem.width / 2, anchorItem.height);
            const bottomPos = anchorItem.mapToGlobal(0, anchorItem.height);
            centerX = centerPos.x;
            popupTop = bottomPos.y + 8;
        } else if (anchorSide === "right") {
            centerX = screenWidth - ((popupWidth / 2) + 10);
        } else {
            centerX = (popupWidth / 2) + 10;
        }

        resolvedLeftMargin = Math.max(10, Math.min(screenWidth - popupWidth - 10, centerX - (popupWidth / 2)));
        resolvedTopMargin = Math.max(0, Math.min(screenHeight - 10, popupTop));
    }

    margins {
        top: resolvedTopMargin
        left: resolvedLeftMargin
        right: 0
    }

    implicitWidth: popupWidth + (screenMargin * 2)
    implicitHeight: popupMaxHeight
    color: "transparent"

    property bool isClosing: false
    property bool isOpening: false

    function closeWindow() {
        if (!visible)
            return;
        isClosing = true;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: Config.animDuration
        onTriggered: {
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

    Timer {
        id: positionRefreshTimer
        interval: 1
        repeat: false
        onTriggered: root.recalculatePosition()
    }

    onVisibleChanged: {
        if (visible) {
            recalculatePosition();
            positionRefreshTimer.restart();
            isClosing = false;
            isOpening = true;
            if (moduleName !== "")
                WindowManagerService.registerOpen(moduleName);
            grabTimer.restart();
        } else {
            focusGrab.active = false;
            isOpening = false;
            if (moduleName !== "")
                WindowManagerService.registerClose(moduleName);
        }
    }

    onAnchorItemChanged: {
        if (visible)
            positionRefreshTimer.restart();
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: background
            width: root.popupWidth
            height: Math.min(root.popupMaxHeight, root.contentImplicitHeight + 32)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            color: Config.backgroundTransparentColor
            radius: Config.radiusLarge
            border.width: 1.0
            border.color: Config.surface2Color
            clip: true

            transformOrigin: root.anchorSide === "left" ? Item.TopLeft : Item.TopRight

            property bool showState: visible && !root.isClosing && root.isOpening

            scale: showState ? 1.0 : 0.9
            opacity: showState ? 1.0 : 0.0

            Behavior on scale {
                NumberAnimation {
                    duration: Config.animDurationLong
                    easing.type: Easing.OutExpo
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animDurationShort
                }
            }

            Behavior on height {
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
            }
        }
    }
}
