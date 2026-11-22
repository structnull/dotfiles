pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.config
import qs.services

RowLayout {
    id: root
    spacing: 5

    // Drawer state
    property bool isOpen: false
    property bool menuLoaded: false
    property Item menuAnchor: null
    property var menuItem: null
    readonly property var sharedMenu: menuLoader.active ? menuLoader.item : null

    function openMenu(anchor, trayItem) {
        menuAnchor = anchor;
        menuItem = trayItem;
        if (sharedMenu)
            sharedMenu.open();
        else
            menuLoaded = true;
    }

    LazyLoader {
        id: menuLoader
        active: root.menuLoaded
        onActiveChanged: {
            if (active)
                item.open();
        }
        component: Component {
            TrayMenu {
                anchorItem: root.menuAnchor
                rootMenuHandle: root.menuItem?.menu ?? null
            }
        }
    }

    Connections {
        target: root.sharedMenu

        function onVisibleChanged() {
            if (!root.sharedMenu)
                return;
            if (!root.sharedMenu.visible) {
                root.menuLoaded = false;
                root.menuItem = null;
                root.menuAnchor = null;
            }
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
            textFormat: Text.PlainText
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
                        source: visible ? Quickshell.iconPath("application-default-icon") : ""
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
                            const trayItem = trayDelegate.trayItem;
                            if (mouse.button === Qt.RightButton || trayItem.onlyMenu) {
                                if (trayItem.hasMenu)
                                    root.openMenu(trayDelegate, trayItem);
                            } else {
                                trayItem.activate();
                                root.sharedMenu?.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
