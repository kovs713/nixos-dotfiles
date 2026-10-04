import QtQuick

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../core" as Core
import "../services" as Services

PanelWindow {
    id: root

    implicitWidth: card.width
    implicitHeight: card.height

    property bool open: false

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

    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property Region noInput: Region {
        width: 0
        height: 0
    }

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

        width: 680
        height: 520

        radius: Core.Theme.radiusMenu

        color: Core.Theme.surface

        border.width: Core.Theme.borderWidth
        border.color: Core.Theme.borderActive

        antialiasing: true

        opacity: root.fade

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
