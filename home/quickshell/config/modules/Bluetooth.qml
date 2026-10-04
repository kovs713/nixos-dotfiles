import QtQuick

import "../core" as Core
import "../services" as Services

Core.BarButton {
    id: root

    implicitWidth: 30
    implicitHeight: Core.Theme.moduleHeight

    popupId: "bluetooth"

    popTarget: icon

    onSecondary: Services.BluetoothService.openManager
    onAlternate: Services.BluetoothService.togglePowered
    onScrolled: function (delta) {
        if (delta !== 0)
            Services.BluetoothService.togglePowered();
    }

    readonly property bool powered: Services.BluetoothService.powered

    readonly property int connectedCount: Services.BluetoothService.connectedCount

    Text {
        id: icon

        anchors.centerIn: parent

        text: !root.powered ? Core.Icons.btOff : root.connectedCount > 0 ? Core.Icons.btConnected : Core.Icons.bluetooth

        font.family: Core.Theme.iconFont
        font.pixelSize: Core.Theme.iconSize

        color: !root.powered ? Core.Theme.foregroundMuted : root.connectedCount > 0 ? Core.Theme.accent : Core.Theme.foreground

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutQuint
            }
        }

        onTextChanged: root.pop()
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right

        anchors.topMargin: 5
        anchors.rightMargin: 4

        width: 5
        height: 5

        radius: 3

        color: Core.Theme.accent

        opacity: Services.BluetoothService.discovering ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutQuint
            }
        }

        SequentialAnimation on scale {
            running: Services.BluetoothService.discovering
            loops: Animation.Infinite

            NumberAnimation {
                to: 1.6
                duration: 480
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: 1.0
                duration: 480
                easing.type: Easing.InOutSine
            }
        }
    }

    Binding {
        target: Services.BluetoothService
        property: "fastPoll"
        value: root.open
    }

    onOpenChanged: {
        if (!root.open && Services.BluetoothService.discovering)
            Services.BluetoothService.setDiscovering(false);
    }
}
