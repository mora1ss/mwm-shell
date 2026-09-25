pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// Visual tokens. Geometry stays square: `radius` is 0 and components read it
// instead of setting their own corner radius.
Singleton {
    id: theme

    readonly property int radius: 0

    readonly property string fontUi: "IBM Plex Sans"
    readonly property string fontMono: "IBM Plex Mono"
    readonly property string fontIcon: "Material Symbols Outlined"

    readonly property int fontSizeUi: 13
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeMono: 12
    readonly property int iconSize: 14

    readonly property int space: 8
    readonly property int spaceSm: 4
    readonly property int spaceLg: 16
    readonly property int borderWidth: 1
    readonly property int motionMs: 120

    readonly property color text: "#f4f1ea"
    readonly property color muted: "#9a948a"
    readonly property color accent: "#ff4d1c"
    readonly property color onAccent: "#1a0c08"
    readonly property color warn: "#e6b325"
    readonly property color danger: "#ff3355"
    readonly property color border: Qt.rgba(1, 0.96, 0.90, 0.16)
    readonly property color bar: Qt.rgba(0.06, 0.067, 0.075, 0.72)
    readonly property color surface: Qt.rgba(1, 1, 1, 0.06)
    readonly property color track: Qt.rgba(1, 1, 1, 0.10)
}
