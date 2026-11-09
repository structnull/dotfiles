pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string statePath: Quickshell.env("HOME") + "/.config/quickshell/state.json"
    readonly property string defaultsPath: Quickshell.env("HOME") + "/.config/quickshell/defaults.json"
    property var state: ({})
    property bool isLoading: true
    property bool _initialized: false
    property bool _reloading: false
    property bool _saving: false
    property int _revision: 0
    property int _writtenRevision: 0
    property var _pendingEdits: []
    signal stateLoaded

    Component.onCompleted: loadState()
    Component.onDestruction: {
        // Flush the trailing debounce on reload/exit, after animations stop.
        if (_pendingEdits.length > 0) {
            stateFile.blockWrites = true;
            stateFile.setText(JSON.stringify(state, null, 2) + "\n");
        }
    }

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        atomicWrites: true
        blockLoading: true
        printErrors: false
        // fileChanged does not update text(): reload before comparing.
        onFileChanged: reloadDebounce.restart()
        onLoaded: {
            if (root._initialized && root._reloading) {
                root._reloading = false;
                root._acceptDiskState();
            }
        }
        onLoadFailed: root._reloading = false
        onSaved: {
            root._saving = false;
            root._pendingEdits = root._pendingEdits.filter(edit => edit.revision > root._writtenRevision);
            if (root._pendingEdits.length > 0)
                saveDebounce.restart();
        }
        onSaveFailed: {
            root._saving = false;
            console.warn("[StateService] Could not save state.json");
        }
    }

    FileView {
        id: defaultsFile
        path: root.defaultsPath
        blockLoading: true
        printErrors: false
    }

    Timer {
        id: reloadDebounce
        interval: 150
        onTriggered: {
            if (root._saving || root._reloading) {
                restart();
                return;
            }
            root._reloading = true;
            stateFile.reload();
        }
    }

    Timer {
        id: saveDebounce
        interval: 150
        onTriggered: {
            if (root._saving || root._reloading || reloadDebounce.running) {
                restart();
                return;
            }
            const encoded = JSON.stringify(root.state, null, 2) + "\n";
            // setText deliberately emits no saved signal for identical content.
            if (stateFile.text() === encoded) {
                root._pendingEdits = [];
                return;
            }
            root._saving = true;
            root._writtenRevision = root._revision;
            stateFile.setText(encoded);
        }
    }

    function get(path: string, defaultValue) {
        const keys = path.split('.');
        let current = state;
        for (const key of keys) {
            if (current !== null && typeof current === 'object' && key in current)
                current = current[key];
            else
                return defaultValue;
        }
        return current;
    }

    function _setPath(object, path, value) {
        const keys = path.split('.');
        let current = object;
        for (let i = 0; i < keys.length - 1; i++) {
            const key = keys[i];
            if (!current[key] || typeof current[key] !== 'object')
                current[key] = {};
            current = current[key];
        }
        current[keys[keys.length - 1]] = value;
    }

    function set(path: string, value) {
        if (get(path, undefined) === value)
            return;
        _setPath(state, path, value);
        stateChanged();
        if (!isLoading) {
            _revision++;
            // Merge unsaved local edits over external changes without losing unknown keys.
            _pendingEdits = _pendingEdits.filter(edit => edit.path !== path)
                .concat([{path: path, value: value, revision: _revision}]);
            saveState();
        }
    }

    function _parse(text) {
        const parsed = JSON.parse(text);
        if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed))
            throw new Error("State must be a JSON object");
        return parsed;
    }

    function _acceptDiskState() {
        try {
            const parsed = _parse(stateFile.text());
            for (const edit of _pendingEdits)
                _setPath(parsed, edit.path, edit.value);
            if (JSON.stringify(parsed) !== JSON.stringify(state)) {
                state = parsed;
                stateLoaded();
            }
        } catch (error) {
            console.warn("[StateService] Ignoring invalid external state:", error);
        }
    }

    function loadState() {
        if (_initialized) {
            reloadDebounce.restart();
            return;
        }
        try {
            state = _parse(stateFile.text());
        } catch (error) {
            try {
                state = _parse(defaultsFile.text());
            } catch (fallbackError) {
                state = {};
            }
        }
        isLoading = false;
        _initialized = true;
        stateLoaded();
    }

    function saveState() {
        saveDebounce.restart();
    }
}
