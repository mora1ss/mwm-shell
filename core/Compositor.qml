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

    function focusedScreen(): var {
        const screens = Quickshell.screens;
        if (!screens || screens.length === 0)
            return null;

        const mon = Hyprland.focusedMonitor;
        if (mon && mon.name) {
            for (let i = 0; i < screens.length; i++) {
                if (screens[i].name === mon.name)
                    return screens[i];
            }
        }
        return screens[0];
    }

    function focusWorkspace(id: int): void {
        const ws = String(id);
        if (Hyprland.usingLua)
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + ws + " })");
        else
            Hyprland.dispatch("workspace " + ws);
    }
}
