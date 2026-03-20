pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell

Singleton {
    readonly property date date: clock.date

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
