import QtQuick

import Quickshell

import "../core" as Core
import "../services" as Services

Core.PopupSurface {
    id: popup

    popupId: "notifications"

    cardWidth: 360
    maxCardHeight: 480

    readonly property var list: Services.NotificationServer.history

    readonly property int count: popup.list.length

    readonly property bool dnd: Services.NotificationServer.dnd

    function setDnd(value) {
        Services.NotificationServer.dnd = value;
    }

    function dismiss(n) {
        Services.NotificationServer.dismiss(n);
    }

    function clearAll() {
        Services.NotificationServer.clearAll();
    }

    function appLabel(n) {
        return Services.NotificationServer.appLabel(n);
    }

    function isCritical(n) {
        return Services.NotificationServer.isCritical(n);
    }

    contentComponent: Component {
        Column {
            id: body

            spacing: Core.Theme.spacing

            Core.PopupHeader {
                width: body.width

                title: "Notifications"

                subtitle: popup.dnd ? "Do not disturb" : popup.count === 0 ? "All caught up" : popup.count === 1 ? "1 notification" : popup.count + " notifications"

                showToggle: true

                toggled: !popup.dnd

                onToggleRequested: popup.setDnd(!popup.dnd)

                actions: [
                    {
                        icon: Core.Icons.trash,
                        action: function () {
                            popup.clearAll();
                        }
                    }
                ]
            }

            Rectangle {
                width: body.width

                height: popup.dnd ? 32 : 0

                visible: height > 1

                clip: true

                radius: Core.Theme.radiusRow

                color: Qt.alpha(Core.Theme.warning, 0.13)

                Behavior on height {
                    NumberAnimation {
                        duration: Core.Theme.durBase
                        easing.type: Easing.OutQuint
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    text: Core.Icons.bellOff + "  New alerts are being silenced"

                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.fontSizeSmall

                    color: Core.Theme.warning
                }
            }

            Core.ExpandableList {
                id: list

                width: body.width

                maxHeight: 330

                spacing: 4

                model: popup.list

                delegate: Core.SwipeRow {
                    id: noteRow

                    required property var modelData

                    width: list.width

                    implicitHeight: Math.max(noteLayout.implicitHeight, iconBox.height) + 20
                    height: implicitHeight

                    onSwiped: popup.dismiss(noteRow.modelData)

                    opacity: noteRow.travelFade

                    Rectangle {
                        anchors.fill: parent

                        radius: Core.Theme.radiusRow

                        color: noteMouse.containsMouse ? Core.Theme.surfaceHover : Core.Theme.surface

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                                easing.type: Easing.OutQuint
                            }
                        }
                    }

                    scale: noteMouse.pressed ? 0.97 : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 110
                            easing.type: Easing.OutQuint
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 6

                        width: 3

                        radius: 2

                        color: popup.isCritical(noteRow.modelData) ? Core.Theme.danger : Core.Theme.accent

                        opacity: popup.isCritical(noteRow.modelData) ? 1.0 : 0.55
                    }

                    Rectangle {
                        id: iconBox

                        anchors.left: parent.left
                        anchors.top: parent.top

                        anchors.leftMargin: 16
                        anchors.topMargin: 10

                        width: 32
                        height: 32

                        radius: 10

                        color: Core.Theme.surface

                        readonly property string resolvedIcon: Services.NotificationServer.iconFor(noteRow.modelData)

                        Image {
                            id: noteIcon

                            anchors.centerIn: parent

                            width: 22
                            height: 22

                            source: iconBox.resolvedIcon

                            visible: iconBox.resolvedIcon !== "" && status === Image.Ready

                            asynchronous: true
                            cache: true
                            smooth: true
                            mipmap: true

                            fillMode: Image.PreserveAspectFit
                        }

                        Text {
                            anchors.centerIn: parent

                            visible: !noteIcon.visible

                            text: Core.Icons.forApp(popup.appLabel(noteRow.modelData))

                            font.family: Core.Theme.iconFont
                            font.pixelSize: Core.Theme.iconSizeSmall

                            color: Core.Theme.foregroundFaint
                        }
                    }

                    Column {
                        id: noteLayout

                        anchors.left: iconBox.right
                        anchors.right: parent.right
                        anchors.top: parent.top

                        anchors.leftMargin: 10
                        anchors.rightMargin: 34
                        anchors.topMargin: 10

                        spacing: 3

                        Item {
                            width: parent.width

                            height: appText.implicitHeight

                            Text {
                                id: appText

                                anchors.left: parent.left
                                anchors.right: ageText.left
                                anchors.rightMargin: 6

                                text: popup.appLabel(noteRow.modelData).toUpperCase()

                                elide: Text.ElideRight

                                font.family: Core.Theme.fontFamily
                                font.pixelSize: Core.Theme.fontSizeSmall
                                font.letterSpacing: 0.8

                                color: Core.Theme.foregroundFaint
                            }

                            Text {
                                id: ageText

                                anchors.right: parent.right
                                anchors.baseline: appText.baseline

                                text: {
                                    const tick = Services.NotificationServer.ageTick;

                                    return Services.NotificationServer.ageText(noteRow.modelData);
                                }

                                font.family: Core.Theme.fontMono
                                font.pixelSize: Core.Theme.fontSizeSmall

                                color: Core.Theme.foregroundFaint
                            }
                        }

                        Text {
                            width: parent.width

                            text: noteRow.modelData.summary ? noteRow.modelData.summary : ""

                            visible: text !== ""

                            elide: Text.ElideRight

                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.Theme.fontSize
                            font.weight: Font.DemiBold

                            color: Core.Theme.foreground
                        }

                        Text {
                            width: parent.width

                            text: noteRow.modelData.body ? noteRow.modelData.body : ""

                            visible: text !== ""

                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight

                            textFormat: Text.StyledText

                            linkColor: Core.Theme.accent

                            onLinkActivated: function (link) {
                                Quickshell.execDetached(["xdg-open", link]);
                            }

                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.Theme.fontSizeSmall

                            color: Core.Theme.foregroundMuted
                        }

                        NotificationActions {
                            width: parent.width

                            chipHeight: 22

                            notification: noteRow.modelData
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top

                        anchors.rightMargin: 6
                        anchors.topMargin: 6

                        width: 22
                        height: 22

                        radius: 11

                        color: closeMouse.containsMouse ? Core.Theme.surfaceHover : "transparent"

                        opacity: noteMouse.containsMouse || closeMouse.containsMouse ? 1.0 : 0.0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutQuint
                            }
                        }

                        Text {
                            anchors.centerIn: parent

                            text: Core.Icons.close

                            font.family: Core.Theme.iconFont
                            font.pixelSize: Core.Theme.iconSizeSmall

                            color: Core.Theme.foregroundMuted
                        }

                        MouseArea {
                            id: closeMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            cursorShape: Qt.PointingHandCursor

                            onClicked: popup.dismiss(noteRow.modelData)
                        }
                    }

                    MouseArea {
                        id: noteMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        cursorShape: Qt.PointingHandCursor

                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        z: -1

                        onClicked: function (event) {
                            if (event.button === Qt.LeftButton) {
                                popup.dismiss(noteRow.modelData);
                                return;
                            }

                            const note = noteRow.modelData;

                            const summary = note.summary ? String(note.summary) : "";

                            const bodyText = note.body ? String(note.body) : "";

                            const app = popup.appLabel(note);

                            const point = noteRow.mapToItem(null, event.x, event.y);

                            popup.openMenu(point.x, point.y, [
                                {
                                    icon: Core.Icons.close,
                                    label: "Dismiss",
                                    action: function () {
                                        popup.dismiss(note);
                                    }
                                },
                                {
                                    icon: Core.Icons.copy,
                                    label: "Copy text",
                                    action: function () {
                                        Services.ClipboardService.copy(summary + (bodyText !== "" ? "\n" + bodyText : ""));
                                    }
                                },
                                {
                                    icon: Core.Icons.info,
                                    label: "Copy app name",
                                    action: function () {
                                        Services.ClipboardService.copy(app);
                                    }
                                },
                                {
                                    separator: true
                                },
                                {
                                    icon: Core.Icons.bellOff,
                                    label: popup.dnd ? "Turn off do not disturb" : "Turn on do not disturb",
                                    action: function () {
                                        popup.setDnd(!popup.dnd);
                                    }
                                },
                                {
                                    icon: Core.Icons.trash,
                                    label: "Clear all",
                                    danger: true,
                                    action: function () {
                                        popup.clearAll();
                                    }
                                }
                            ]);
                        }
                    }
                }
            }

            Core.EmptyState {
                width: body.width

                shown: popup.count === 0

                icon: Core.Icons.bell

                text: "Nothing to catch up on"
            }
        }
    }
}
