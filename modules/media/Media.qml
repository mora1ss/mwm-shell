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

    readonly property var player: Mpris.player
    readonly property var targetScreen: Compositor.focusedScreen()
    property real shown: 0
    property bool dragging: false

    function restart(): void {
        const current = win.player;
        if (!current) {
            travel.stop();
            win.shown = 0;
            return;
        }
        if (win.dragging)
            return;

        win.shown = current.position;
        const length = current.length;
        const rate = current.rate > 0 ? current.rate : 1;
        if (current.isPlaying && length > current.position) {
            travel.from = current.position;
            travel.to = length;
            travel.duration = Math.max(16, (length - current.position) / rate * 1000);
            travel.restart();
        } else {
            travel.stop();
        }
    }

    function clock(seconds: real): string {
        if (!seconds || seconds < 0)
            return "0:00";
        const whole = Math.floor(seconds);
        const minutes = Math.floor(whole / 60);
        const rest = whole % 60;
        return minutes + ":" + (rest < 10 ? "0" : "") + rest;
    }

    function seekTo(x: real): void {
        const current = win.player;
        if (!current || !current.canSeek || current.length <= 0)
            return;
        const ratio = Math.max(0, Math.min(1, x / Math.max(1, seekTrack.width)));
        current.position = ratio * current.length;
        win.shown = current.position;
    }

    screen: targetScreen
    color: "transparent"
    visible: targetScreen !== null
    focusable: true

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "mwm-media"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    NumberAnimation {
        id: travel

        target: win
        property: "shown"
        easing.type: Easing.Linear
    }

    Connections {
        target: win.player

        function onPositionChanged(): void {
            win.restart();
        }
        function onIsPlayingChanged(): void {
            win.restart();
        }
        function onLengthChanged(): void {
            win.restart();
        }
    }

    Component.onCompleted: win.restart()

    Item {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.mediaOpen = false
        }

        Rectangle {
            id: panel

            z: 1
            width: 360
            height: column.implicitHeight + Theme.space * 2
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: (Config.barOnTop ? Config.barHeight : 0) + Theme.space
            anchors.rightMargin: Theme.space + (ShellState.controlCenterOpen ? 300 + Theme.space : 0)
            radius: Theme.radius
            color: Theme.bar
            border.width: Theme.borderWidth
            border.color: Theme.border
            antialiasing: false

            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: column

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.space
                spacing: Theme.space

                Item {
                    width: parent.width
                    height: 18

                    Label {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.player ? (win.player.identity || "Media") : "Media"
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 18
                        height: 18
                        radius: Theme.radius
                        color: closeArea.containsMouse ? Theme.surface : "transparent"
                        border.width: Theme.borderWidth
                        border.color: Theme.border
                        antialiasing: false

                        Label {
                            anchors.centerIn: parent
                            text: "×"
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellState.mediaOpen = false
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 112
                    visible: win.player !== null

                    Rectangle {
                        id: artFrame

                        width: 112
                        height: 112
                        radius: Theme.radius
                        color: Theme.surface
                        antialiasing: false
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: win.player ? win.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize.width: 448
                            sourceSize.height: 448
                        }
                    }

                    Column {
                        anchors.left: artFrame.right
                        anchors.leftMargin: Theme.space
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spaceSm

                        Label {
                            width: parent.width
                            text: win.player && win.player.trackTitle ? win.player.trackTitle : "Sem título"
                            elide: Text.ElideRight
                        }

                        Label {
                            width: parent.width
                            small: true
                            color: Theme.muted
                            text: win.player && win.player.trackArtist ? win.player.trackArtist : ""
                            elide: Text.ElideRight
                        }

                        Label {
                            width: parent.width
                            small: true
                            color: Theme.muted
                            text: win.player && win.player.trackAlbum ? win.player.trackAlbum : ""
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }
                    }
                }

                Label {
                    visible: win.player === null
                    color: Theme.muted
                    text: "Nada a reproduzir"
                }

                Column {
                    width: parent.width
                    spacing: Theme.spaceSm
                    visible: win.player !== null && win.player.length > 0

                    Item {
                        id: seekTrack

                        width: parent.width
                        height: 18

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 4
                            radius: Theme.radius
                            color: Theme.track
                            antialiasing: false
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: {
                                const length = win.player ? win.player.length : 0;
                                if (length <= 0)
                                    return 0;
                                return Math.max(0, Math.min(1, win.shown / length)) * parent.width;
                            }
                            height: 4
                            radius: Theme.radius
                            color: Theme.accent
                            antialiasing: false
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: win.player && win.player.canSeek
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onPressed: event => {
                                win.dragging = true;
                                travel.stop();
                                win.seekTo(event.x);
                            }
                            onPositionChanged: event => {
                                if (pressed)
                                    win.seekTo(event.x);
                            }
                            onReleased: {
                                win.dragging = false;
                                win.restart();
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: elapsed.implicitHeight

                        Label {
                            id: elapsed
                            mono: true
                            small: true
                            color: Theme.muted
                            text: win.clock(win.shown)
                        }

                        Label {
                            anchors.right: parent.right
                            mono: true
                            small: true
                            color: Theme.muted
                            text: win.clock(win.player ? win.player.length : 0)
                        }
                    }
                }

                Row {
                    spacing: Theme.spaceSm
                    visible: win.player !== null

                    Rectangle {
                        width: 72
                        height: 28
                        radius: Theme.radius
                        color: prevArea.containsMouse ? Theme.surface : "transparent"
                        border.width: Theme.borderWidth
                        border.color: Theme.border
                        antialiasing: false

                        Label {
                            anchors.centerIn: parent
                            small: true
                            text: "Anterior"
                        }

                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: win.player && win.player.canGoPrevious
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.player.previous()
                        }
                    }

                    Rectangle {
                        width: 72
                        height: 28
                        radius: Theme.radius
                        color: Theme.accent
                        antialiasing: false

                        Label {
                            anchors.centerIn: parent
                            small: true
                            color: Theme.accentText
                            text: win.player && win.player.isPlaying ? "Pausa" : "Tocar"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (win.player)
                                    win.player.togglePlaying();
                            }
                        }
                    }

                    Rectangle {
                        width: 72
                        height: 28
                        radius: Theme.radius
                        color: nextArea.containsMouse ? Theme.surface : "transparent"
                        border.width: Theme.borderWidth
                        border.color: Theme.border
                        antialiasing: false

                        Label {
                            anchors.centerIn: parent
                            small: true
                            text: "Seguinte"
                        }

                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: win.player && win.player.canGoNext
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.player.next()
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.space
                    visible: Audio.streams.length > 0

                    Label {
                        small: true
                        color: Theme.muted
                        text: "Mixer"
                    }

                    Repeater {
                        model: Audio.streams

                        delegate: Column {
                            id: streamRow

                            required property var modelData

                            width: 360 - Theme.space * 2
                            spacing: Theme.spaceSm

                            Item {
                                width: parent.width
                                height: streamName.implicitHeight

                                Label {
                                    id: streamName
                                    width: parent.width - streamValue.width - Theme.space
                                    text: streamRow.modelData.description || streamRow.modelData.name || "Aplicação"
                                    elide: Text.ElideRight
                                }

                                Label {
                                    id: streamValue
                                    anchors.right: parent.right
                                    mono: true
                                    small: true
                                    color: Theme.muted
                                    text: Math.round((streamRow.modelData.audio ? streamRow.modelData.audio.volume : 0) * 100)
                                }
                            }

                            Slider {
                                width: parent.width
                                from: 0
                                to: 1.5
                                value: streamRow.modelData.audio ? streamRow.modelData.audio.volume : 0
                                onMoved: next => Audio.setStreamVolume(streamRow.modelData, next)
                            }
                        }
                    }
                }
            }
        }
    }
}
