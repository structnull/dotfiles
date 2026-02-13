pragma Singleton
import QtQuick
import Quickshell.Services.SystemTray

QtObject {
    id: root

    // Docs v0.2.1: SystemTray.items is ObjectModel<SystemTrayItem>.
    // Use .values for a reactive list in normal QML bindings/repeaters.
    readonly property var items: SystemTray.items.values
    readonly property var itemsModel: SystemTray.items

    // Checks whether there are items in the tray.
    readonly property int itemCount: (items && typeof items.length === "number") ? items.length : 0
    readonly property bool hasItems: itemCount > 0

    // --- ICON LOGIC ---
    function getIconSource(iconString) {
        if (!iconString)
            return "image://icon/image-missing";
        // Docs v0.2.1: SystemTrayItem.icon can be used directly as an Image source.
        return iconString;
    }

    // Resolves menu item icon source, returning empty string for missing icons
    function getMenuIconSource(iconString) {
        if (!iconString || iconString === "")
            return "";
        return getIconSource(iconString);
    }

    // Keeps reference to the currently open menu to ensure only 1 exists in the entire system
    property var activeMenu: null

    function registerActiveMenu(menuInstance) {
        if (activeMenu && activeMenu !== menuInstance) {
            // If there is already an open menu and we try to open another, close the previous one
            if (typeof activeMenu.close === "function") {
                activeMenu.close();
            } else {
                activeMenu.visible = false;
            }
        }
        activeMenu = menuInstance;
    }
}
