pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services

Item {
    id: root

    property int maxWidth: 400
    readonly property int horizontalPadding: Config.padding
    readonly property int iconBoxWidth: 14

    readonly property var activeToplevel: Hyprland.activeToplevel
    readonly property var hostMonitor: QsWindow.window?.screen ? Hyprland.monitorFor(QsWindow.window.screen) : null
    readonly property bool windowExists: activeToplevel !== null
        && (!hostMonitor || activeToplevel.workspace === hostMonitor.activeWorkspace)
    property bool specialWorkspaceActive: false
    property string specialWorkspaceMonitor: ""
    readonly property bool specialWorkspaceFocused: {
        const workspace = Hyprland.activeToplevel?.workspace;
        const workspaceName = workspace?.name ?? "";
        const activeFromWindow = workspaceName.startsWith("special:") || (workspace?.id ?? 0) < 0;
        const activeFromEvent = specialWorkspaceActive && (specialWorkspaceMonitor === "" || specialWorkspaceMonitor === Hyprland.focusedMonitor?.name);
        return activeFromWindow || activeFromEvent;
    }

    readonly property string windowTitle: specialWorkspaceFocused ? "" : (Hyprland.activeToplevel?.title ?? "")
    readonly property bool showingLayout: LayoutService.visible
    readonly property bool showingWindowInfo: windowExists && !specialWorkspaceFocused && !showingLayout

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecial") {
                const parts = (event.data ?? "").split(",");
                root.specialWorkspaceActive = (parts[0] ?? "") !== "";
                root.specialWorkspaceMonitor = parts[1] ?? "";
            }
        }
    }

    implicitWidth: showingLayout || showingWindowInfo ? Math.min(content.implicitWidth + (horizontalPadding * 2), maxWidth) : 0
    implicitHeight: Math.max(content.implicitHeight, Config.fontSizeNormal + 6)

    visible: opacity > 0
    opacity: showingLayout || showingWindowInfo ? 1.0 : 0.0

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
            textFormat: Text.PlainText
            text: root.windowTitle !== "" ? "" : ""
            visible: !root.showingLayout
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

        LayoutIndicator {
            visible: root.showingLayout
            Layout.preferredWidth: implicitWidth
            Layout.preferredHeight: implicitHeight
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            textFormat: Text.PlainText
            id: titleText
            text: root.windowTitle
            visible: !root.showingLayout
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
