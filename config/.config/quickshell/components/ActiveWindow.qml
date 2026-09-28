pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.config

Item {
    id: root

    property int maxWidth: 400
    readonly property int horizontalPadding: Config.padding
    readonly property int iconBoxWidth: 14

    // Internal state to force clearing
    property bool windowExists: Hyprland.activeToplevel !== null
    property bool specialWorkspaceActive: false
    property string specialWorkspaceMonitor: ""
    property string pendingWorkspaceName: ""
    readonly property bool specialWorkspaceFocused: {
        const workspace = Hyprland.activeToplevel?.workspace;
        const workspaceName = workspace?.name ?? "";
        const activeFromWindow = workspaceName.startsWith("special:") || (workspace?.id ?? 0) < 0;
        const activeFromEvent = specialWorkspaceActive && (specialWorkspaceMonitor === "" || specialWorkspaceMonitor === Hyprland.focusedMonitor?.name);
        return activeFromWindow || activeFromEvent;
    }

    readonly property string windowTitle: specialWorkspaceFocused ? "" : (Hyprland.activeToplevel?.title ?? "")

    Timer {
        id: workspaceFocusRefresh
        interval: 75
        repeat: false
        onTriggered: {
            const activeWindow = Hyprland.activeToplevel;
            root.windowExists = activeWindow !== null && activeWindow.workspace?.name === root.pendingWorkspaceName;
        }
    }

    // Logic to verify focus changes
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            // "activewindowv2" is sent even when clicking the desktop (returns empty)
            if (event.name === "activewindowv2") {
                // If the address is empty, no window is focused
                root.windowExists = event.data !== "," && event.data !== "";
            }

            if (event.name === "activespecial") {
                const parts = (event.data ?? "").split(",");
                root.specialWorkspaceActive = (parts[0] ?? "") !== "";
                root.specialWorkspaceMonitor = parts[1] ?? "";
            }

            // Clear immediately when changing workspaces. Hyprland can briefly
            // keep reporting the previous active toplevel until the new focus
            // event arrives.
            if (event.name === "workspace") {
                root.windowExists = false;
                root.pendingWorkspaceName = event.data ?? "";
                workspaceFocusRefresh.restart();
            }
        }
    }

    implicitWidth: windowExists && !specialWorkspaceFocused ? Math.min(content.implicitWidth + (horizontalPadding * 2), maxWidth) : 0
    implicitHeight: content.implicitHeight

    visible: opacity > 0
    opacity: windowExists && !specialWorkspaceFocused ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: Config.animDuration
        }
    }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        id: content
        spacing: 5
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }

        Text {
            text: root.windowTitle !== "" ? "" : ""
            color: Config.textColor
            style: Text.Outline
            styleColor: Qt.alpha(Config.backgroundColor, 0.85)
            font.family: Config.font
            font.pixelSize: Config.fontSizeSmall
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            Layout.preferredWidth: root.iconBoxWidth
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: titleText
            text: root.windowTitle
            color: Config.textColor
            style: Text.Outline
            styleColor: Qt.alpha(Config.backgroundColor, 0.85)
            font.family: Config.font
            font.pixelSize: Config.fontSizeNormal
            elide: Text.ElideRight

            Layout.fillWidth: true
            Layout.maximumWidth: Math.max(0, root.maxWidth - (root.horizontalPadding * 2) - root.iconBoxWidth - content.spacing)
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
