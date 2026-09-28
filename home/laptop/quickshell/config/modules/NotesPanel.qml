import QtQuick

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../core" as Core
import "../services" as Services

// NotesPanel
//
// A scratch pad pinned to the right edge, for the things you have to type down
// while the rest of the screen is busy (interview questions, a name off a
// badge). Toggle with Mod+N.
//
// The card is not full height on purpose: a short floating panel stays out of
// the way and, being a layer surface on Overlay, never moves other windows.
//
// This is a view. The file, the debounce, the export filename's timestamp and
// the mkdir all live in NotesService, in the same idiom as TimerService and
// ReminderService.

PanelWindow {
    id: root

    // A PanelWindow is sized by implicitWidth/implicitHeight, not by its
    // children: with neither set it collapsed to the header's implicit width
    // (~150px, so seven characters a line), and the card's own `width` — clamped
    // against that same root.width — inherited the collapse. The card is the
    // size, and the window follows it, same as Privacy.qml.
    implicitWidth: card.width
    implicitHeight: card.height

    property bool open: false

    // Same fade the popups use (PopupSurface.qml `contentHost`): 150ms in, 100ms
    // out, no transform. The window outlives `open` on the way out -- see the
    // `visible` binding below -- so the exit is not cut off by the unmap.
    property real fade: root.open ? 1.0 : 0.0

    Behavior on fade {
        NumberAnimation {
            duration: root.open ? 150 : 100
            easing.type: Easing.OutCubic
        }
    }

    function toggle() {
        root.open = !root.open;

        if (root.open) {
            Qt.callLater(function () {
                editor.forceActiveFocus();
            });

            return;
        }

        Core.PopupManager.close();
    }

    function clear() {
        editor.text = "";
    }

    function save() {
        Services.NotesService.exportText(editor.text);

        noticeTimer.restart();
    }

    readonly property string savedNotice: Services.NotesService.savedNotice

    Timer {
        id: noticeTimer

        interval: 2500
        repeat: false

        onTriggered: Services.NotesService.clearNotice()
    }

    anchors {
        top: true
        right: true
        bottom: true
    }

    margins.top: 60
    margins.right: 14
    margins.bottom: 60

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    visible: root.open || root.fade > 0.01

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-notes"

    // Exclusive, not OnDemand. OnDemand only hands the surface the keyboard once
    // the user clicks it, so `editor.forceActiveFocus()` below had nothing to
    // attach to and the pad could only be typed into after a click. Exclusive
    // is what Bar.qml uses for the same reason when a launcher opens.
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Nothing to click when closed, so the rest of the screen is untouched.
    property Region noInput: Region {
        width: 0
        height: 0
    }

    // Masked to the card, so the rest of the right-hand column keeps passing
    // clicks through to whatever is underneath while the pad is open.
    property Region cardInput: Region {
        item: card
    }

    mask: root.open ? root.cardInput : root.noInput

    onOpenChanged: {
        if (!root.open)
            noticeTimer.stop();
    }

    Rectangle {
        id: card

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        // Wide enough for a full sentence per line, which is the whole point of
        // typing a question down while reading one off a screen.
        width: 680
        height: 520

        radius: Core.Theme.radiusMenu

        color: Core.Theme.surface

        border.width: Core.Theme.borderWidth
        border.color: Core.Theme.borderActive

        antialiasing: true

        opacity: root.fade

        // No click-away layer: the window is masked to this card, so the desktop
        // is still clickable around it. Close with Mod+N, Escape or the x.

        Core.PopupHeader {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            anchors.margins: Core.Theme.padding

            title: "Notes"

            subtitle: root.savedNotice !== "" ? "Saved " + root.savedNotice.split("/").pop() : "Autosaved"

            actions: [
                {
                    icon: Core.Icons.save,
                    action: root.save
                },
                {
                    icon: Core.Icons.trash,
                    action: root.clear
                },
                {
                    icon: Core.Icons.close,
                    action: root.open = false
                }
            ]
        }

        Flickable {
            id: scroller

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: footer.top

            anchors.leftMargin: Core.Theme.padding
            anchors.rightMargin: Core.Theme.padding
            anchors.topMargin: 4
            anchors.bottomMargin: 4

            clip: true

            contentWidth: width
            contentHeight: Math.max(height, editor.implicitHeight + 8)

            boundsBehavior: Flickable.StopAtBounds

            // No ScrollBar: nothing else in this shell pulls in QtQuick.Controls,
            // and the wheel scrolls fine without one.

            TextEdit {
                id: editor

                width: scroller.width

                wrapMode: TextEdit.Wrap

                text: ""

                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.fontSize
                font.letterSpacing: 0.2

                color: Core.Theme.foreground
                selectionColor: Qt.alpha(Core.Theme.accent, 0.4)
                selectedTextColor: Core.Theme.foreground

                selectByMouse: true

                // Debounced in the service: one write per pause, not one per
                // keystroke.
                onTextChanged: Services.NotesService.edit(editor.text)

                Keys.onEscapePressed: root.open = false
            }
        }

        Text {
            id: footer

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            anchors.margins: Core.Theme.padding

            visible: editor.text.length === 0

            text: "Type here. Mod+N closes."

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSizeSmall

            color: Core.Theme.foregroundFaint
        }
    }

    IpcHandler {
        target: "notes"

        function toggle(): void {
            root.toggle();
        }
    }

    Component.onCompleted: editor.text = Services.NotesService.load()
}
