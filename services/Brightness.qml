pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real fraction: -1
    property int queued: -1
    readonly property bool available: fraction >= 0

    function ingest(line: string): void {
        const parts = String(line).trim().split(",");
        if (parts.length < 4)
            return;
        const pct = parseInt(String(parts[3]).replace("%", ""), 10);
        if (Number.isNaN(pct))
            return;
        root.fraction = Math.max(0, Math.min(1, pct / 100));
    }

    function setFraction(next: real): void {
        const pct = Math.round(Math.max(0, Math.min(1, next)) * 100);
        root.fraction = pct / 100;
        root.queued = pct;
        root.pump();
    }

    function pump(): void {
        if (setter.running || root.queued < 0)
            return;
        const pct = root.queued;
        root.queued = -1;
        setter.command = ["brightnessctl", "-c", "backlight", "set", pct + "%"];
        setter.running = true;
    }

    Process {
        id: watch

        command: ["sh", Quickshell.shellPath("scripts/backlight.sh")]
        running: true

        stdout: SplitParser {
            onRead: data => root.ingest(data)
        }
    }

    Process {
        id: setter

        running: false
        onExited: root.pump()
    }
}
