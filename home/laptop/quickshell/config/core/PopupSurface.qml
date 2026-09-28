import QtQuick
import Quickshell
import Quickshell.Wayland

import "." as Core

PanelWindow {
    id: root

    property string popupId: ""
    property int cardWidth: Core.Theme.popupWidth
    property int maxCardHeight: Core.Theme.popupMaxHeight
    property Component contentComponent: null

    // A click on the empty window around the card dismisses it. That is the usual
    // way out of a bar popup and it stays the default, but it is a parameter
    // because a card can be tall enough that the strip of window beside it reads
    // as "not part of the popup" -- pressing there to reach a button is then the
    // press that closes the thing you were reaching for. Such a card is dismissed
    // with Escape or its own close action instead.
    property bool closeOnOutsideClick: true

    readonly property bool open: Core.PopupManager.isOpen(root.popupId)

    signal didOpen
    signal didClose

    function openMenu(x, y, items) {
        menuLayer.show(x, y, items);
    }

    function closeMenu() {
        menuLayer.close();
    }

    anchors {
        bottom: true
        left: true
        right: true
    }

    margins.bottom: Core.Theme.barMarginTop

    implicitHeight: root.maxCardHeight + 320

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore

    visible: root.open

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-popup"

    // Exclusive, not OnDemand. OnDemand means "keyboard only after the user
    // clicks this surface", and a popup that nobody clicked -- opened from a
    // bar button, or opened and dismissed by habit -- never gets it, so Escape
    // went to whatever window was focused underneath. The launchers take
    // Exclusive for the same reason.
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property Region noInput: Region {
        width: 0
        height: 0
    }

    // The bar's band, measured up from the bottom of this window: the pill plus
    // the margin its own window sits at. Everything below it belongs to the bar.
    //
    // `barTopOffset` is that same number, and it is why the two are one value and
    // not two: the card is positioned from it and the input mask is cut from it,
    // so a token that moved one and not the other would put a hole in the input
    // region of every popup.
    readonly property int barStrip: Core.Theme.barMarginTop + Core.Theme.pillHeight + Core.Theme.borderWidth

    // What the window is allowed to touch. NOT `null` while open, which is what it
    // used to be, and that was the bug: the window reaches down to the same 10px
    // the bar's does, so it sat over the pill with no mask and swallowed the
    // pointer. The bar's HoverHandler then saw nothing for as long as any card
    // was up, and a HoverHandler re-arms on pointer MOTION rather than on the
    // window going away -- so closing a card collapsed the bar under a cursor
    // that never moved, which read as the bar closing at the end of the close
    // animation.
    //
    // So the mask is the card, and -- for the popups that dismiss on an outside
    // click -- everything above the bar's band, because a dismissal that needs
    // the pointer to find the sliver of window beside the card is not one.
    property Region cardInput: Region {
        item: card
    }

    property Region dismissArea: Region {
        x: 0
        y: 0
        width: root.width
        height: Math.max(0, root.height - root.barStrip)
    }

    // ONE Region holding a LIST, not a list of Regions. `mask` is a
    // PendingRegion with `regions` as its default property, so a JS array was
    // never assignable to it: QML logged "Unable to assign QJSValue to
    // PendingRegion" once per open and left the old mask in place -- which was
    // the empty `noInput`, so the window took no pointer at all. That is why
    // neither the card nor the space beside it responded, and it failed
    // silently: the warning is in the log, not on screen.
    property Region cardAndDismiss: Region {
        regions: [root.cardInput, root.dismissArea]
    }

    mask: root.open ? (root.closeOnOutsideClick ? root.cardAndDismiss : root.cardInput) : root.noInput

    onOpenChanged: {
        if (root.open) {
            root.didOpen();
        } else {
            menuLayer.close();
            root.didClose();
        }
    }

    readonly property real barTopOffset: Core.Theme.barMarginTop + Core.Theme.pillHeight + Core.Theme.borderWidth

    readonly property real naturalHeight: contentHost.implicitHeight + Core.Theme.padding * 2

    readonly property real targetHeight: Math.min(root.naturalHeight, root.maxCardHeight)

    MouseArea {
        anchors.fill: parent

        // Off means off, not inert: the press falls through to whatever is under
        // the window instead of being swallowed by a MouseArea that does nothing.
        enabled: root.open && root.closeOnOutsideClick

        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onPressed: {
            if (menuLayer.active) {
                menuLayer.close();
                return;
            }

            Core.PopupManager.close();
        }
    }

    // The card, the context menu and the Escape handler are ONE subtree, and the
    // handler is its root.
    //
    // Escape was on a sibling Item next to the card, which meant it only ever saw
    // keystrokes that arrived with nothing else focused. A card holding a
    // `Core.TextField` -- TimerPopup's "what are you working on" -- autofocuses
    // that field, and a key event goes to the focused item and then up through
    // its ANCESTORS. A sibling is not an ancestor, so Escape died in the field
    // and the card could not be dismissed from the keyboard at all. Every popup
    // without a text field worked, which is why this looked like a Pomodoro bug
    // and not a scaffolding one.
    Item {
        anchors.fill: parent

        focus: root.open

        Keys.onEscapePressed: {
            if (menuLayer.active)
                menuLayer.close();
            else
                Core.PopupManager.close();
        }

        Rectangle {
            id: card

            width: root.cardWidth

            x: Math.round(Math.max(Core.Theme.popupGap, Math.min(root.width - root.cardWidth - Core.Theme.popupGap, Core.PopupManager.anchorCenter - root.cardWidth / 2)))

            y: Math.round(root.height - root.barTopOffset - root.targetHeight - Core.Theme.popupGap)

            height: root.targetHeight

            color: "transparent"

            antialiasing: true

            Item {
                anchors.fill: parent

                // No transform animation here on purpose.
                //
                // This is a layer surface, so Hyprland already animates it on map via
                // layersIn + fadeLayersIn (see hyprland/config/animation.lua). Scaling
                // it again from QML meant two independent scale animations running on
                // the same window with different durations and curves, which is what
                // made the motion read as unstable. The compositor owns the entrance;
                // the card just draws itself at its final size.
                opacity: root.open ? 1.0 : 0.0

                Rectangle {
                    anchors.fill: parent

                    radius: Core.Theme.radiusMenu

                    color: Core.Theme.surface

                    border.width: 1
                    border.color: Core.Theme.panelRim

                    antialiasing: true
                }

                Item {
                    id: contentHost

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top

                    anchors.margins: Core.Theme.padding

                    implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0

                    height: implicitHeight

                    opacity: root.open ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: root.open ? 150 : 100
                            easing.type: Easing.OutCubic
                        }
                    }

                    Loader {
                        id: contentLoader

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top

                        sourceComponent: root.contentComponent
                    }
                }
            }
        }

        Item {
            id: menuLayer

            anchors.fill: parent

            z: 999

            property bool active: false
            property var items: []

            property real targetX: 0
            property real targetY: 0

            function show(x, y, list) {
                menuLayer.items = list;
                menuLayer.targetX = x;
                menuLayer.targetY = y;
                menuLayer.active = true;
            }

            function close() {
                menuLayer.active = false;
            }

            visible: menuLayer.active || menuBox.opacity > 0.01

            Rectangle {
                id: menuBox

                width: 200

                height: menuColumn.implicitHeight + 10

                x: Math.round(Math.max(6, Math.min(menuLayer.width - width - 6, menuLayer.targetX)))

                y: Math.round(Math.max(6, Math.min(menuLayer.height - height - 6, menuLayer.targetY)))

                radius: 14

                color: Core.Theme.surface

                border.width: Core.Theme.borderWidth
                border.color: Core.Theme.border

                antialiasing: true

                // The context menu is drawn inside this window rather than being its
                // own surface, so Hyprland does not animate it. A plain fade, with no
                // scale, so it does not pop toward the viewer either.
                opacity: menuLayer.active ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: menuLayer.active ? 120 : 90

                        easing.type: Easing.OutCubic
                    }
                }

                Column {
                    id: menuColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top

                    anchors.margins: 5

                    spacing: 1

                    Repeater {
                        model: menuLayer.items

                        delegate: Loader {
                            id: entryLoader

                            required property var modelData

                            width: menuColumn.width

                            sourceComponent: entryLoader.modelData.separator === true ? separatorComp : entryComp

                            Component {
                                id: separatorComp

                                Item {
                                    height: 7

                                    Rectangle {
                                        anchors.centerIn: parent

                                        width: parent.width - 12
                                        height: 1

                                        color: Core.Theme.separator
                                    }
                                }
                            }

                            Component {
                                id: entryComp

                                Rectangle {
                                    height: 30

                                    radius: 9

                                    color: entryMouse.containsMouse ? Core.Theme.surfaceHover : "transparent"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 90
                                            easing.type: Easing.OutQuint
                                        }
                                    }

                                    Row {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter

                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10

                                        spacing: 9

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter

                                            width: 16

                                            text: entryLoader.modelData.icon ? entryLoader.modelData.icon : ""

                                            font.family: Core.Theme.iconFont

                                            font.pixelSize: Core.Theme.iconSizeSmall

                                            color: entryLoader.modelData.danger === true ? Core.Theme.danger : Core.Theme.foregroundMuted
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter

                                            text: entryLoader.modelData.label

                                            font.family: Core.Theme.fontFamily

                                            font.pixelSize: Core.Theme.fontSize

                                            color: entryLoader.modelData.danger === true ? Core.Theme.danger : Core.Theme.foreground
                                        }
                                    }

                                    MouseArea {
                                        id: entryMouse

                                        anchors.fill: parent

                                        hoverEnabled: true

                                        cursorShape: Qt.PointingHandCursor

                                        onClicked: {
                                            const act = entryLoader.modelData.action;

                                            menuLayer.close();

                                            if (typeof act === "function")
                                                act();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
