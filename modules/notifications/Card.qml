pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications
import "../../services"
import "../../styles"
import "../../components"

Rectangle {
    id: root

    required property var note
    property bool inHistory: false

    function plain(raw: string): string {
        return String(raw ?? "").replace(/<[^>]+>/g, "");
    }

    function ttl(): int {
        const timeout = root.note.expireTimeout;
        if (!timeout || timeout <= 0)
            return 5000;
        if (timeout < 100)
            return timeout * 1000;
        return timeout;
    }

    width: 320
    implicitHeight: layout.implicitHeight + Theme.space * 2
    height: implicitHeight
    radius: Theme.radius
    color: Theme.bar
    border.width: Theme.borderWidth
    border.color: root.note.urgency === NotificationUrgency.Critical ? Theme.danger : Theme.border
    antialiasing: false

    Timer {
        interval: root.ttl()
        running: !root.inHistory && root.note.urgency !== NotificationUrgency.Critical
        onTriggered: Notifications.drop(root.note)
    }

    Column {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.space
        spacing: Theme.spaceSm

        Item {
            width: parent.width
            height: Math.max(summary.implicitHeight, 18)

            Label {
                id: summary
                anchors.left: parent.left
                anchors.right: dismissBox.left
                anchors.rightMargin: Theme.spaceSm
                anchors.verticalCenter: parent.verticalCenter
                text: root.note.summary || root.note.appName || "Notificação"
                elide: Text.ElideRight
            }

            Rectangle {
                id: dismissBox

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: Theme.radius
                color: dismissArea.containsMouse ? Theme.surface : "transparent"
                border.width: Theme.borderWidth
                border.color: Theme.border
                antialiasing: false

                Label {
                    anchors.centerIn: parent
                    text: "×"
                }

                MouseArea {
                    id: dismissArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.note.dismiss();
                        Notifications.drop(root.note);
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: Theme.space
            visible: (root.note.image && root.note.image.length > 0) || root.plain(root.note.body).length > 0

            Image {
                visible: root.note.image && root.note.image.length > 0
                width: visible ? 48 : 0
                height: 48
                source: root.note.image
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize.width: 192
                sourceSize.height: 192
            }

            Label {
                width: parent.width - (root.note.image && root.note.image.length > 0 ? 48 + Theme.space : 0)
                small: true
                color: Theme.muted
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                text: root.plain(root.note.body)
            }
        }

        Flow {
            width: parent.width
            spacing: Theme.spaceSm
            visible: root.note.actions && root.note.actions.length > 0

            Repeater {
                model: root.note.actions

                delegate: Rectangle {
                    id: actionButton

                    required property var modelData

                    width: Math.min(140, actionLabel.implicitWidth + Theme.space * 2)
                    height: 24
                    radius: Theme.radius
                    color: actionArea.containsMouse ? Theme.surface : "transparent"
                    border.width: Theme.borderWidth
                    border.color: Theme.border
                    antialiasing: false

                    Label {
                        id: actionLabel
                        anchors.centerIn: parent
                        small: true
                        text: actionButton.modelData.text || "Ação"
                    }

                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: actionButton.modelData.invoke()
                    }
                }
            }
        }

        TextInput {
            visible: root.note.hasInlineReply
            width: parent.width
            color: Theme.text
            selectionColor: Theme.accent
            font.family: Theme.fontUi
            font.pixelSize: Theme.fontSizeSmall
            clip: true
            onAccepted: {
                root.note.sendInlineReply(text);
                text = "";
            }
        }
    }
}
