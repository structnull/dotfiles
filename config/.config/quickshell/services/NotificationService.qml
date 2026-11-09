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
        for (let i = 0; i < notifications.length; i++) {
            if (notifications[i] && notifications[i].popup) {
                notifications[i].popup = false;
            }
        }
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

    readonly property list<NotifWrapper> notifications: []
    readonly property list<NotifWrapper> popups: notifications.filter(n => n && n.popup)

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
        actionIconsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;

            // If DND is active, don't show popup but still keep in history
            const showPopup = !root.dndEnabled;

            const wrapper = notifComponent.createObject(root, {
                "popup": showPopup,
                "notification": notif
            });

            if (wrapper) {
                root.notifications.unshift(wrapper);

                // Dismiss before releasing the wrapper so server-owned image
                // data is also released. Removal can synchronously emit dropped.
                while (root.notifications.length > 100) {
                    const oldest = root.notifications[root.notifications.length - 1];
                    oldest.popup = false;
                    if (oldest.notification)
                        oldest.notification.dismiss();
                    root.notifications = root.notifications.filter(item => item !== oldest);
                }
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
            onFinished: wrapper.popup = false
        }

        // Timestamp
        readonly property date time: new Date()
        readonly property string timeStr: {
            const now = new Date();
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
                root.notifications = root.notifications.filter(w => w !== wrapper);
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
        for (let i = 0; i < notifications.length; i++) {
            if (notifications[i].notifId === notifId) {
                notifications[i].popup = false;
                break;
            }
        }
    }

    function removeNotification(notifId) {
        for (let i = 0; i < notifications.length; i++) {
            if (notifications[i].notifId === notifId) {
                const wrapper = notifications[i];
                wrapper.popup = false;
                if (wrapper.notification) {
                    wrapper.notification.dismiss();
                }
                break;
            }
        }
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
