import QtQuick

import "." as Core

Item {
    id: root

    property string icon: ""

    property color color: Core.Theme.foregroundMuted

    property bool spinning: false

    property real pressScale: 0.88

    signal clicked

    implicitWidth: 26
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent

        radius: height / 2

        color: mouse.containsMouse ? Core.Theme.surfaceHover : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 100
                easing.type: Easing.OutQuint
            }
        }
    }

    scale: mouse.pressed && root.pressScale !== 1.0 ? root.pressScale : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 110
            easing.type: Easing.OutQuint
        }
    }

    Text {
        anchors.centerIn: parent

        text: root.icon

        font.family: Core.Theme.iconFont
        font.pixelSize: Math.round(Math.min(root.width, root.height) * 0.6)

        color: root.color

        RotationAnimator on rotation {
            running: root.spinning
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 1000
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent

        hoverEnabled: true

        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
    }
}
