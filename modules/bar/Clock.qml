pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../core"
import "../../styles"
import "../../components"

Item {
    id: root

    required property bool live

    implicitWidth: Math.max(row.implicitWidth, 18)
    implicitHeight: Math.max(row.implicitHeight, 18)

    SystemClock {
        id: clock

        enabled: root.live && root.visible
        precision: Config.clockShowSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Row {
        id: row

        spacing: Theme.space

        Label {
            color: Theme.muted
            text: Qt.formatDateTime(clock.date, "ddd d MMM")
        }

        Label {
            text: Qt.formatDateTime(clock.date, Config.clockShowSeconds ? "HH:mm:ss" : "HH:mm")
        }
    }
}
