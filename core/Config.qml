pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configPath: {
        const xdg = Quickshell.env("XDG_CONFIG_HOME");
        const home = Quickshell.env("HOME") ?? "";
        const base = (xdg && String(xdg).length > 0) ? String(xdg) : (home + "/.config");
        return base + "/mwm/config.json";
    }

    property string barPosition: "top"
    property int barHeight: 32
    property int barPadding: 8
    property int barGap: 12
    property bool hideOnFullscreen: true
    property bool showWorkspaces: true
    property bool showClock: true
    property bool clockShowSeconds: false
    property bool showTray: true
    property bool showStats: true
    property int statsIntervalMs: 1500

    readonly property bool barOnTop: barPosition !== "bottom"

    function apply(raw: string): void {
        if (!raw || raw.trim().length === 0)
            return;

        let data;
        try {
            data = JSON.parse(raw);
        } catch (e) {
            console.warn("mwm: config.json inválido:", e);
            return;
        }

        const bar = data.bar ?? {};
        if (bar.position === "top" || bar.position === "bottom")
            root.barPosition = bar.position;
        if (typeof bar.height === "number")
            root.barHeight = Math.max(28, Math.round(bar.height));
        if (typeof bar.padding === "number")
            root.barPadding = Math.max(0, Math.round(bar.padding));
        if (typeof bar.gap === "number")
            root.barGap = Math.max(0, Math.round(bar.gap));
        if (typeof bar.hideOnFullscreen === "boolean")
            root.hideOnFullscreen = bar.hideOnFullscreen;
        if (typeof bar.workspaces === "boolean")
            root.showWorkspaces = bar.workspaces;
        if (typeof bar.clock === "boolean")
            root.showClock = bar.clock;
        if (typeof bar.clockSeconds === "boolean")
            root.clockShowSeconds = bar.clockSeconds;
        if (typeof bar.tray === "boolean")
            root.showTray = bar.tray;
        if (typeof bar.stats === "boolean")
            root.showStats = bar.stats;
        if (typeof bar.statsIntervalMs === "number")
            root.statsIntervalMs = Math.max(500, Math.round(bar.statsIntervalMs));
    }

    FileView {
        id: view

        path: root.configPath
        watchChanges: true
        printErrors: false

        onLoaded: root.apply(text())
        onFileChanged: reload()
    }
}
