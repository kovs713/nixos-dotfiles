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

    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property Region noInput: Region {
        width: 0
        height: 0
    }

    readonly property int barStrip: Core.Theme.barMarginTop + Core.Theme.pillHeight + Core.Theme.borderWidth

    property Region cardInput: Region {
        item: card
    }

    property Region dismissArea: Region {
        x: 0
        y: 0
        width: root.width
        height: Math.max(0, root.height - root.barStrip)
    }

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
