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
    property real sampledRawPosition: 0
    property double sampledWallClockMs: 0
    property int playbackTick: 0

    readonly property string title: {
        const preferred = ((activePlayer?.trackTitle ?? "") + "").trim();
        if (preferred !== "")
            return preferred;

        const fallback = ((activePlayer?.metadata?.["xesam:title"] ?? "") + "").trim();
        return fallback !== "" ? fallback : "Nothing playing";
    }

    readonly property string artist: {
        const preferred = ((activePlayer?.trackArtist ?? "") + "").trim();
        if (preferred !== "")
            return preferred;

        const artistMeta = activePlayer?.metadata?.["xesam:artist"];
        if (Array.isArray(artistMeta) && artistMeta.length > 0)
            return ((artistMeta[0] ?? "") + "").trim();

        const fallback = ((artistMeta ?? "") + "").trim();
        return fallback !== "" ? fallback : "Unknown artist";
    }

    readonly property string album: {
        const preferred = ((activePlayer?.trackAlbum ?? "") + "").trim();
        if (preferred !== "")
            return preferred;

        const fallback = ((activePlayer?.metadata?.["xesam:album"] ?? "") + "").trim();
        return fallback;
    }

    readonly property string artUrl: {
        const fromMetadata = ((activePlayer?.metadata?.["mpris:artUrl"] ?? "") + "").trim();
        if (fromMetadata !== "")
            return fromMetadata;

        const fromTrack = ((activePlayer?.trackArtUrl ?? "") + "").trim();
        if (fromTrack !== "")
            return fromTrack;

        return "";
    }

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

    readonly property real maxTimeRaw: Math.max(rawLength, rawPosition)
    readonly property real timeDivisor: maxTimeRaw > 10000000 ? 1000000 : (maxTimeRaw > 10000 ? 1000 : 1)
    readonly property real extrapolatedRawPosition: {
        // Touch this tick so the binding reevaluates at timer cadence while playing.
        playbackTick;
        if (!hasProgress)
            return 0;

        let next = sampledRawPosition;
        if (isPlaying && sampledWallClockMs > 0) {
            const elapsedMs = Math.max(0, Date.now() - sampledWallClockMs);
            next += elapsedMs * (timeDivisor / 1000.0);
        }

        if (rawLength > 0)
            next = Math.min(rawLength, next);
        return Math.max(0, next);
    }

    readonly property real position: extrapolatedRawPosition / timeDivisor
    readonly property real length: rawLength / timeDivisor
    readonly property bool hasProgress: (activePlayer?.lengthSupported ?? false) && rawLength > 0
    readonly property bool canSeek: (activePlayer?.canSeek ?? false) && hasProgress
    readonly property real progress: {
        if (!hasProgress)
            return 0;
        return Math.max(0, Math.min(1, extrapolatedRawPosition / rawLength));
    }

    readonly property string trackKey: {
        const playerId = ((activePlayer?.dbusName ?? activePlayer?.uniqueId ?? "none") + "").trim();
        const trackId = ((activePlayer?.metadata?.["mpris:trackid"] ?? "") + "").trim();
        return playerId + "|" + trackId + "|" + title + "|" + artUrl;
    }

    readonly property string elapsedText: formatDuration(position)
    readonly property string remainingText: hasProgress ? ("-" + formatDuration(Math.max(0, length - position))) : "--:--"

    property var orderedPlayers: []

    onActivePlayerChanged: {
        updateOrderedList();
        syncPositionSample(rawPosition);
    }
    onRawPositionChanged: syncPositionSample(rawPosition)
    onTrackKeyChanged: syncPositionSample(rawPosition)
    onIsPlayingChanged: syncPositionSample(rawPosition)
    onTimeDivisorChanged: syncPositionSample(rawPosition)
    onHasProgressChanged: syncPositionSample(rawPosition)

    Timer {
        interval: 80
        repeat: true
        running: root.hasPlayer && root.hasProgress && root.isPlaying
        onTriggered: root.playbackTick++
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            root.updateActivePlayer();
            root.updateOrderedList();
        }
    }

    Instantiator {
        model: Mpris.players.values

        delegate: QtObject {
            required property var modelData
            property bool isPlaying: modelData.isPlaying ?? false
            onIsPlayingChanged: root.updateActivePlayer()
        }

        onObjectAdded: {
            root.updateActivePlayer();
            root.updateOrderedList();
        }
        onObjectRemoved: {
            root.updateActivePlayer();
            root.updateOrderedList();
        }
    }

    function twoDigits(value) {
        if (value < 10)
            return "0" + value;
        return value + "";
    }

    function playerDbusName(player) {
        return ((player?.dbusName ?? player?.uniqueId ?? "") + "").trim();
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

    function syncPositionSample(candidateRawPosition) {
        const fallback = Math.max(0, rawPosition);
        const candidate = Math.max(0, (candidateRawPosition ?? fallback));
        sampledRawPosition = candidate;
        sampledWallClockMs = Date.now();
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
        root.syncPositionSample(targetRaw);
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
        root.syncPositionSample(player?.position ?? root.rawPosition);
    }
}
