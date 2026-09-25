pragma ComponentBehavior: Bound

import QtQuick
import "../styles"

Item {
    id: root

    property bool checked: false
    signal toggled

    implicitWidth: 28
    implicitHeight: 16

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: root.checked ? Theme.accent : "transparent"
        border.width: root.checked ? 0 : Theme.borderWidth
        border.color: Theme.border
        antialiasing: false
    }

    Rectangle {
        x: root.checked ? parent.width - width - 2 : 2
        anchors.verticalCenter: parent.verticalCenter
        width: 10
        height: 12
        radius: Theme.radius
        color: root.checked ? Theme.onAccent : Theme.muted
        antialiasing: false

        Behavior on x {
            NumberAnimation {
                duration: Theme.motionMs
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
