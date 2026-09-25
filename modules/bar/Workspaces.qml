pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import "../../core"
import "../../styles"
import "../../components"

Item {
    id: root

    required property var screen

    readonly property var entries: {
        const values = Hyprland.workspaces.values;
        const toplevelCount = Hyprland.toplevels.values.length;
        const mon = Compositor.monitorFor(root.screen);
        const activeId = mon && mon.activeWorkspace ? mon.activeWorkspace.id : 0;
        const monName = mon && mon.name ? mon.name : "";
        const out = [];

        for (let i = 0; i < values.length; i++) {
            const ws = values[i];
            if (!ws || ws.id <= 0)
                continue;
            const name = ws.name ? String(ws.name) : "";
            if (name.indexOf("special:") === 0)
                continue;
            if (monName.length > 0 && ws.monitor && ws.monitor.name && ws.monitor.name !== monName)
                continue;

            const tops = ws.toplevels ? ws.toplevels.values.length : 0;
            out.push({
                id: ws.id,
                label: String(ws.id),
                occupied: tops > 0,
                active: ws.id === activeId
            });
        }

        out.sort(function (a, b) {
            return a.id - b.id;
        });
        void toplevelCount;
        return out;
    }

    implicitWidth: row.implicitWidth
    implicitHeight: 18

    Row {
        id: row

        spacing: Theme.spaceSm

        Repeater {
            model: root.entries

            delegate: Item {
                id: cell

                required property var modelData

                implicitWidth: Math.max(18, num.implicitWidth + 8)
                implicitHeight: 18

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    antialiasing: false
                    color: {
                        if (cell.modelData.active)
                            return Theme.accent;
                        if (area.containsMouse)
                            return Theme.surface;
                        return "transparent";
                    }
                    border.width: cell.modelData.active ? 0 : Theme.borderWidth
                    border.color: cell.modelData.occupied ? Theme.text : Theme.border

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.motionMs
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Label {
                    id: num

                    anchors.centerIn: parent
                    mono: true
                    text: cell.modelData.label
                    color: cell.modelData.active ? Theme.onAccent : (cell.modelData.occupied ? Theme.text : Theme.muted)
                }

                MouseArea {
                    id: area

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Compositor.focusWorkspace(cell.modelData.id)
                }
            }
        }
    }
}
