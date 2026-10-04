import QtQuick

import "." as Core

Item {
    id: root

    property string text: ""

    property string placeholder: ""

    property string label: ""

    property string icon: ""

    property bool echoPassword: false

    property bool autofocus: true

    implicitHeight: 32

    signal edited(string value)
    signal accepted

    function focusInput() {
        input.forceActiveFocus();
    }

    Rectangle {
        anchors.fill: parent

        radius: Core.Theme.radiusRow

        color: Core.Theme.surface

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

        Connections {
            target: root

            function onTextChanged() {
                if (input.text !== root.text)
                    input.text = root.text;
            }
        }

        onVisibleChanged: {
            if (!visible || !root.autofocus)
                return;

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
