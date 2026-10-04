import QtQuick

import "." as Core

// IconButton
//
// A circular glyph button.
//
// The shape was written out six times in the tree, at sizes 22, 24, 26, 28, 30
// and 38, with six different corner radii: `height / 2`, 14, 12, 11, 9 and 11.
// Two of those were not circles at all, which is the only reason a size change
// was ever a thing to think about. The radius is `height / 2` here, so the
// button is a circle at any size and the call site only says how big.
Item {
    id: root

    property string icon: ""

    property color color: Core.Theme.foregroundMuted

    // A spinner's own animation, for an action that is still running.
    property bool spinning: false

    // The press dips the button. Off for a control that is already at its
    // smallest, which is what the two call sites that set it to 0 wanted.
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
