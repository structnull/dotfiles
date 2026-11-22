pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: root

    visible: PolkitService.isActive

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.namespace: "qs_polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    color: "transparent"

    // =========================================================================
    // STATE
    // =========================================================================

    readonly property var flow: PolkitService.flow
    property string password: ""

    // Shake animation state
    property real shakeOffset: 0

    // =========================================================================
    // FLOW WATCHERS
    // =========================================================================

    Connections {
        target: root.flow ?? null
        enabled: root.flow !== null

        function onFailedChanged() {
            if (root.flow && root.flow.failed) {
                root.password = "";
                shakeAnim.restart();
            }
        }

        function onInputPromptChanged() { root.resetResponse(); }
        function onIsResponseRequiredChanged() { root.resetResponse(); }
    }

    onFlowChanged: resetResponse()
    onWindowConnected: resetResponse()

    function resetResponse() {
        password = "";
        if (visible && flow?.isResponseRequired)
            Qt.callLater(passwordInput.forceActiveFocus);
    }

    // Shake animation on auth failure
    SequentialAnimation {
        id: shakeAnim

        NumberAnimation {
            target: root
            property: "shakeOffset"
            to: -12
            duration: 50
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "shakeOffset"
            to: 12
            duration: 50
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "shakeOffset"
            to: -8
            duration: 50
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "shakeOffset"
            to: 8
            duration: 50
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "shakeOffset"
            to: 0
            duration: 60
            easing.type: Easing.OutQuad
        }
    }

    // =========================================================================
    // BACKGROUND OVERLAY
    // =========================================================================

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Config.backgroundColor, 0.65)

        opacity: root.visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuad
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.flow)
                    root.flow.cancelAuthenticationRequest();
            }
        }
    }

    // =========================================================================
    // DIALOG CARD
    // =========================================================================

    Rectangle {
        id: dialogCard

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.shakeOffset

        width: 400
        height: dialogContent.implicitHeight + 48

        radius: Config.radiusLarge
        color: Config.surface0Color
        border.width: 1
        border.color: Config.surface2Color

        scale: root.visible ? 1.0 : 0.92
        opacity: root.visible ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutQuint
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuint
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Config.animDuration
            }
        }

        // Prevent clicks from reaching background MouseArea
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: dialogContent

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 24
            }
            spacing: 16

            // ── Shield icon ──────────────────────────────────────────
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                radius: 28
                color: Qt.alpha(Config.accentColor, 0.15)

                Behavior on color {
                    ColorAnimation { duration: Config.animDuration }
                }

                Text {
                    textFormat: Text.PlainText
                    anchors.centerIn: parent
                    text: "󰌾"
                    font.family: Config.font
                    font.pixelSize: 26
                    color: Config.accentColor

                    Behavior on color {
                        ColorAnimation { duration: Config.animDuration }
                    }
                }
            }

            // ── Title ────────────────────────────────────────────────
            Text {
                textFormat: Text.PlainText
                Layout.alignment: Qt.AlignHCenter
                text: "Authentication Required"
                font.family: Config.font
                font.pixelSize: Config.fontSizeLarge
                font.bold: true
                color: Config.textColor

                Behavior on color {
                    ColorAnimation { duration: Config.animDuration }
                }
            }

            // ── Message ──────────────────────────────────────────────
            Text {
                textFormat: Text.PlainText
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.flow ? root.flow.message : ""
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
                color: Config.subtextColor
                wrapMode: Text.WordWrap
                visible: text !== ""
            }

            // ── Action ID ────────────────────────────────────────────
            Text {
                textFormat: Text.PlainText
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.flow ? root.flow.actionId : ""
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                color: Qt.alpha(Config.subtextColor, 0.6)
                wrapMode: Text.WordWrap
                visible: text !== ""
                elide: Text.ElideMiddle
            }

            // ── Supplementary message ────────────────────────────────
            Text {
                textFormat: Text.PlainText
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.flow ? (root.flow.supplementaryMessage ?? "") : ""
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                color: (root.flow && root.flow.supplementaryIsError) ? Config.errorColor : Config.subtextColor
                wrapMode: Text.WordWrap
                visible: text !== ""
            }

            // ── Password input ───────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: root.flow ? root.flow.isResponseRequired : false

                // Prompt label
                Text {
                    textFormat: Text.PlainText
                    text: root.flow ? (root.flow.inputPrompt ?? "Password:") : "Password:"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    color: Config.subtextColor
                }

                Rectangle {
                    id: inputContainer

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: Config.radius
                    color: Config.surface1Color
                    border.width: 2
                    border.color: passwordInput.activeFocus ? Config.accentColor : Config.surface2Color

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Config.animDurationShort
                        }
                    }

                    TextInput {
                        id: passwordInput

                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 12
                        }
                        verticalAlignment: TextInput.AlignVCenter

                        text: root.password
                        onTextChanged: root.password = text

                        echoMode: (root.flow && root.flow.responseVisible) ? TextInput.Normal : TextInput.Password
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        color: Config.textColor
                        selectionColor: Config.accentColor
                        selectedTextColor: Config.textReverseColor
                        clip: true

                        Keys.onReturnPressed: root.submitPassword()
                        Keys.onEnterPressed: root.submitPassword()
                        Keys.onEscapePressed: {
                            if (root.flow)
                                root.flow.cancelAuthenticationRequest();
                        }
                    }

                    // Placeholder
                    Text {
                        textFormat: Text.PlainText
                        anchors {
                            left: parent.left
                            leftMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        text: "Enter password…"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        color: Qt.alpha(Config.subtextColor, 0.4)
                        visible: passwordInput.text === "" && !passwordInput.activeFocus
                    }
                }
            }

            // ── Buttons ──────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: Config.spacing

                // Cancel button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: Config.radius
                    color: cancelMouse.containsMouse ? Config.surface3Color : Config.surface2Color

                    Behavior on color {
                        ColorAnimation { duration: Config.animDurationShort }
                    }

                    scale: cancelMouse.pressed ? 0.97 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 80 }
                    }

                    Text {
                        textFormat: Text.PlainText
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        font.weight: Font.DemiBold
                        color: Config.textColor
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.flow)
                                root.flow.cancelAuthenticationRequest();
                        }
                    }
                }

                // Authenticate button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: Config.radius
                    color: authMouse.containsMouse ? Qt.lighter(Config.accentColor, 1.15) : Config.accentColor

                    Behavior on color {
                        ColorAnimation { duration: Config.animDurationShort }
                    }

                    scale: authMouse.pressed ? 0.97 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 80 }
                    }

                    Text {
                        textFormat: Text.PlainText
                        anchors.centerIn: parent
                        text: "Authenticate"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        font.weight: Font.DemiBold
                        color: Config.textReverseColor
                    }

                    MouseArea {
                        id: authMouse
                        enabled: !!root.flow?.isResponseRequired
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submitPassword()
                    }
                }
            }

            // ── Keyboard hint ────────────────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Repeater {
                    model: [
                        { key: "Enter", label: "Submit" },
                        { key: "Esc", label: "Cancel" }
                    ]

                    Row {
                        required property var modelData
                        spacing: 4

                        Rectangle {
                            width: hintKeyText.implicitWidth + 8
                            height: 18
                            radius: 4
                            color: Config.surface1Color
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                textFormat: Text.PlainText
                                id: hintKeyText
                                anchors.centerIn: parent
                                text: modelData.key
                                font.family: Config.font
                                font.pixelSize: 9
                                font.bold: true
                                color: Config.subtextColor
                            }
                        }

                        Text {
                            textFormat: Text.PlainText
                            text: modelData.label
                            font.family: Config.font
                            font.pixelSize: 10
                            color: Config.mutedColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // FUNCTIONS
    // =========================================================================

    function submitPassword() {
        if (!flow?.isResponseRequired || password === "")
            return;
        const response = password;
        password = "";
        flow.submit(response);
    }

    onVisibleChanged: resetResponse()
}
