pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "../../styles"
import "../../components"

PanelWindow {
    id: win

    property bool open: false
    property bool armed: false
    property string kind: "volume"
    property real level: 0
    property bool mute: false
    property real seenBrightness: -1

    readonly property var targetScreen: Compositor.focusedScreen()
    readonly property real ratio: {
        if (mute && kind === "volume")
            return 0;
        if (kind === "volume")
            return Math.max(0, Math.min(1, level / 1.5));
        return Math.max(0, Math.min(1, level));
    }

    function flash(nextKind: string, nextLevel: real, nextMute: bool): void {
        if (!win.armed)
            return;
        if (ShellState.controlCenterOpen || ShellState.mediaOpen)
            return;
        win.kind = nextKind;
        win.level = nextLevel;
        win.mute = nextMute;
        win.open = true;
        hide.restart();
    }

    screen: targetScreen
    color: "transparent"
    visible: targetScreen !== null && (open || card.opacity > 0.01)
    focusable: false

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "mwm-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        item: card
    }

    Timer {
        interval: 700
        running: true
        onTriggered: win.armed = true
    }

    Timer {
        id: hide

        interval: 900
        onTriggered: win.open = false
    }

    Connections {
        target: Audio

        function onVolumeChanged(): void {
            win.flash("volume", Audio.volume, Audio.muted);
        }
        function onMutedChanged(): void {
            win.flash("volume", Audio.volume, Audio.muted);
        }
    }

    Connections {
        target: Brightness

        function onFractionChanged(): void {
            if (!Brightness.available)
                return;
            if (win.seenBrightness < 0) {
                win.seenBrightness = Brightness.fraction;
                return;
            }
            if (Math.abs(Brightness.fraction - win.seenBrightness) < 0.005)
                return;
            win.seenBrightness = Brightness.fraction;
            win.flash("brilho", Brightness.fraction, false);
        }
    }

    Rectangle {
        id: card

        width: 220
        height: 36
        anchors.centerIn: parent
        radius: Theme.radius
        color: Theme.bar
        border.width: Theme.borderWidth
        border.color: Theme.border
        antialiasing: false
        opacity: win.open ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.motionMs
                easing.type: Easing.OutCubic
            }
        }

        Label {
            anchors.left: parent.left
            anchors.leftMargin: Theme.space
            anchors.verticalCenter: parent.verticalCenter
            text: win.kind === "volume" ? "Volume" : "Brilho"
        }

        Label {
            anchors.right: parent.right
            anchors.rightMargin: Theme.space
            anchors.verticalCenter: parent.verticalCenter
            mono: true
            text: win.mute && win.kind === "volume" ? "mudo" : Math.round((win.kind === "volume" ? win.level : Brightness.fraction) * 100)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 3
            radius: Theme.radius
            color: Theme.track
            antialiasing: false

            Rectangle {
                width: parent.width * win.ratio
                height: parent.height
                radius: Theme.radius
                color: Theme.accent
                antialiasing: false
            }
        }
    }
}
