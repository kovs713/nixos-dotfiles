import QtQuick

import "." as Core

// ExpandableList
//
// A clipped, height-capped device list: the shape behind the network, bluetooth,
// battery and notification lists. The card grows the list to its content and
// stops at `maxHeight`, and the list scrolls inside that.
//
// This was open-coded five times. The five `Transition`s — add, remove,
// displaced, addDisplaced, removeDisplaced — were byte-identical in four of the
// five files and near-identical in the fifth, ~200 lines in total. Beside them,
// four different magic caps (250/330/180/300) and three different hover
// behaviours on the same "clipped list that grows to its content" idea.
//
// The delegate stays with the caller: the roles and the context menu are
// per-popup, and only the container is shared.

Item {
    id: root

    // The cap. Not a token — five numbers for five cards, and a token per call
    // site is ceremony. Theme.rowHeight and Theme.popupMaxHeight exist and are
    // bypassed, but popup geometry is deliberately not going to Nix.
    property int maxHeight: 0

    // What to show. False collapses the list to zero height, which is how the
    // "wifi is off" and "no peripherals" states are expressed.
    property bool expanded: true

    // Whether the growth is animated.
    //
    // The network list is the exception, and it was a deliberate choice: it sits
    // directly under a card whose own height is already animating, so a second
    // animation on the same dimension made the surface trail its own content
    // and slice the rows against its edge. The other three have no such parent
    // motion, so they animate.
    property bool animated: true

    property int spacing: 1

    property var model: null

    // Required. The roles and the context menu are per-popup; only the
    // container is shared.
    property Component delegate

    implicitHeight: root.expanded ? Math.min(list.contentHeight, root.maxHeight) : 0

    clip: true

    Behavior on implicitHeight {
        enabled: root.animated
        NumberAnimation {
            duration: Core.Theme.durBase
            easing.type: Easing.OutQuint
        }
    }

    ListView {
        id: list

        anchors.fill: parent

        clip: true

        spacing: root.spacing

        boundsBehavior: Flickable.StopAtBounds

        model: root.model

        delegate: root.delegate

        // Per-row motion. Identical in all four callers before this existed.

        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 160
                easing.type: Easing.OutQuint
            }
        }

        remove: Transition {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 160
                easing.type: Easing.InQuint
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 170
                easing.type: Easing.OutQuint
            }
        }

        addDisplaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 170
                easing.type: Easing.OutQuint
            }
        }

        removeDisplaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 160
                easing.type: Easing.OutQuint
            }
        }
    }
}
