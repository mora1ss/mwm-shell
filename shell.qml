//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QS_DROP_EXPENSIVE_FONTS=1
//@ pragma Env QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "styles"
import "core"
import "modules/bar"
import "modules/controlcenter"
import "modules/media"
import "modules/osd"

ShellRoot {
    id: root

    settings.watchFiles: true

    Component.onCompleted: ShellState.shellRoot = root

    IpcHandler {
        target: "mwm"

        function toggle(name: string): string {
            return ShellState.toggle(name);
        }

        function barPosition(): string {
            return Config.barPosition;
        }
    }

    Loader {
        active: ShellState.controlCenterOpen
        sourceComponent: ControlCenter {}
    }

    Loader {
        active: ShellState.mediaOpen
        sourceComponent: Media {}
    }

    Osd {}

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: win

                required property var modelData

                readonly property bool concealed: {
                    if (!Config.hideOnFullscreen)
                        return false;
                    const top = ToplevelManager.activeToplevel;
                    if (!top || !top.fullscreen)
                        return false;
                    const list = top.screens;
                    if (!list || list.length === 0)
                        return true;
                    for (let i = 0; i < list.length; i++) {
                        if (list[i] === win.screen)
                            return true;
                    }
                    return false;
                }

                screen: modelData
                color: "transparent"
                visible: !concealed
                focusable: false

                anchors.top: Config.barOnTop
                anchors.bottom: !Config.barOnTop
                anchors.left: true
                anchors.right: true

                implicitHeight: Config.barHeight
                exclusiveZone: concealed ? 0 : Config.barHeight

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "mwm-bar"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                ScreenState {
                    screen: win.screen
                }

                Bar {
                    anchors.fill: parent
                    screen: win.screen
                    live: !win.concealed
                }
            }
        }
    }
}
