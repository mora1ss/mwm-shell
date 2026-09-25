pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var player: {
        const list = Mpris.players.values;
        for (let i = 0; i < list.length; i++) {
            const entry = list[i];
            if (entry && entry.isPlaying)
                return entry;
        }
        return list.length > 0 ? list[0] : null;
    }

    readonly property bool active: player !== null
}
