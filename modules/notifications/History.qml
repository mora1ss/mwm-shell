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

    readonly property var targetScreen: Compositor.focusedScreen()

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
    WlrLayershell.namespace: "mwm-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Item {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.notificationsOpen = false
        }

        Rectangle {
            id: panel

            z: 1
            width: 320
            height: Math.min(parent.height - anchors.topMargin - Theme.space, column.implicitHeight + Theme.space * 2)
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: Theme.space
            anchors.topMargin: (Config.barOnTop ? Config.barHeight : 0) + Theme.space
            radius: Theme.radius
            color: Theme.bar
            border.width: Theme.borderWidth
            border.color: Theme.border
            antialiasing: false
            clip: true

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
                        text: "Notificações"
                    }

                    Label {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        small: true
                        color: clearArea.containsMouse ? Theme.text : Theme.muted
                        text: "Limpar"

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifications.clearHistory()
                        }
                    }
                }

                Label {
                    visible: Notifications.history.length === 0
                    color: Theme.muted
                    text: "Histórico vazio"
                }

                Repeater {
                    model: Notifications.history

                    delegate: Card {
                        required property var modelData
                        note: modelData
                        inHistory: true
                        width: 320 - Theme.space * 2
                    }
                }
            }
        }
    }
}
