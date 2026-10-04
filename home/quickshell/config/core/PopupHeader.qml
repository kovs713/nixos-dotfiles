import QtQuick

import "." as Core

// PopupHeader

Item {
    id: root

    property string title: ""
    property string subtitle: ""

    // Toggle switch
    property bool showToggle: false
    property bool toggled: false

    signal toggleRequested

    // Action buttons: [{ icon, spinning, action }]
    property var actions: []

    implicitHeight: 40

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.right: actionRow.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        spacing: 1

        Text {
            width: parent.width

            text: root.title

            elide: Text.ElideRight

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSizeLarge
            font.weight: Font.DemiBold

            color: Core.Theme.foreground
        }

        Text {
            width: parent.width

            visible: root.subtitle !== ""

            text: root.subtitle

            elide: Text.ElideRight

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSizeSmall

            color: Core.Theme.foregroundMuted
        }
    }

    Row {
        id: actionRow

        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter

        spacing: 2

        Repeater {
            model: root.actions

            delegate: Core.IconButton {
                required property var modelData

                width: 28
                height: 28

                icon: modelData.icon

                spinning: modelData.spinning === true

                onClicked: {
                    if (typeof modelData.action === "function")
                        modelData.action();
                }
            }
        }

        Item {
            visible: root.showToggle

            width: root.showToggle ? 44 : 0
            height: 28

            Rectangle {
                id: track

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 2

                width: 38
                height: 20

                radius: 10

                color: root.toggled ? Core.Theme.accent : Core.Theme.surface

                border.width: Core.Theme.borderWidth;
                border.color: root.toggled ? Core.Theme.accent : Core.Theme.border

                Behavior on color {
                    ColorAnimation {
                        duration: 180
                        easing.type: Easing.OutQuint
                    }
                }

                Rectangle {
                    width: 14
                    height: 14

                    radius: 7

                    anchors.verticalCenter: parent.verticalCenter

                    x: root.toggled ? track.width - width - 3 : 3

                    color: root.toggled ? Core.Theme.accentForeground : Core.Theme.foregroundMuted

                    Behavior on x {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutQuint
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 180
                            easing.type: Easing.OutQuint
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    hoverEnabled: true

                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.toggleRequested()
                }
            }
        }
    }
}
