pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Notifications

import qs.config
import qs.services

Item {
    id: root

    // ========================================================================
    // PROPERTIES
    // ========================================================================

    // The notification wrapper (from NotificationService)
    required property var wrapper

    // Popup mode (true) or history mode (false)
    property bool popupMode: false

    // Internal state for exit animation
    property bool isExiting: false
    property bool isCollapsed: false

    // ========================================================================
    // PROPERTIES DERIVED FROM WRAPPER
    // ========================================================================

    readonly property int notifId: wrapper ? wrapper.notifId : -1
    readonly property string summary: wrapper ? wrapper.summary : ""
    readonly property string body: wrapper ? wrapper.body : ""
    readonly property string appName: wrapper ? wrapper.appName : "System"
    readonly property string appIcon: wrapper ? wrapper.appIcon : ""
    readonly property string image: wrapper ? wrapper.image : ""
    readonly property int urgency: wrapper ? wrapper.urgency : 0
    readonly property bool isUrgent: wrapper ? wrapper.isUrgent : false
    readonly property var actions: wrapper ? wrapper.actions : []
    readonly property bool hasActions: wrapper ? wrapper.hasActions : false
    readonly property bool showPopup: wrapper ? wrapper.popup : false
    readonly property string timeStr: !popupMode && wrapper ? wrapper.ageAt(TimeService.date) : ""

    // Keep the original 50 ms visual steps. A continuous property animation
    // otherwise repaints this separate window at the display's refresh rate.
    // The service still owns the native countdown; history never subscribes.
    readonly property real progress: {
        if (!popupMode || !wrapper)
            return 0;
        const steps = Math.max(1, wrapper.totalTime / 50);
        return Math.floor(wrapper.progress * steps) / steps;
    }

    // Check if paused (hover)
    readonly property bool isPaused: wrapper && wrapper.isPaused

    readonly property var defaultAction: actions.find(action => action?.identifier === "default") ?? null
    readonly property var visibleActions: actions.filter(action => action && action.identifier !== "default")

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (root.popupMode) {
                if (hovered)
                    NotificationService.setHovered(root.notifId);
                else if (NotificationService.hoveredNotificationId === root.notifId)
                    NotificationService.clearHovered();
            }
        }
    }

    MouseArea {
        width: parent.width
        height: root.visualHeight
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.startExitAnimation(true);
            else if (root.defaultAction)
                root.defaultAction.invoke();
            else if (root.popupMode)
                root.startExitAnimation(false);
        }
    }

    // ========================================================================
    // DIMENSIONS
    // ========================================================================

    readonly property int visualHeight: contentColumn.implicitHeight + 24
    implicitWidth: Config.notifWidth

    implicitHeight: {
        if (isCollapsed)
            return 0;
        if (popupMode && !showPopup)
            return 0;
        if (!wrapper)
            return 0;
        return visualHeight + Config.notifSpacing;
    }

    visible: !isCollapsed && (popupMode ? showPopup : true) && opacity > 0 && wrapper !== null

    // ========================================================================
    // VISUAL
    // ========================================================================

    // Container with clipping
    Rectangle {
        id: clippedContainer
        width: parent.width
        height: root.visualHeight
        visible: root.wrapper !== null
        radius: Config.radiusLarge
        clip: true
        color: "transparent"

        // Background
        Rectangle {
            anchors.fill: parent
            color: Config.backgroundTransparentColor
        }

        // Progress bar (only in popup mode)
        Rectangle {
            visible: root.popupMode
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            height: 3
            width: parent.width * (1.0 - root.progress)
            color: root.isUrgent ? Config.errorColor : Config.accentColor
        }

        // Content
        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            anchors.rightMargin: root.popupMode ? 38 : 12
            spacing: 8

            // Main row: Icon + Text
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Icon / Image
                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    Layout.alignment: Qt.AlignTop
                    radius: width / 2
                    clip: true
                    color: root.isUrgent ? Qt.alpha(Config.errorColor, 0.2) : Config.surface1Color

                    Image {
                        id: notifImage
                        anchors.fill: parent
                        anchors.margins: root.image !== "" ? 0 : 8
                        fillMode: Image.PreserveAspectCrop

                        asynchronous: true
                        smooth: true
                        sourceSize: Qt.size(128, 128)

                        source: NotificationService.getIconSource(root.appIcon, root.image)


                    }

                    // Fallback icon if there is no image
                    Text {
                        textFormat: Text.PlainText
                        visible: notifImage.status === Image.Error || (notifImage.source + "") === ""
                        anchors.centerIn: parent
                        text: "󰍡"
                        font.family: Config.font
                        font.pixelSize: 20
                        color: Config.subtextColor
                    }
                }

                // Texts
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    // Header: Title + App Name + Time
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Text {
                            text: root.summary
                            color: Config.textColor
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }

                        Text {
                            textFormat: Text.PlainText
                            text: root.appName
                            color: root.isUrgent ? Config.errorColor : Config.accentColor
                            font.family: Config.font
                            font.pixelSize: 10
                            font.bold: true
                            opacity: 0.8
                        }
                    }

                    // Time (only in history)
                    Text {
                        textFormat: Text.PlainText
                        visible: !root.popupMode && root.timeStr !== ""
                        text: root.timeStr
                        color: Config.subtextColor
                        font.family: Config.font
                        font.pixelSize: 10
                        opacity: 0.7
                    }

                    // Notification body
                    Text {
                        text: root.body
                        color: Config.subtextColor
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        visible: text !== ""
                        textFormat: Text.StyledText
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
            }
            Flow {
                Layout.fillWidth: true
                visible: root.visibleActions.length > 0
                spacing: 6

                Repeater {
                    model: root.visibleActions
                    delegate: Button {
                        required property NotificationAction modelData
                        text: modelData?.text || "Open"
                        onClicked: modelData?.invoke()
                    }
                }
            }
        }

    }

    // Outer border (hover state)
    Rectangle {
        width: parent.width
        height: root.visualHeight
        radius: Config.radiusLarge
        color: "transparent"
        border.width: 1
        border.color: {
            if (root.isUrgent)
                return Config.errorColor;
            if (hover.hovered)
                return Config.surface2Color;
            return "transparent";
        }
    }

    Rectangle {
        id: closeButton
        visible: root.popupMode
        width: 22
        height: 22
        radius: 11
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.rightMargin: 8
        color: closeMouseArea.containsMouse ? Config.surface2Color : Qt.alpha(Config.surface1Color, 0.8)
        z: 3

        Behavior on color {
            ColorAnimation {
                duration: Config.animDurationShort
            }
        }

        Text {
            textFormat: Text.PlainText
            anchors.centerIn: parent
            text: "󰅖"
            font.family: Config.font
            font.pixelSize: 11
            color: Config.textColor
        }

        MouseArea {
            id: closeMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                mouse.accepted = true;
                root.startExitAnimation(true);
            }
        }
    }

    // ========================================================================
    // EXIT ANIMATION
    // ========================================================================

    function startExitAnimation(removeCompletely) {
        if (isExiting)
            return;
        isExiting = true;
        exitAnim.removeCompletely = removeCompletely;
        exitAnim.start();
    }

    SequentialAnimation {
        id: exitAnim
        property bool removeCompletely: false

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: Config.animDuration
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "x"
                to: 50
                duration: Config.animDuration
                easing.type: Easing.InQuad
            }
        }

        ScriptAction {
            script: root.isCollapsed = true
        }

        PauseAnimation {
            duration: Config.animDuration
        }

        ScriptAction {
            script: {
                const id = root.notifId;

                if (exitAnim.removeCompletely) {
                    NotificationService.removeNotification(id);
                } else {
                    NotificationService.expireNotification(id);
                }

                root.opacity = 1;
                root.x = 0;
                root.isCollapsed = false;
                root.isExiting = false;
            }
        }
    }
}
