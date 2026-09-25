pragma ComponentBehavior: Bound

import QtQuick
import "../../services"
import "../../styles"
import "../../components"

Row {
    id: root

    spacing: Config.barGap

    Component.onCompleted: SystemStats.subscribe()
    Component.onDestruction: SystemStats.unsubscribe()

    component Stat: Item {
        id: stat

        required property string glyph
        required property int value
        required property string suffix

        readonly property string figure: value < 0 ? "–" : (value + suffix)
        readonly property color tone: {
            if (value < 0)
                return Theme.muted;
            if (value >= 90)
                return Theme.danger;
            if (value >= 75)
                return Theme.warn;
            return Theme.text;
        }

        implicitWidth: mark.implicitWidth + Theme.spaceSm + reading.implicitWidth
        implicitHeight: 18

        Icon {
            id: mark

            anchors.verticalCenter: parent.verticalCenter
            name: stat.glyph
        }

        Label {
            id: reading

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: mark.right
            anchors.leftMargin: Theme.spaceSm
            mono: true
            text: stat.figure
            color: stat.tone
        }
    }

    Stat {
        glyph: "cpu"
        value: SystemStats.cpu
        suffix: ""
    }

    Stat {
        glyph: "ram"
        value: SystemStats.ram
        suffix: ""
    }

    Stat {
        glyph: "temp"
        value: SystemStats.temp
        suffix: "°"
    }
}
