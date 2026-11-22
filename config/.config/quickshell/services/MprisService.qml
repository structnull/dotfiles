pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property var activePlayer: null
    property string preferredPlayerKey: ""
    readonly property bool hasPlayer: activePlayer !== null
    readonly property string activePlayerKey: playerKey(activePlayer)
    property int progressConsumers: 0

    onProgressConsumersChanged: {
        if (progressConsumers > 0)
            activePlayer?.positionChanged();
    }

    readonly property string title: activePlayer?.trackTitle || "Nothing playing"
    readonly property string artist: activePlayer?.trackArtist || "Unknown artist"
    readonly property string album: activePlayer?.trackAlbum ?? ""
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""

    readonly property string playerIdentity: ((activePlayer?.identity ?? "") + "").trim()
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property bool canTogglePlaying: activePlayer?.canTogglePlaying ?? false
    readonly property bool canPlay: activePlayer?.canPlay ?? false
    readonly property bool canPause: activePlayer?.canPause ?? false
    readonly property bool canControl: canTogglePlaying || canPlay || canPause
    readonly property bool canGoNext: activePlayer?.canGoNext ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property int orderedPlayersCount: (orderedPlayers && orderedPlayers.length !== undefined) ? orderedPlayers.length : 0

    readonly property real rawPosition: {
        const pos = activePlayer?.position;
        if (pos === undefined || pos === null || isNaN(pos))
            return 0;
        return Math.max(0, pos);
    }

    readonly property real rawLength: {
        const len = activePlayer?.length;
        if (len === undefined || len === null || isNaN(len))
            return 0;
        return Math.max(0, len);
    }

    readonly property real position: hasProgress ? Math.min(rawLength, rawPosition) : 0
    readonly property real length: rawLength
    readonly property bool hasProgress: (activePlayer?.lengthSupported ?? false) && (activePlayer?.positionSupported ?? false) && rawLength > 0
    readonly property bool canSeek: (activePlayer?.canSeek ?? false) && hasProgress
    readonly property real progress: {
        if (!hasProgress)
            return 0;
        return Math.max(0, Math.min(1, position / rawLength));
    }

    readonly property string trackKey: activePlayer ? activePlayer.dbusName + "|" + activePlayer.uniqueId : ""

    readonly property string elapsedText: formatDuration(position)
    readonly property string remainingText: hasProgress ? ("-" + formatDuration(Math.max(0, length - position))) : "--:--"

    property var orderedPlayers: []

    onActivePlayerChanged: updateOrderedList()

    Timer {
        interval: 250
        repeat: true
        running: root.progressConsumers > 0 && root.hasProgress && root.isPlaying
        onTriggered: root.activePlayer?.positionChanged()
    }

    function refreshPlayers() {
        updateActivePlayer();
        updateOrderedList();
    }

    Instantiator {
        model: Mpris.players

        delegate: QtObject {
            required property MprisPlayer modelData
            property bool isPlaying: modelData?.isPlaying ?? false
            onIsPlayingChanged: Qt.callLater(root.refreshPlayers)
        }

        onObjectAdded: Qt.callLater(root.refreshPlayers)
        onObjectRemoved: Qt.callLater(root.refreshPlayers)
    }

    function twoDigits(value) {
        if (value < 10)
            return "0" + value;
        return value + "";
    }

    function playerDbusName(player) {
        return ((player?.dbusName ?? "") + "").trim();
    }

    function playerKey(player) {
        const dbus = playerDbusName(player);
        if (dbus !== "")
            return "dbus:" + dbus;

        const desktop = ((player?.desktopEntry ?? "") + "").trim();
        if (desktop !== "")
            return "desktop:" + desktop;

        const identity = ((player?.identity ?? "") + "").trim();
        if (identity !== "")
            return "identity:" + identity;

        return "";
    }

    function playerDisplayName(player) {
        const identity = ((player?.identity ?? "") + "").trim();
        if (identity !== "")
            return identity;

        const desktopEntry = ((player?.desktopEntry ?? "") + "").trim();
        if (desktopEntry !== "")
            return desktopEntry;

        return "Media";
    }

    function formatDuration(seconds) {
        if (seconds === undefined || seconds === null || isNaN(seconds) || seconds < 0)
            return "0:00";

        const total = Math.floor(seconds);
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = total % 60;

        if (h > 0)
            return h + ":" + twoDigits(m) + ":" + twoDigits(s);
        return m + ":" + twoDigits(s);
    }

    function updateActivePlayer() {
        const rawList = Mpris.players.values;

        if (rawList.length === 0) {
            root.activePlayer = null;
            root.preferredPlayerKey = "";
            return;
        }

        if (root.preferredPlayerKey !== "") {
            const preferred = rawList.find(player => root.playerKey(player) === root.preferredPlayerKey);
            if (preferred) {
                root.activePlayer = preferred;
                return;
            }

            root.preferredPlayerKey = "";
        }

        const playing = rawList.find(player => player.isPlaying);
        if (playing && (!root.activePlayer || !rawList.includes(root.activePlayer) || !root.activePlayer.isPlaying)) {
            root.activePlayer = playing;
            return;
        }

        if (root.activePlayer && rawList.includes(root.activePlayer))
            return;

        root.activePlayer = rawList[0];
    }

    function updateOrderedList() {
        const rawList = Mpris.players.values;

        if (!root.activePlayer) {
            root.orderedPlayers = rawList;
            return;
        }

        const others = rawList.filter(player => player !== root.activePlayer);
        root.orderedPlayers = [root.activePlayer].concat(others);
    }

    function seekToProgress(value) {
        if (!root.canSeek || !root.activePlayer)
            return;

        const clamped = Math.max(0, Math.min(1, value));
        const targetRaw = root.rawLength * clamped;
        root.activePlayer.position = targetRaw;
    }

    function playPause() {
        if (!hasPlayer)
            return;

        if (activePlayer?.canTogglePlaying) {
            activePlayer.togglePlaying();
            return;
        }

        if (isPlaying && activePlayer?.canPause) {
            activePlayer.pause();
            return;
        }

        if (!isPlaying && activePlayer?.canPlay)
            activePlayer.play();
    }

    function next() {
        if (activePlayer?.canGoNext)
            activePlayer.next();
    }

    function previous() {
        if (activePlayer?.canGoPrevious)
            activePlayer.previous();
    }

    function setActivePlayer(player) {
        if (!player)
            return;

        root.preferredPlayerKey = root.playerKey(player);
        root.activePlayer = player;
        root.updateOrderedList();
        player.positionChanged();
    }
}
