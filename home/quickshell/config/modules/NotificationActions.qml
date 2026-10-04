import QtQuick

import Quickshell

import "../core" as Core
import "../services" as Services

Item {
    id: root

    property var notification: null

    property int chipHeight: 24

    readonly property var actionList: {
        try {
            const list = root.notification ? root.notification.actions : null;

            return list ? list : [];
        } catch (e) {
            return [];
        }
    }

    readonly property bool iconActions: Services.NotificationServer.hasActionIcons(root.notification)

    readonly property bool canReply: Services.NotificationServer.hasInlineReply(root.notification)

    readonly property bool replying: Services.NotificationServer.isReplying(root.notification)

    property string reply: ""

    implicitHeight: layout.implicitHeight

    height: root.implicitHeight

    visible: root.actionList.length > 0 || root.canReply

    function focusReply() {
        if (root.replying)
            replyField.focusInput();
    }

    onReplyingChanged: {
        if (root.replying) {
            root.reply = "";

            Qt.callLater(root.focusReply);
        }
    }

    MouseArea {
        anchors.fill: parent

        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: {}
    }

    Column {
        id: layout

        width: parent.width

        spacing: 6

        Flow {
            width: parent.width

            spacing: 6

            Repeater {
                model: root.actionList

                delegate: Rectangle {
                    id: chip

                    required property var modelData

                    readonly property string label: {
                        try {
                            if (chip.modelData.text && String(chip.modelData.text) !== "")
                                return String(chip.modelData.text);
                        } catch (e) {}

                        return "Open";
                    }

                    readonly property string iconSource: {
                        if (!root.iconActions)
                            return "";

                        try {
                            if (chip.modelData.identifier && String(chip.modelData.identifier) !== "")
                                return Quickshell.iconPath(String(chip.modelData.identifier), true);
                        } catch (e) {}

                        return "";
                    }

                    height: root.chipHeight

                    width: chipIcon.visible ? root.chipHeight + 12 : chipText.implicitWidth + 20

                    radius: height / 2

                    color: chipMouse.containsMouse ? Core.Theme.surfaceHover : Core.Theme.surface

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                            easing.type: Easing.OutQuint
                        }
                    }

                    Image {
                        id: chipIcon

                        anchors.centerIn: parent

                        width: Core.Theme.iconSizeSmall
                        height: Core.Theme.iconSizeSmall

                        source: chip.iconSource

                        visible: chip.iconSource !== "" && status === Image.Ready

                        asynchronous: true
                        cache: true
                        smooth: true
                        mipmap: true

                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        id: chipText

                        anchors.centerIn: parent

                        visible: !chipIcon.visible

                        text: chip.label

                        font.family: Core.Theme.fontFamily

                        font.pixelSize: Core.Theme.fontSizeSmall

                        color: Core.Theme.foreground
                    }

                    MouseArea {
                        id: chipMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        cursorShape: Qt.PointingHandCursor

                        onClicked: Services.NotificationServer.invokeAction(root.notification, chip.modelData)
                    }
                }
            }

            Rectangle {
                visible: root.canReply && !root.replying

                height: root.chipHeight

                width: replyChipText.implicitWidth + 26

                radius: height / 2

                color: replyChipMouse.containsMouse ? Core.Theme.surfaceHover : Core.Theme.surface

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                        easing.type: Easing.OutQuint
                    }
                }

                Text {
                    id: replyChipText

                    anchors.centerIn: parent

                    text: Core.Icons.send + "  " + Services.NotificationServer.replyPlaceholder(root.notification)

                    font.family: Core.Theme.iconFont

                    font.pixelSize: Core.Theme.fontSizeSmall

                    color: Core.Theme.accent
                }

                MouseArea {
                    id: replyChipMouse

                    anchors.fill: parent

                    hoverEnabled: true

                    cursorShape: Qt.PointingHandCursor

                    onClicked: Services.NotificationServer.beginReply(root.notification)
                }
            }
        }

        Item {
            width: parent.width

            height: root.replying ? 30 : 0

            visible: root.replying

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                anchors.leftMargin: 2
                anchors.rightMargin: 2

                spacing: 2

                Core.TextField {
                    id: replyField

                    width: parent.width - 28

                    height: 26

                    text: reply

                    placeholder: Services.NotificationServer.replyPlaceholder(root.notification)

                    onEdited: function (value) {
                        root.reply = value;
                    }

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Escape) {
                            Services.NotificationServer.cancelReply();
                            event.accepted = true;
                            return;
                        }

                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            Services.NotificationServer.sendReply(root.notification, replyField.text);
                            event.accepted = true;
                        }
                    }
                }

                Core.IconButton {
                    width: 24
                    height: 24

                    anchors.verticalCenter: parent.verticalCenter

                    icon: Core.Icons.send

                    color: replyField.text.length > 0 ? Core.Theme.accent : Core.Theme.foregroundFaint

                    onClicked: Services.NotificationServer.sendReply(root.notification, replyField.text)
                }
            }
        }
    }
}
