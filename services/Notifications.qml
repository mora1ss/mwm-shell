pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../core"

Singleton {
    id: root

    property var live: []

    function push(note: var): void {
        const next = [];
        next.push(note);
        for (let i = 0; i < root.live.length; i++) {
            if (root.live[i] !== note)
                next.push(root.live[i]);
        }
        if (next.length > 4)
            next.length = 4;
        root.live = next;
    }

    function drop(note: var): void {
        const next = [];
        for (let i = 0; i < root.live.length; i++) {
            if (root.live[i] !== note)
                next.push(root.live[i]);
        }
        root.live = next;
    }

    function clearHistory(): void {
        const list = server.trackedNotifications.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i])
                list[i].dismiss();
        }
        root.live = [];
    }

    readonly property var history: server.trackedNotifications.values

    NotificationServer {
        id: server

        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true
        inlineReplySupported: true

        onNotification: note => {
            note.tracked = true;
            const critical = note.urgency === NotificationUrgency.Critical;
            if (ShellState.dnd && !critical)
                return;
            root.push(note);
        }
    }
}
