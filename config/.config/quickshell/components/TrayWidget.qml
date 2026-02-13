pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

RowLayout {
    id: root
    spacing: 5

    // Drawer state
    property bool isOpen: false
    // We create the TrayMenu object here, but it starts invisible.
    TrayMenu {
        id: sharedMenu
        visible: false

        onVisibleChanged: {
            if (visible)
                TrayService.registerActiveMenu(sharedMenu);
        }
    }

    // Toggle button
    Rectangle {
        id: toggleBtn

        visible: true
        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        radius: 8

        color: (toggleMouse.containsMouse || root.isOpen) ? Qt.rgba(1, 1, 1, root.isOpen ? 0.14 : 0.09) : "transparent"
        border.width: (toggleMouse.containsMouse || root.isOpen) ? 1 : 0
        border.color: (toggleMouse.containsMouse || root.isOpen) ? Qt.rgba(1, 1, 1, 0.26) : "transparent"
        opacity: 1

        Behavior on color {
            ColorAnimation {
                duration: Config.animDuration
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: Config.animDuration
            }
        }
        Behavior on border.width {
            NumberAnimation {
                duration: Config.animDurationShort
            }
        }

        // Arrow Icon
        Text {
            anchors.centerIn: parent
            text: "󰅁"
            font.family: Config.font
            font.pixelSize: Config.fontSizeIconSmall
            color: Config.textColor

            scale: root.isOpen ? -1 : 1

            Behavior on scale {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutBack
                }
            }
        }


        MouseArea {
            id: toggleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.isOpen = !root.isOpen
        }
    }

    Item {
        id: drawer

        clip: true

        Layout.preferredHeight: 30
        Layout.preferredWidth: root.isOpen ? (iconsRow.implicitWidth + 5) : 0

        Behavior on Layout.preferredWidth {
            NumberAnimation {
                duration: Config.animDurationLong
                easing.type: Easing.OutExpo
            }
        }

        opacity: root.isOpen ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Config.animDuration
            }
        }

        // Drawer content
        Row {
            id: iconsRow
            spacing: 3
            anchors.verticalCenter: parent.verticalCenter

            anchors.left: parent.left
            anchors.leftMargin: root.isOpen ? 5 : -iconsRow.implicitWidth

            Behavior on anchors.leftMargin {
                NumberAnimation {
                    duration: Config.animDurationLong
                    easing.type: Easing.OutExpo
                }
            }

            Repeater {
                id: trayRepeater
                model: TrayService.itemsModel

                delegate: Rectangle {
                    id: trayDelegate
                    required property var modelData
                    readonly property var trayItem: modelData

                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 8
                    color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : "transparent"
                    border.width: mouseArea.containsMouse ? 1 : 0
                    border.color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.26) : "transparent"
                    visible: !!trayItem

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                    Behavior on border.color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                    Behavior on border.width {
                        NumberAnimation {
                            duration: Config.animDurationShort
                        }
                    }

                    // Primary icon (theme name, file path, or pixmap URL)
                    Image {
                        id: trayIcon
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: TrayService.getIconSource(trayDelegate.trayItem ? trayDelegate.trayItem.icon : "")
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        sourceSize: Qt.size(32, 32)
                        smooth: true
                        visible: status === Image.Ready
                    }

                    // Fallback when primary icon fails (e.g. pixmap-based icons from nm-applet)
                    Image {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: "image://icon/application-default-icon"
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(32, 32)
                        smooth: true
                        visible: trayIcon.status === Image.Error
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor

                        onClicked: mouse => {
                            if (!trayDelegate.trayItem)
                                return;
                            if (mouse.button === Qt.LeftButton) {
                                trayDelegate.trayItem.activate();
                                sharedMenu.close();
                            } else if (mouse.button === Qt.RightButton) {
                                if (trayDelegate.trayItem.hasMenu) {
                                    // 1. Gets the absolute position of the icon on screen
                                    var globalPos = trayDelegate.mapToGlobal(0, trayDelegate.height);

                                    // 2. Configures the shared menu
                                    sharedMenu.rootMenuHandle = trayDelegate.trayItem.menu;
                                    sharedMenu.anchorX = globalPos.x;
                                    sharedMenu.anchorY = globalPos.y + 5;

                                    // 3. Opens the menu
                                    sharedMenu.open();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
