pragma ComponentBehavior: Bound

import QtQuick
import "../../styles"
import "../../core"
import "../../services"
import "../../components"

Item {
    id: root

    required property var screen
    required property bool live

    Surface {
        anchors.fill: parent
    }

    Rectangle {
        visible: Config.barOnTop
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Theme.borderWidth
        radius: Theme.radius
        color: Theme.border
        antialiasing: false
    }

    Rectangle {
        visible: !Config.barOnTop
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Theme.borderWidth
        radius: Theme.radius
        color: Theme.border
        antialiasing: false
    }

    Workspaces {
        anchors.left: parent.left
        anchors.leftMargin: Config.barPadding
        anchors.verticalCenter: parent.verticalCenter
        visible: Config.showWorkspaces
        screen: root.screen
    }

    Clock {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        visible: Config.showClock
        live: root.live
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Config.barPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.barGap

        Loader {
            id: trayLoader

            active: Config.showTray
            visible: active
            sourceComponent: Tray {}
        }

        Item {
            width: Theme.borderWidth
            height: 18
            visible: trayLoader.active && trayLoader.item && trayLoader.item.count > 0 && statsLoader.active

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: 14
                radius: Theme.radius
                color: Theme.border
                antialiasing: false
            }
        }

        Loader {
            id: statsLoader

            active: Config.showStats && root.live
            visible: active
            sourceComponent: Stats {}
        }

        Rectangle {
            visible: Mpris.active
            width: visible ? 18 : 0
            height: 18
            radius: Theme.radius
            antialiasing: false
            color: ShellState.mediaOpen ? Theme.accent : (mediaArea.containsMouse ? Theme.surface : "transparent")
            border.width: ShellState.mediaOpen ? 0 : Theme.borderWidth
            border.color: Theme.border

            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: Theme.radius
                color: ShellState.mediaOpen ? Theme.accentText : Theme.text
                antialiasing: false
            }

            MouseArea {
                id: mediaArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.toggle("media")
            }
        }

        Rectangle {
            width: 18
            height: 18
            radius: Theme.radius
            antialiasing: false
            color: ShellState.controlCenterOpen ? Theme.accent : (menuArea.containsMouse ? Theme.surface : "transparent")
            border.width: ShellState.controlCenterOpen ? 0 : Theme.borderWidth
            border.color: Theme.border

            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: Theme.radius
                color: "transparent"
                border.width: Theme.borderWidth
                border.color: ShellState.controlCenterOpen ? Theme.accentText : Theme.text
                antialiasing: false
            }

            MouseArea {
                id: menuArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.toggle("controlCenter")
            }
        }
    }
}
