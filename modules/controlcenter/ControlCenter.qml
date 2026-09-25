pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import "../../core"
import "../../services"
import "../../styles"
import "../../components"

PanelWindow {
    id: win

    readonly property var targetScreen: Compositor.focusedScreen()

    function connectedLabel(): string {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++) {
            const device = devices[i];
            if (!device || !device.connected)
                continue;
            const nets = device.networks ? device.networks.values : [];
            for (let j = 0; j < nets.length; j++) {
                if (nets[j] && nets[j].connected && nets[j].name)
                    return nets[j].name;
            }
            return device.name || "Ligado";
        }
        return Networking.wifiEnabled ? "Sem ligação" : "Desligado";
    }

    function connectedDevices(): int {
        const list = Bluetooth.devices.values;
        let count = 0;
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].connected)
                count += 1;
        }
        return count;
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
    WlrLayershell.namespace: "mwm-control"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Item {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.controlCenterOpen = false
        }

        Rectangle {
            id: panel

            z: 1
            width: 300
            height: column.implicitHeight + Theme.space * 2
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: Theme.space
            anchors.topMargin: (Config.barOnTop ? Config.barHeight : 0) + Theme.space
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
                        text: "Controlo"
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
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
                            onClicked: ShellState.controlCenterOpen = false
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.space

                    Column {
                        width: parent.width - wifiToggle.width - Theme.space
                        spacing: 2

                        Label {
                            text: "Wi-Fi"
                        }
                        Label {
                            small: true
                            color: Theme.muted
                            text: win.connectedLabel()
                            width: parent.width
                            elide: Text.ElideRight
                        }
                    }

                    Toggle {
                        id: wifiToggle
                        anchors.verticalCenter: parent.verticalCenter
                        checked: Networking.wifiEnabled
                        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.space

                    Column {
                        width: parent.width - btToggle.width - Theme.space
                        spacing: 2

                        Label {
                            text: "Bluetooth"
                        }
                        Label {
                            small: true
                            color: Theme.muted
                            text: {
                                const adapter = Bluetooth.defaultAdapter;
                                if (!adapter)
                                    return "Indisponível";
                                const n = win.connectedDevices();
                                if (!adapter.enabled)
                                    return "Desligado";
                                return n > 0 ? (n + " ligado" + (n === 1 ? "" : "s")) : "Sem dispositivos";
                            }
                        }
                    }

                    Toggle {
                        id: btToggle
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: Bluetooth.defaultAdapter !== null
                        checked: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                        onToggled: {
                            const adapter = Bluetooth.defaultAdapter;
                            if (adapter)
                                adapter.enabled = !adapter.enabled;
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 28

                    Label {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notificações"
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: historyLabel.implicitWidth + Theme.space * 2
                        height: 24
                        radius: Theme.radius
                        color: ShellState.notificationsOpen ? Theme.accent : (historyArea.containsMouse ? Theme.surface : "transparent")
                        border.width: ShellState.notificationsOpen ? 0 : Theme.borderWidth
                        border.color: Theme.border
                        antialiasing: false

                        Label {
                            id: historyLabel
                            anchors.centerIn: parent
                            small: true
                            color: ShellState.notificationsOpen ? Theme.accentText : Theme.text
                            text: "Histórico"
                        }

                        MouseArea {
                            id: historyArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellState.toggle("notifications")
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.space

                    Label {
                        text: "Não incomodar"
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - dndToggle.width - Theme.space
                    }

                    Toggle {
                        id: dndToggle
                        anchors.verticalCenter: parent.verticalCenter
                        checked: ShellState.dnd
                        onToggled: ShellState.dnd = !ShellState.dnd
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spaceSm

                    Item {
                        width: parent.width
                        height: volValue.implicitHeight

                        Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Volume"
                        }

                        Label {
                            id: volValue
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            mono: true
                            text: Audio.muted ? "mudo" : Math.round(Audio.volume * 100)
                        }
                    }

                    Slider {
                        width: parent.width
                        from: 0
                        to: 1.5
                        value: Audio.volume
                        onMoved: next => Audio.setVolume(next)
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spaceSm
                    visible: Brightness.available

                    Item {
                        width: parent.width
                        height: briValue.implicitHeight

                        Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Brilho"
                        }

                        Label {
                            id: briValue
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            mono: true
                            text: Math.round(Brightness.fraction * 100)
                        }
                    }

                    Slider {
                        width: parent.width
                        value: Brightness.fraction
                        onMoved: next => Brightness.setFraction(next)
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spaceSm

                    Repeater {
                        model: [
                            { "label": "Eco", "profile": PowerProfile.PowerSaver },
                            { "label": "Equilíbrio", "profile": PowerProfile.Balanced },
                            { "label": "Desempenho", "profile": PowerProfile.Performance }
                        ]

                        delegate: Rectangle {
                            id: profileButton

                            required property var modelData

                            readonly property bool active: PowerProfiles.profile === profileButton.modelData.profile

                            width: (300 - Theme.space * 2 - Theme.spaceSm * 2) / 3
                            height: 28
                            radius: Theme.radius
                            antialiasing: false
                            color: active ? Theme.accent : (area.containsMouse ? Theme.surface : "transparent")
                            border.width: active ? 0 : Theme.borderWidth
                            border.color: Theme.border

                            Label {
                                anchors.centerIn: parent
                                text: profileButton.modelData.label
                                small: true
                                color: profileButton.active ? Theme.accentText : Theme.text
                            }

                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: PowerProfiles.profile = profileButton.modelData.profile
                            }
                        }
                    }
                }
            }
        }
    }
}
