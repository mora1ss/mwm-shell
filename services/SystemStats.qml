pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

// One sampler for every screen. It runs only while at least one stats
// widget is loaded.
Singleton {
    id: root

    property int subscribers: 0
    property int cpu: -1
    property int ram: -1
    property int temp: -1
    property int prevIdle: 0
    property int prevTotal: 0

    function subscribe(): void {
        root.subscribers += 1;
        if (root.subscribers === 1 && !sampler.running)
            sampler.running = true;
    }

    function unsubscribe(): void {
        root.subscribers = Math.max(0, root.subscribers - 1);
        if (root.subscribers === 0)
            resample.stop();
    }

    function ingest(raw: string): void {
        const parts = raw.trim().split(/\s+/);
        if (parts.length < 4)
            return;

        const idle = parseInt(parts[0], 10);
        const total = parseInt(parts[1], 10);
        const mem = parseInt(parts[2], 10);
        const degrees = parseInt(parts[3], 10);
        if (Number.isNaN(idle) || Number.isNaN(total) || total <= 0)
            return;

        if (root.prevTotal > 0 && total > root.prevTotal) {
            const dTotal = total - root.prevTotal;
            const dIdle = idle - root.prevIdle;
            const used = Math.max(0, dTotal - dIdle);
            root.cpu = Math.min(100, Math.round(used * 100 / dTotal));
        }

        root.prevIdle = idle;
        root.prevTotal = total;
        if (!Number.isNaN(mem))
            root.ram = mem;
        if (!Number.isNaN(degrees))
            root.temp = degrees;
    }

    Process {
        id: sampler

        command: ["sh", Quickshell.shellPath("scripts/stats.sh")]
        running: false

        stdout: StdioCollector {
            id: out

            waitForEnd: true
            onStreamFinished: root.ingest(out.text)
        }

        onExited: {
            if (root.subscribers > 0)
                resample.restart();
        }
    }

    Timer {
        id: resample

        interval: Config.statsIntervalMs
        repeat: false
        onTriggered: {
            if (root.subscribers > 0 && !sampler.running)
                sampler.running = true;
        }
    }
}
