import QtQuick

import "." as Core

// BarButton
//
// The chrome around a bar module's content: the hover pill, the three-button
// click dispatch, the wheel, and the icon pop.
//
// Nine of the ten bar modules opened with this exact block:
//
//     Rectangle {
//         anchors.fill: parent
//         radius: height / 2
//         color: root.menuOpen ? Core.Theme.surface : (mouse.containsMouse ? Core.Theme.surfaceHover : "transparent")
//         Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuint } }
//     }
//
// and six of them ended with a MouseArea that dispatched left, right and middle
// to the same three actions in the same order. The tenth had the same block with
// a `radius: 14` literal, which is why two of the buttons were not pills.
//
// A module is this plus its own content:
//
//     Core.BarButton {
//         id: root
//
//         popupId: "audio"
//         onSecondary: root.svc.toggleOutputMute
//         onAlternate: root.svc.toggleMicMute
//         onScrolled: function (delta) { root.svc.stepVolume(root.svc.sink, delta > 0 ? 0.05 : -0.05) }
//
//         Row { ... }
//     }
//
// The anchor arithmetic stays in PopupManager, so `popupId` is all a module says
// about where its popup goes. A two-state button like the brightness stepper
// leaves `popupId` empty and gives `onPrimary` directly.
Item {
    id: root

    // Which popup this button opens. Empty for a button that has none.
    property string popupId: ""

    readonly property bool open: root.popupId !== "" && Core.PopupManager.isOpen(root.popupId)

    // Left click. With a popupId and no onPrimary, this is the popup toggle.
    property var onPrimary: null

    // Right click, middle click. Absent handler means the button does nothing.
    property var onSecondary: null
    property var onAlternate: null

    // Wheel, with the sign of the scroll. Vertical only, and a horizontal scroll
    // is not delivered: these sit in a bar that nothing scrolls.
    property var onScrolled: null

    // The icon to pop when its glyph changes. The caller owns the Text, so the
    // caller wires this once instead of writing the animation out again:
    //
    //     Text { id: icon; text: root.svc.icon; onTextChanged: root.pop() }
    //     popTarget: icon
    property Item popTarget: null

    function pop() {
        if (root.popTarget)
            popDelay.restart();
    }

    // Hover pill
    Rectangle {
        anchors.fill: parent

        radius: height / 2

        color: root.open ? Core.Theme.surface : (mouse.containsMouse ? Core.Theme.surfaceHover : "transparent")

        Behavior on color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutQuint
            }
        }
    }

    // The icon pop: a short dip and back, so a changed glyph is noticed without
    // the bar twitching. `target` and `property` belong on each step -- a
    // SequentialAnimation animates its children, it is not itself an animation
    // of one property.
    SequentialAnimation {
        id: popAnim

        NumberAnimation {
            target: root.popTarget
            property: "opacity"

            to: 0.55
            duration: 90
            easing.type: Easing.OutQuint
        }

        NumberAnimation {
            target: root.popTarget
            property: "opacity"

            to: 1.0
            duration: 150
            easing.type: Easing.OutQuint
        }
    }

    // The pop says the state settled, and a state that is still settling is not
    // worth saying twice. Everything that changes a bar icon does it through a
    // round trip -- powerprofilesd over D-Bus, a Process, a hyprctl dispatch --
    // so the glyph lands a press or two after the press that asked for it, and
    // every press fired its own dip. Restarted pops cut each other off
    // mid-dip, and the flicker read worse than the change it was announcing.
    //
    // Debounced, a burst is one dip. `restart()` is also what coalesces it: a
    // second press inside the window moves the deadline instead of queueing.
    Timer {
        id: popDelay

        interval: 70

        onTriggered: popAnim.restart()
    }

    MouseArea {
        id: mouse

        anchors.fill: parent

        hoverEnabled: true

        cursorShape: Qt.PointingHandCursor

        // Only the buttons that have a handler. Accepting a middle click on a
        // module with no onAlternate used to swallow a click meant for whatever
        // is behind the bar.
        acceptedButtons: Qt.LeftButton
            | (root.onSecondary ? Qt.RightButton : 0)
            | (root.onAlternate ? Qt.MiddleButton : 0)

        onClicked: function (event) {
            if (event.button === Qt.MiddleButton) {
                if (root.onAlternate)
                    root.onAlternate();
                return;
            }

            if (event.button === Qt.RightButton) {
                if (root.onSecondary)
                    root.onSecondary();
                return;
            }

            if (root.onPrimary) {
                root.onPrimary();
                return;
            }

            // The anchor is derived from this item, never passed as a coordinate.
            if (root.popupId !== "")
                Core.PopupManager.toggle(root.popupId, root);
        }

        onWheel: function (event) {
            if (root.onScrolled)
                root.onScrolled(event.angleDelta.y);
        }
    }
}
