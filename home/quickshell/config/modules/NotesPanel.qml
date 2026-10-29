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

    readonly property color noteBackground: Core.Theme.isLight ? "#faf7ed" : "#24231f"
    readonly property color noteForeground: Core.Theme.isLight ? "#3d392e" : "#e9e4d5"
    readonly property color noteMuted: Core.Theme.isLight ? "#746d5c" : "#b3ac97"
    readonly property color noteHeaderBackground: Core.Theme.isLight ? "#fff1ad" : "#39311d"

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

        color: root.noteBackground

        border.width: Core.Theme.borderWidth
        border.color: Core.Theme.borderActive

        antialiasing: true

        opacity: root.fade

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            height: header.y + header.height + 4
            topLeftRadius: card.radius
            topRightRadius: card.radius
            color: root.noteHeaderBackground
        }

        Core.PopupHeader {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            anchors.margins: Core.Theme.padding

            title: "Notes"
            foregroundColor: Core.Theme.isLight ? "#443615" : "#f4e6b5"
            mutedColor: Core.Theme.isLight ? "#79612b" : "#c3b17a"

            subtitle: root.savedNotice !== "" ? "Saved " + root.savedNotice.split("/").pop() : ""

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

            readonly property int ruleSpacing: Math.ceil(noteMetrics.height)

            FontMetrics {
                id: noteMetrics
                font: editor.font
            }

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: footer.top

            anchors.leftMargin: Core.Theme.padding
            anchors.rightMargin: Core.Theme.padding
            anchors.topMargin: 12
            anchors.bottomMargin: 4

            clip: true

            contentWidth: width
            contentHeight: Math.max(height, editor.implicitHeight + 8)

            boundsBehavior: Flickable.StopAtBounds

            Repeater {
                model: Math.ceil(scroller.height / scroller.ruleSpacing) + 1

                delegate: Rectangle {
                    required property int index

                    width: scroller.width
                    height: 1
                    y: (Math.floor(scroller.contentY / scroller.ruleSpacing) + index + 1) * scroller.ruleSpacing - 1
                    color: Qt.alpha(root.noteMuted, 0.2)
                }
            }

            NotesEditor {
                id: editor

                width: scroller.width

                wrapMode: TextEdit.Wrap

                text: ""

                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.fontSize
                font.letterSpacing: 0.2

                color: root.noteForeground
                selectionColor: Qt.alpha(root.noteForeground, 0.2)
                selectedTextColor: root.noteForeground

                onTextChanged: Services.NotesService.edit(editor.text)

                onCursorRectangleChanged: {
                    if (editor.cursorRectangle.y < scroller.contentY)
                        scroller.contentY = editor.cursorRectangle.y;
                    else if (editor.cursorRectangle.y + editor.cursorRectangle.height > scroller.contentY + scroller.height)
                        scroller.contentY = editor.cursorRectangle.y + editor.cursorRectangle.height - scroller.height;
                }
            }
        }

        Text {
            id: footer

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            anchors.margins: Core.Theme.padding

            text: editor.mode

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSizeSmall

            color: root.noteMuted
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
