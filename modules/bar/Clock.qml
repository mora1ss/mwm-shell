pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../core"
import "../../styles"
import "../../components"

Item {
    id: root

    required property bool live

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

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
