pragma ComponentBehavior: Bound

import QtQuick
import "../styles"

Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    signal moved(real next)

    implicitWidth: 160
    implicitHeight: 18

    readonly property real span: Math.max(0.0001, to - from)
    readonly property real ratio: Math.max(0, Math.min(1, (value - from) / span))

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
        width: root.ratio * parent.width
        height: 4
        radius: Theme.radius
        color: Theme.accent
        antialiasing: false
    }

    MouseArea {
        anchors.fill: parent
        onPressed: event => root.seek(event.x)
        onPositionChanged: event => {
            if (pressed)
                root.seek(event.x);
        }
    }

    function seek(x: real): void {
        const ratio = Math.max(0, Math.min(1, x / Math.max(1, width)));
        root.moved(root.from + ratio * root.span);
    }
}
