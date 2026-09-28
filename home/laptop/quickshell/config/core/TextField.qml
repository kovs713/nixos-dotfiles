import QtQuick

import "." as Core

// TextField
//
// A single-line text input inside a card: the chrome, the placeholder, and a
// two-way binding that does not fight the cursor.
//
// Four popups wrote their own, at heights 34, 32, 36 and 30. Two of them also
// wrote their own two-way bridge, in three parts:
//
//     Component.onCompleted: input.text = popup.svc.label
//     onTextChanged: popup.svc.label = input.text
//     Connections { target: popup.svc; function onLabelChanged() { ... } }
//
// which exists because a plain `text: popup.svc.label` binding is re-applied on
// every keystroke. It is not, as long as only *user* input writes back:
//
//     TextInput {
//         text: root.text
//         onTextEdited: root.text = text
//     }
//
// onTextEdited fires for typing and pasting, not for a programmatic set. So an
// external change flows in through the binding, a keystroke flows out through
// the handler, and the two never see each other. The re-application on each
// keystroke writes the value the input already has, which QML does not notify,
// so the cursor does not move.
//
// NetworkPopup also carried a `focusPulse` counter, incremented to make a
// Connections fire so it could call forceActiveFocus on a field that lives
// inside a Loader and whose id is out of scope. `autofocus` is that, done
// once, for everybody.
Item {
    id: root

    // The text. Assign it, and read it after `textEdited`.
    property string text: ""

    property string placeholder: ""

    // A short label to the left of the input, the way a form field is labelled.
    // Empty for none. It takes the accent colour while the field has focus, so
    // the label and the border agree about where the attention is.
    property string label: ""

    // A Nerd Font glyph on the left, or "" for none.
    property string icon: ""

    // Password entry, with a bullet that is not the platform's, so it looks the
    // same under every shell.
    property bool echoPassword: false

    // Take focus when the field becomes visible. Which is the normal case: a
    // field the user has just caused to exist is a field they are about to type
    // into. Opt out where the caller drives focus itself.
    property bool autofocus: true

    implicitHeight: 32

    // User input only, and it carries the value rather than the caller reading a
    // property back. Not onTextChanged: a programmatic set is not an edit.
    //
    // The component deliberately does NOT write `text` here. Assigning to a
    // property that has a binding destroys that binding, and `text:` is a
    // binding the caller put there -- so writing it here meant that after one
    // keystroke the field had stopped listening to its caller, and a field
    // cleared between two connections kept the first password, and a reply draft
    // kept the text of the previous reply. The caller owns the value; this only
    // reports it.
    signal edited(string value)
    signal accepted

    // NOT `focus()`. `Item` already has a `focus` property -- a bool -- and a
    // function of the same name does not replace it: `root.focus` resolved to the
    // property, so `Qt.callLater(root.focus)` was handed `false` and threw "first
    // argument not a function or signal" out of the very handler that runs when
    // the field becomes visible. Wrapping the call in a closure is not enough --
    // that fails on the same line with "Property 'focus' is not a function".
    // The name is the bug; renaming it is the fix.
    function focusInput() {
        input.forceActiveFocus();
    }

    Rectangle {
        anchors.fill: parent

        radius: Core.Theme.radiusRow

        color: Core.Theme.surface

        // A literal 1, and only while focused. Theme.borderWidth is 0 in both
        // shipped themes, so a themed border here drew nothing at all and the
        // field had no focus ring -- TimerPopup and PolkitPrompt both had one,
        // and both lost it to this.
        border.width: input.activeFocus ? 1 : 0
        border.color: Core.Theme.accent

        Behavior on border.color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutQuint
            }
        }
    }

    Text {
        id: fieldLabel

        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        visible: root.label !== ""

        text: root.label

        color: input.activeFocus ? Core.Theme.accent : Core.Theme.foregroundMuted

        font.family: Core.Theme.fontFamily
        font.pixelSize: Core.Theme.fontSize
    }

    Text {
        id: lockIcon

        anchors.left: root.label !== "" ? fieldLabel.right : parent.left
        anchors.leftMargin: root.label !== "" ? 8 : 12
        anchors.verticalCenter: parent.verticalCenter

        visible: root.icon !== ""

        text: root.icon

        font.family: Core.Theme.iconFont
        font.pixelSize: Core.Theme.iconSizeSmall

        color: Core.Theme.foregroundMuted
    }

    TextInput {
        id: input

        anchors.left: {
            if (root.icon !== "")
                return lockIcon.right;

            if (root.label !== "")
                return fieldLabel.right;

            return parent.left;
        }
        anchors.leftMargin: {
            if (root.icon !== "")
                return 9;

            if (root.label !== "")
                return 8;

            return 12;
        }
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        clip: true

        echoMode: root.echoPassword ? TextInput.Password : TextInput.Normal
        passwordCharacter: "•"

        font.family: Core.Theme.fontFamily
        font.pixelSize: Core.Theme.fontSize

        color: Core.Theme.foreground

        selectionColor: Core.Theme.accentSoft

        selectByMouse: true

        onTextEdited: root.edited(input.text)

        onAccepted: root.accepted()

        // The value, in -- and deliberately not a binding.
        //
        // `text: root.text` looks right and is not: a keystroke writes
        // input.text imperatively, which destroys the binding behind it, and
        // nothing re-establishes it. A Binding with restoreMode does not help
        // either, because a removed binding is never re-evaluated. Measured: after
        // one caller-side set, two further external changes never reached the
        // field again.
        //
        // So there is no binding to lose. The caller pushes, this pushes in, and
        // the guard is what stops the two fighting: while the user types,
        // input.text differs from text until the caller writes back, and a
        // Connections only fires on an actual change of text.
        Connections {
            target: root

            function onTextChanged() {
                if (input.text !== root.text)
                    input.text = root.text;
            }
        }

        // The field is inside a Loader and so built once, at config load, when
        // the popup is closed and the field has no size. Becoming visible is the
        // per-open cue, and it is per open because a child item's `visible`
        // follows its window's.
        onVisibleChanged: {
            if (!visible || !root.autofocus)
                return;

            // A closure, not a bare function reference: callLater wants something
            // it can invoke, and an argument that happens to share its name with a
            // property is not it.
            Qt.callLater(function () {
                root.focusInput();
            });
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter

            visible: input.text === ""

            text: root.placeholder

            elide: Text.ElideRight

            width: parent.width

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSize

            color: Core.Theme.foregroundFaint
        }
    }
}
