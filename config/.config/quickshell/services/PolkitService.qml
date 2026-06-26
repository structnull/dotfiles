pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Polkit

Singleton {
    id: root

    readonly property bool isActive: agent.isActive
    readonly property var flow: agent.flow
    readonly property bool isRegistered: agent.isRegistered

    PolkitAgent {
        id: agent
    }
}
