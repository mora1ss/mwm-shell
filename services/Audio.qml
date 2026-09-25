pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property var streams: {
        const nodes = Pipewire.nodes.values;
        const out = [];
        for (let i = 0; i < nodes.length; i++) {
            const node = nodes[i];
            if (!node || !node.isStream || !node.audio)
                continue;
            if (node.isSink)
                continue;
            out.push(node);
        }
        return out;
    }

    function setVolume(next: real): void {
        if (!root.sink || !root.sink.audio)
            return;
        root.sink.audio.volume = Math.max(0, Math.min(1.5, next));
    }

    function toggleMute(): void {
        if (!root.sink || !root.sink.audio)
            return;
        root.sink.audio.muted = !root.sink.audio.muted;
    }

    function setStreamVolume(node: var, next: real): void {
        if (!node || !node.audio)
            return;
        node.audio.volume = Math.max(0, Math.min(1.5, next));
    }
}
