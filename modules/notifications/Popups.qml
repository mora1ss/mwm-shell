pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "../../styles"

PanelWindow {
    id: win

    readonly property var targetScreen: Compositor.focusedScreen()

    screen: targetScreen
    color: "transparent"
    visible: targetScreen !== null && Notifications.live.length > 0
    focusable: false

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "mwm-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        item: stack
    }

    Column {
        id: stack

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: (Config.barOnTop ? Config.barHeight : 0) + Theme.space
        anchors.rightMargin: Theme.space + (ShellState.controlCenterOpen ? 308 : 0)
        spacing: Theme.space

        Repeater {
            model: Notifications.live

            delegate: Card {
                required property var modelData
                note: modelData
            }
        }
    }
}
