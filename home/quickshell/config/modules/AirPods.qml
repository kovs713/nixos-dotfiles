import QtQuick

import "../core" as Core
import "../services" as Services

Core.BarButton {
    id: root

    implicitWidth: 30
    implicitHeight: Core.Theme.moduleHeight

    popupId: "airpods"

    popTarget: icon

    readonly property var svc: Services.AirPodsService

    onSecondary: function () {
        svc.cycleNoiseMode();
    }

    // The daemon reports the pods whether or not the audio link is up, so the mark
    // follows the daemon and not connected: a battery arrives over BLE with the
    // link down.
    readonly property bool live: svc.running && svc.connected

    readonly property bool low: svc.lowestLevel > 0 && svc.lowestLevel < 20

    Text {
        id: icon

        anchors.centerIn: parent

        text: Core.Icons.headset

        font.family: Core.Theme.iconFont
        font.pixelSize: Core.Theme.iconSize

        color: !root.svc.running ? Core.Theme.foregroundFaint : root.low ? Core.Theme.danger : root.live ? Core.Theme.accent : Core.Theme.foreground

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutQuint
            }
        }
    }
}