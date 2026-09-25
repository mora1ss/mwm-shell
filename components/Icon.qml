pragma ComponentBehavior: Bound

import QtQuick
import "../styles"

// Drawn marks, so the bar stays monochrome without an icon font.
Item {
    id: root

    property string name: "cpu"

    implicitWidth: Theme.iconSize
    implicitHeight: Theme.iconSize

    Item {
        anchors.fill: parent
        visible: root.name === "cpu"

        Rectangle {
            anchors.centerIn: parent
            width: 12
            height: 12
            radius: Theme.radius
            color: "transparent"
            border.width: Theme.borderWidth
            border.color: Theme.text
            antialiasing: false
        }

        Rectangle {
            anchors.centerIn: parent
            width: 4
            height: 4
            radius: Theme.radius
            color: Theme.text
            antialiasing: false
        }
    }

    Item {
        anchors.fill: parent
        visible: root.name === "ram"

        Repeater {
            model: [6, 10, 14]

            delegate: Rectangle {
                required property int modelData
                required property int index

                x: 2 + index * 4
                y: Theme.iconSize - modelData
                width: 2
                height: modelData
                radius: Theme.radius
                color: Theme.text
                antialiasing: false
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.name === "temp"

        Rectangle {
            x: 5
            y: 0
            width: 4
            height: 8
            radius: Theme.radius
            color: "transparent"
            border.width: Theme.borderWidth
            border.color: Theme.text
            antialiasing: false
        }

        Rectangle {
            x: 3
            y: 8
            width: 8
            height: 6
            radius: Theme.radius
            color: Theme.text
            antialiasing: false
        }
    }
}
