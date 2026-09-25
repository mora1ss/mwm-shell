pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Services.SystemTray
import "../../styles"
import "../../components"

Item {
    id: root

    readonly property int count: repeater.count

    implicitWidth: row.implicitWidth
    implicitHeight: 18

    Row {
        id: row

        spacing: Theme.space

        Repeater {
            id: repeater

            model: SystemTray.items

            delegate: Item {
                id: cell

                required property SystemTrayItem modelData

                implicitWidth: 18
                implicitHeight: 18

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    antialiasing: false
                    color: area.containsMouse ? Theme.surface : "transparent"
                }

                Image {
                    id: glyph

                    anchors.centerIn: parent
                    width: Theme.iconSize
                    height: Theme.iconSize
                    source: cell.modelData.icon
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: Theme.iconSize * 2
                    sourceSize.height: Theme.iconSize * 2
                    visible: false
                }

                ColorOverlay {
                    anchors.fill: glyph
                    source: glyph
                    color: Theme.text
                }

                Rectangle {
                    visible: cell.modelData.status === Status.NeedsAttention
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: 4
                    height: 4
                    radius: Theme.radius
                    color: Theme.accent
                    antialiasing: false
                }

                MouseArea {
                    id: area

                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => {
                        const win = Window.window;
                        if (event.button === Qt.RightButton || cell.modelData.onlyMenu) {
                            if (!win) {
                                cell.modelData.secondaryActivate();
                                return;
                            }
                            const point = mapToItem(win.contentItem, width / 2, height);
                            cell.modelData.display(win, Math.round(point.x), Math.round(point.y));
                        } else {
                            cell.modelData.activate();
                        }
                    }
                }
            }
        }
    }
}
