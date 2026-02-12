pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config

Item {
    id: root

    // --- Sizing Properties ---
    readonly property int itemWidth: 20
    readonly property int itemHeight: 18
    readonly property int activeWidth: 28
    readonly property int activeHeight: 18
    readonly property int itemSpacing: 2

    function toRoman(value) {
        let num = Math.max(1, Math.floor(value));
        const numerals = [{
                value: 1000,
                symbol: "M"
            }, {
                value: 900,
                symbol: "CM"
            }, {
                value: 500,
                symbol: "D"
            }, {
                value: 400,
                symbol: "CD"
            }, {
                value: 100,
                symbol: "C"
            }, {
                value: 90,
                symbol: "XC"
            }, {
                value: 50,
                symbol: "L"
            }, {
                value: 40,
                symbol: "XL"
            }, {
                value: 10,
                symbol: "X"
            }, {
                value: 9,
                symbol: "IX"
            }, {
                value: 5,
                symbol: "V"
            }, {
                value: 4,
                symbol: "IV"
            }, {
                value: 1,
                symbol: "I"
            }];

        let output = "";
        for (let i = 0; i < numerals.length; i++) {
            while (num >= numerals[i].value) {
                output += numerals[i].symbol;
                num -= numerals[i].value;
            }
        }
        return output;
    }

    // --- Monitor Logic ---
    readonly property var parentWindow: QsWindow.window
    readonly property var parentScreen: parentWindow?.screen ?? null

    property var currentMonitor: {
        if (!Hyprland)
            return null;
        return (parentScreen ? Hyprland.monitorFor(parentScreen) : null) ?? Hyprland.focusedMonitor ?? null;
    }

    readonly property string monitorName: currentMonitor?.name ?? ""
    property var activeWorkspace: currentMonitor?.activeWorkspace ?? null

    // --- Special Workspace Detection ---
    property string manualSpecialName: ""
    readonly property bool isSpecialWorkspace: manualSpecialName !== ""

    readonly property string specialWorkspaceName: {
        if (!isSpecialWorkspace)
            return "";
        return manualSpecialName.startsWith("special:") ? manualSpecialName.substring(8) : manualSpecialName;
    }

    // --- Normal Workspace Math ---
    property int activeId: (activeWorkspace && activeWorkspace.id > 0) ? activeWorkspace.id : 1
    property int monitorOffset: Math.floor((activeId - 1) / 100) * 100
    property var visibleWorkspaceIds: []

    implicitWidth: isSpecialWorkspace ? specialIndicator.width : Math.max(activeWidth, workspaceRow.width)
    implicitHeight: activeHeight + 4

    // --- Special Workspaces Config ---
    readonly property var specialWorkspaces: ({
            "whatsapp": {
                icon: "󰖣",
                color: Config.successColor,
                name: "WhatsApp"
            },
            "spotify": {
                icon: "󰓇",
                color: Config.accentColor,
                name: "Music"
            },
            "magic": {
                icon: "󰀘",
                color: Config.warningColor,
                name: "Magic"
            }
        })

    // --- Cache Logic to prevent flashing ---
    property string cachedIcon: "󰀘"
    property string cachedName: ""
    property color cachedColor: Config.accentColor

    readonly property var currentSpecialConfig: {
        if (!isSpecialWorkspace)
            return null;
        return specialWorkspaces[specialWorkspaceName] ?? {
            icon: "󰀘",
            color: Config.accentColor,
            name: specialWorkspaceName.charAt(0).toUpperCase() + specialWorkspaceName.slice(1)
        };
    }

    // Updates the cache only when there is a valid workspace
    onCurrentSpecialConfigChanged: {
        if (currentSpecialConfig) {
            cachedIcon = currentSpecialConfig.icon;
            cachedName = currentSpecialConfig.name;
            cachedColor = currentSpecialConfig.color;
        }
    }

    // --- Dynamic Workspace List ---
    function updateWorkspaceModel() {
        if (!Hyprland || !Hyprland.workspaces)
            return;

        let ids = [];
        for (let ws of Hyprland.workspaces.values) {
            if (!ws || ws.id <= 0)
                continue;
            const wsOffset = Math.floor((ws.id - 1) / 100) * 100;
            if (wsOffset === monitorOffset)
                ids.push(ws.id);
        }

        if (activeId > 0 && !ids.includes(activeId))
            ids.push(activeId);

        ids.sort((a, b) => a - b);
        visibleWorkspaceIds = ids;
    }

    Component.onCompleted: updateWorkspaceModel()
    onCurrentMonitorChanged: updateWorkspaceModel()
    onMonitorOffsetChanged: updateWorkspaceModel()
    onActiveIdChanged: updateWorkspaceModel()

    Timer {
        id: workspaceUpdateTimer
        interval: 10
        onTriggered: root.updateWorkspaceModel()
    }

    // --- Event Handling ---
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event)
                return;
            if (event.name === "activespecial") {
                let parts = event.data.split(',');
                let wsName = parts[0] || "";
                let targetMonitor = parts[1] || "";
                if (targetMonitor === "" || targetMonitor === root.monitorName) {
                    root.manualSpecialName = wsName;
                }
            }
            if (event.name === "workspace") {
                root.manualSpecialName = "";
                workspaceUpdateTimer.restart();
            }
            const refreshEvents = ["createworkspace", "destroyworkspace", "movewindow", "openwindow", "closewindow"];
            if (refreshEvents.includes(event.name))
                workspaceUpdateTimer.restart();
        }
    }

    // =========================================================================
    // SPECIAL WORKSPACE INDICATOR
    // =========================================================================
    Rectangle {
        id: specialIndicator
        visible: opacity > 0
        anchors.centerIn: parent

        // Opacity depends only on whether the state is special
        opacity: root.isSpecialWorkspace ? (specialHover.hovered ? 0.8 : 1.0) : 0

        scale: root.isSpecialWorkspace ? 1.0 : 0.9
        property int yOffset: root.isSpecialWorkspace ? 0 : 5
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: yOffset

        width: specialContent.width + Config.padding * 3
        height: root.activeHeight
        radius: Config.radius

        color: root.cachedColor
        border.width: 1

        Behavior on opacity {
            NumberAnimation {
                duration: Config.animDurationShort
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Config.animDuration
            }
        }

        Row {
            id: specialContent
            anchors.centerIn: parent
            spacing: Config.padding * 0.8

            Text {
                // Uses the cached icon
                text: root.cachedIcon
                font {
                    family: Config.font
                    pixelSize: Config.fontSizeLarge
                }
                color: Config.textReverseColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                // Uses the cached name
                text: root.cachedName
                font {
                    family: Config.font
                    bold: true
                    pixelSize: Config.fontSizeNormal
                }
                color: Config.textReverseColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        TapHandler {
            onTapped: {
                if (root.specialWorkspaceName)
                    Hyprland.dispatch("togglespecialworkspace " + root.specialWorkspaceName);
            }
        }
        HoverHandler {
            id: specialHover
            cursorShape: Qt.PointingHandCursor
        }
    }

    // =========================================================================
    // NORMAL WORKSPACES LIST
    // =========================================================================
    Item {
        id: workspacesContainer
        visible: !root.isSpecialWorkspace
        opacity: visible ? 1 : 0
        width: workspaceRow.width
        height: parent.height
        anchors.centerIn: parent

        Behavior on opacity {
            NumberAnimation {
                duration: Config.animDuration
            }
        }

        Row {
            id: workspaceRow
            anchors.centerIn: parent
            spacing: root.itemSpacing

            Repeater {
                model: root.visibleWorkspaceIds
                delegate: Item {
                    id: workspaceItem
                    required property var modelData
                    readonly property int workspaceId: Number(modelData)
                    readonly property int displayId: workspaceId - root.monitorOffset
                    readonly property bool isActive: workspaceId === root.activeId
                    width: isActive ? root.activeWidth : root.itemWidth
                    height: isActive ? root.activeHeight : root.itemHeight
                    opacity: !isActive ? (workspaceHover.hovered ? 0.8 : 1.0) : 1

                    Text {
                        anchors.centerIn: parent
                        visible: workspaceItem.isActive
                        text: root.toRoman(workspaceItem.displayId)
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        font.bold: true
                        color: Qt.alpha(Config.accentColor, 0.45)
                        opacity: workspaceItem.isActive ? 1.0 : 0.0
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.toRoman(workspaceItem.displayId)
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        font.bold: workspaceItem.isActive
                        color: workspaceItem.isActive ? Qt.lighter(Config.accentColor, 1.25) : Qt.alpha(Config.textColor, 0.62)
                    }
                    Behavior on width {
                        NumberAnimation {
                            duration: Config.animDurationShort
                        }
                    }
                    Behavior on height {
                        NumberAnimation {
                            duration: Config.animDurationShort
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Config.animDurationShort
                        }
                    }

                    TapHandler {
                        onTapped: {
                            if (!workspaceItem.isActive)
                                Hyprland.dispatch("workspace " + workspaceItem.workspaceId);
                        }
                    }

                    HoverHandler {
                        id: workspaceHover
                        cursorShape: {
                            if (!workspaceItem.isActive)
                                return Qt.PointingHandCursor;
                        }
                    }
                }
            }
        }
    }
}
