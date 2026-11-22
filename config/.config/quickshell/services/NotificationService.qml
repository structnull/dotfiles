pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config
import qs.services

Singleton {
    id: root

    // ========================================================================
    // DND (DO NOT DISTURB)
    // ========================================================================

    property bool dndEnabled: false

    function clearActivePopups() {
        for (const wrapper of popups.slice())
            hidePopup(wrapper);
    }

    function hidePopup(wrapper) {
        if (!wrapper || !wrapper.popup)
            return;
        wrapper.popup = false;
        if (wrapper.notification?.transient)
            wrapper.notification.expire();
    }

    function applyDndState(enabled: bool) {
        if (dndEnabled === enabled)
            return;

        dndEnabled = enabled;
        if (enabled)
            clearActivePopups();
    }

    function syncDndFromState() {
        const persisted = StateService.get("notifications.dnd", dndEnabled);
        applyDndState(persisted);
    }

    function toggleDnd() {
        setDnd(!dndEnabled);
    }

    function setDnd(enabled: bool) {
        applyDndState(enabled);
        StateService.set("notifications.dnd", dndEnabled);
    }

    Component.onCompleted: syncDndFromState()

    Connections {
        target: StateService

        function onStateLoaded() {
            root.syncDndFromState();
        }
    }

    // ========================================================================
    // NOTIFICATION LISTS
    // ========================================================================

    readonly property list<NotifWrapper> records: []
    readonly property list<NotifWrapper> notifications: records.filter(n => n?.notification && !n.notification.transient)
    readonly property list<NotifWrapper> popups: records.filter(n => n?.popup)
    readonly property int maxPopups: 5

    readonly property int count: notifications.length
    readonly property int activePopupCount: popups.length

    property int hoveredNotificationId: -1

    // ========================================================================
    // NOTIFICATION SERVER
    // ========================================================================

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        actionIconsSupported: false
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            const showPopup = !root.dndEnabled && !notif.lastGeneration;
            if (notif.transient && !showPopup)
                return;

            notif.tracked = true;
            const wrapper = notifComponent.createObject(root, {
                popup: showPopup,
                notification: notif
            });
            if (!wrapper) {
                notif.tracked = false;
                return;
            }

            root.records.unshift(wrapper);
            while (root.popups.length > root.maxPopups)
                root.hidePopup(root.popups[root.popups.length - 1]);
            while (root.notifications.length > 100) {
                const oldest = root.notifications[root.notifications.length - 1];
                oldest.notification?.dismiss();
                root.records = root.records.filter(item => item !== oldest);
            }
        }
    }

    // ========================================================================
    // WRAPPER COMPONENT
    // ========================================================================

    component NotifWrapper: QtObject {
        id: wrapper

        property bool popup: false

        readonly property int totalTime: Config.notifTimeout
        property real progress: 0.0
        readonly property bool isPaused: root.hoveredNotificationId === (notification ? notification.id : -1)

        // expireTimeout is a read-only client hint in QS 0.3.2. Keep the
        // configured popup lifetime and tracked history/actions, as before.
        readonly property NumberAnimation countdown: NumberAnimation {
            target: wrapper
            property: "progress"
            from: 0
            to: 1
            duration: wrapper.totalTime
            running: wrapper.popup
            paused: wrapper.isPaused && wrapper.popup
            onFinished: root.hidePopup(wrapper)
        }

        // Timestamp
        readonly property date time: new Date()
        function ageAt(now: date): string {
            const diff = now.getTime() - time.getTime();
            const minutes = Math.floor(diff / 60000);

            if (minutes < 1)
                return "now";
            if (minutes < 60)
                return minutes + "m ago";

            const hours = Math.floor(minutes / 60);
            if (hours < 24)
                return hours + "h ago";

            return Math.floor(hours / 24) + "d ago";
        }

        required property Notification notification

        readonly property int notifId: notification ? notification.id : -1
        readonly property string summary: notification ? (notification.summary || "") : ""
        readonly property string body: notification ? (notification.body || "") : ""
        readonly property string appIcon: notification ? (notification.appIcon || "") : ""
        readonly property string appName: notification ? (notification.appName || "System") : "System"
        readonly property string image: notification ? (notification.image || "") : ""
        readonly property int urgency: notification ? notification.urgency : 0
        readonly property bool isUrgent: urgency === 2
        readonly property var actions: notification ? (notification.actions || []) : []
        readonly property bool hasActions: actions && actions.length > 0

        readonly property Connections conn: Connections {
            target: wrapper.notification ? wrapper.notification.Retainable : null

            function onDropped(): void {
                wrapper.popup = false;
                if (root.hoveredNotificationId === wrapper.notifId)
                    root.hoveredNotificationId = -1;
                root.records = root.records.filter(w => w !== wrapper);
            }

            function onAboutToDestroy(): void {
                wrapper.destroy();
            }
        }
    }

    Component {
        id: notifComponent
        NotifWrapper {}
    }

    // ========================================================================
    // PUBLIC FUNCTIONS
    // ========================================================================

    function setHovered(notifId) {
        hoveredNotificationId = notifId;
    }

    function clearHovered() {
        hoveredNotificationId = -1;
    }

    function expireNotification(notifId) {
        hidePopup(popups.find(wrapper => wrapper.notifId === notifId));
    }

    function removeNotification(notifId) {
        const wrapper = records.find(item => item.notifId === notifId);
        if (wrapper)
            wrapper.notification?.dismiss();
    }

    function clearAll() {
        const toRemove = notifications.slice();
        for (const wrapper of toRemove) {
            if (wrapper) {
                if (wrapper.notification) {
                    wrapper.notification.dismiss();
                }
            }
        }
    }

    // ========================================================================
    // ICON HELPER
    // ========================================================================

    function getIconSource(appIcon, image) {
        if (image && image !== "") {
            if (image.startsWith("/"))
                return "file://" + image;
            if (image.startsWith("file://") || image.startsWith("image://"))
                return image;
            return image;
        }

        if (appIcon && appIcon !== "") {
            if (appIcon.startsWith("/"))
                return "file://" + appIcon;
            if (appIcon.startsWith("file://") || appIcon.startsWith("image://"))
                return appIcon;
            return Quickshell.iconPath(appIcon);
        }

        return "";
    }
}
