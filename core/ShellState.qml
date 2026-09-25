pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property var shellRoot: null
    property bool controlCenterOpen: false
    property bool mediaOpen: false
    property bool notificationsOpen: false
    property bool calendarOpen: false
    property bool dnd: false

    function toggle(name: string): string {
        switch (name) {
        case "controlCenter":
            root.controlCenterOpen = !root.controlCenterOpen;
            return "controlCenter=" + (root.controlCenterOpen ? "1" : "0");
        case "media":
            root.mediaOpen = !root.mediaOpen;
            return "media=" + (root.mediaOpen ? "1" : "0");
        case "notifications":
            root.notificationsOpen = !root.notificationsOpen;
            return "notifications=" + (root.notificationsOpen ? "1" : "0");
        case "calendar":
            root.calendarOpen = !root.calendarOpen;
            return "calendar=" + (root.calendarOpen ? "1" : "0");
        case "dnd":
            root.dnd = !root.dnd;
            return "dnd=" + (root.dnd ? "1" : "0");
        default:
            return "unknown";
        }
    }
}
