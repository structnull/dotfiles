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

    // Properties received when opening
    property QsMenuHandle rootMenuHandle: null
    property Item anchorItem: null
    readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
    readonly property point anchorPosition: {
        if (!anchorItem)
            return Qt.point(0, 0);
        // mapToGlobal itself does not track window or item movement.
        const position = anchorWindow?.windowTransform;
        const x = anchorItem.x;
        const y = anchorItem.y;
        return anchorItem.mapToGlobal(0, anchorItem.height);
    }
    property bool isClosing: false
    property real openProgress: 0.0

    // --- WINDOW CONFIGURATION ---
    color: "transparent"
    visible: false
    screen: anchorWindow?.screen ?? Quickshell.screens[0] ?? null
    onAnchorItemChanged: { if (!anchorItem) close(); }
    onRootMenuHandleChanged: { if (!rootMenuHandle) close(); }
    onVisibleChanged: {
        if (visible)
            TrayService.registerActiveMenu(root);
        else
            TrayService.unregisterActiveMenu(root);
    }

    // Size
    implicitWidth: Math.max(1, Math.min(220, (screen?.width ?? 1920) - 10))
    implicitHeight: Math.min(mainColumn.implicitHeight + 2 * frameInset, Math.max(1, (screen?.height ?? 1080) - 10))
    readonly property int frameInset: 2

    WlrLayershell.namespace: "qs_modules"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: -1

    // Positions where the mouse clicked (or icon)
    anchors {
        left: true
        top: true
    }
    margins {
        left: Math.max(5, Math.min((screen?.width ?? implicitWidth) - implicitWidth - 5, anchorPosition.x - (screen?.x ?? 0)))
        top: Math.max(5, Math.min((screen?.height ?? implicitHeight) - implicitHeight - 5, anchorPosition.y - (screen?.y ?? 0) + 5))
    }

    property list<QsMenuEntry> menuStack: []
    readonly property QsMenuHandle currentMenuHandle: menuStack.length > 0
        ? menuStack[menuStack.length - 1] : rootMenuHandle

    function popSubMenu() {
        if (menuStack.length > 0) {
            menuStack.pop();
            menuViewport.contentY = 0;
        }
    }

    // --- FOCUS AND CLOSING ---
    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        active: false
        onCleared: root.close()
    }

    function open() {
        if (!rootMenuHandle || !anchorItem)
            return;
        menuViewport.contentY = 0;
        menuStack = [];
        isClosing = false;
        closeAnimation.stop();
        openProgress = 0;
        root.visible = true;
        openAnimation.restart();
        focusTimer.restart();
    }

    function close() {
        if (!root.visible || isClosing)
            return;

        isClosing = true;
        openAnimation.stop();
        closeAnimation.restart();
    }

    NumberAnimation {
        id: openAnimation
        target: root
        property: "openProgress"
        from: 0
        to: 1
        duration: Config.animDurationLong
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnimation
        target: root
        property: "openProgress"
        to: 0
        duration: Config.animDuration
        easing.type: Easing.InCubic
        onFinished: {
            if (!root.isClosing)
                return;

            root.visible = false;
            menuStack = []; // Resets navigation on close
            focusGrab.active = false;
            root.isClosing = false;
        }
    }

    Timer {
        id: focusTimer
        interval: 50
        onTriggered: {
            focusGrab.active = true;
            background.forceActiveFocus();
        }
    }

    // The object that reads the items of the current menu
    QsMenuOpener {
        id: menuOpener
        menu: root.currentMenuHandle
    }

    // --- VISUALS ---
    Rectangle {
        id: background
        anchors.fill: parent
        color: Config.backgroundTransparentColor
        border.color: Config.surface2Color
        border.width: 1
        radius: Config.radius
        clip: true
        transformOrigin: Item.Top

        scale: 0.97 + (root.openProgress * 0.03)
        opacity: root.openProgress

        focus: true
        Keys.onEscapePressed: {
            if (menuStack.length > 0)
                popSubMenu();
            else
                root.close();
        }

        Flickable {
            id: menuViewport
            anchors.fill: parent
            anchors.margins: root.frameInset
            contentWidth: width
            contentHeight: mainColumn.implicitHeight
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: mainColumn
                width: parent.width
                spacing: 0

                // --- HEADER / BACK ---
                // Only appears if we are inside a submenu
                Rectangle {
                    visible: menuStack.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: backMouse.containsMouse ? Config.surface1Color : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 5
                        Text {
                            textFormat: Text.PlainText
                            text: "⬅ Back"
                            color: Config.accentColor
                            font.family: Config.font
                            font.bold: true
                            font.pixelSize: Config.fontSizeSmall
                        }
                    }
                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: popSubMenu()
                    }
                }

                // Divider if there is a back button
                Rectangle {
                    visible: menuStack.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Config.surface2Color
                }

                // --- ITEMS LIST ---
                Repeater {
                    model: menuOpener.children

                    delegate: Rectangle {
                        id: itemDelegate

                        required property QsMenuEntry modelData

                        // Helpers
                        readonly property bool isSeparator: modelData?.isSeparator ?? false
                        readonly property bool isEnabled: modelData?.enabled ?? false
                        readonly property bool hasSubMenu: modelData?.hasChildren ?? false

                        Layout.fillWidth: true
                        Layout.preferredHeight: isSeparator ? 6 : 32
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                        color: itemMouse.containsMouse && !isSeparator ? Config.surface1Color : "transparent"
                        radius: Config.radius
                        opacity: isEnabled ? 1.0 : 0.5

                        // Separator
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 10
                            height: 1
                            color: Config.surface2Color
                            visible: parent.isSeparator
                        }

                        // Item Content
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10
                            visible: !parent.isSeparator

                            // Icon (resolved via TrayService to handle theme names, pixmaps, and file paths)
                            Image {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                source: itemDelegate.modelData ? itemDelegate.modelData.icon : ""
                                visible: source !== "" && status === Image.Ready
                                sourceSize: Qt.size(16, 16)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                            }

                            // Checkbox
                            Rectangle {
                                Layout.preferredWidth: 10
                                Layout.preferredHeight: 10
                                radius: itemDelegate.modelData?.buttonType === QsMenuButtonType.RadioButton ? 5 : 2
                                color: "transparent"
                                border.color: Config.textColor
                                visible: itemDelegate.modelData && itemDelegate.modelData.buttonType !== QsMenuButtonType.None
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 6
                                    height: itemDelegate.modelData?.checkState === Qt.PartiallyChecked ? 2 : 6
                                    visible: itemDelegate.modelData?.checkState !== Qt.Unchecked
                                    radius: Math.max(0, parent.radius - 1)
                                    color: Config.textColor
                                }
                            }

                            // Text
                            Text {
                                textFormat: Text.PlainText
                                text: (itemDelegate.modelData?.text ?? "").replace(/&&|&/g, marker => marker === "&&" ? "&" : "")
                                color: Config.textColor
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // Submenu Arrow
                            Text {
                                textFormat: Text.PlainText
                                visible: itemDelegate.hasSubMenu
                                text: "›"
                                color: Config.subtextColor
                                font.pixelSize: 14
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: !parent.isSeparator && parent.isEnabled
                            enabled: hoverEnabled
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                const entry = itemDelegate.modelData;
                                if (itemDelegate.hasSubMenu) {
                                    root.menuStack.push(entry);
                                    menuViewport.contentY = 0;
                                } else {
                                    entry.triggered();
                                    root.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
