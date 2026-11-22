pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import "../../../components/"

Item {
    id: root

    Layout.fillWidth: true

    implicitHeight: 350

    // Received properties
    property string targetSsid: ""
    property string errorText: ""

    signal cancelled
    signal connectClicked(string password)

    // Intercept background clicks to remove input focus when clicking outside
    MouseArea {
        anchors.fill: parent
        onClicked: parent.forceActiveFocus()
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.85 // Takes 85% of the window width
        spacing: 20

        // --- Highlight Icon ---
        Text {
            textFormat: Text.PlainText
            text: ""
            font.family: Config.font
            font.pixelSize: 48
            color: Config.accentColor
            Layout.alignment: Qt.AlignHCenter
        }

        // --- Titles ---
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 5

            Text {
                textFormat: Text.PlainText
                text: "Password Required"
                color: Config.subtextColor
                font.pixelSize: Config.fontSizeNormal
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                textFormat: Text.PlainText
                text: root.targetSsid
                color: Config.textColor
                font.bold: true
                font.pixelSize: Config.fontSizeLarge
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.width
            }
        }

        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.errorText
            textFormat: Text.PlainText
            color: Config.errorColor
            wrapMode: Text.Wrap
        }

        // --- Password Field ---
        TextField {
            id: passInput
            Layout.fillWidth: true
            Layout.preferredHeight: 45

            placeholderText: "Enter network password..."
            placeholderTextColor: Qt.alpha(Config.subtextColor, 0.5)

            color: Config.textColor
            font.family: Config.font
            font.pixelSize: Config.fontSizeNormal

            verticalAlignment: TextInput.AlignVCenter
            leftPadding: 15
            rightPadding: 40 // Space for the eye icon

            echoMode: showPassToggle.checked ? TextInput.Normal : TextInput.Password
            passwordCharacter: "•"

            background: Rectangle {
                color: Config.surface1Color
                radius: Config.radius
                border.width: 1
                border.color: passInput.activeFocus ? Config.accentColor : Config.surface2Color

                // Smooth border animation on focus
                Behavior on border.color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            // Show/Hide Password Button (Eye)
            Text {
                textFormat: Text.PlainText
                id: eyeIcon
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter

                text: showPassToggle.checked ? "" : "" // NerdFont icons (eye open/closed)
                font.family: Config.font
                font.pixelSize: 16
                color: showPassHover.containsMouse ? Config.textColor : Config.subtextColor

                MouseArea {
                    id: showPassHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: showPassToggle.checked = !showPassToggle.checked
                }
            }

            // Invisible state control for the toggle
            Item {
                id: showPassToggle
                property bool checked: false
            }

            // Request focus on open
            onVisibleChanged: if (visible)
                forceActiveFocus()

            // Enter connects
            onAccepted: {
                if (text.length > 0) {
                    const password = text;
                    text = "";
                    showPassToggle.checked = false;
                    root.connectClicked(password);
                }
            }
        }

        // --- Action Buttons ---
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10
            spacing: 15

            // Cancel Button
            ClearButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                icon: "󰜺"
                text: "Cancel"
                baseColor: Config.subtextColor

                onClicked: {
                    passInput.text = "";
                    showPassToggle.checked = false;
                    root.cancelled();
                }
            }

            // Connect Button
            ActionButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                icon: ""
                text: "Connect"
                size: 40
                baseColor: Config.accentColor
                hoverColor: Qt.darker(Config.accentColor, 1.1)
                textColor: Config.textReverseColor
                hoverTextColor: Config.textReverseColor
                enabled: passInput.text.length > 0
                opacity: enabled ? 1.0 : 0.5

                onClicked: {
                    const password = passInput.text;
                    passInput.text = "";
                    showPassToggle.checked = false;
                    root.connectClicked(password);
                }
            }
        }
    }
}
