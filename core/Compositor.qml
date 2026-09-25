pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    function monitorFor(screen: var): var {
        return Hyprland.monitorFor(screen);
    }

    function focusWorkspace(id: int): void {
        const ws = String(id);
        if (Hyprland.usingLua)
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + ws + " })");
        else
            Hyprland.dispatch("workspace " + ws);
    }
}
