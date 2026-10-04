import QtQuick

import Quickshell.Io

import "../core" as Core
import "../services" as Services

Core.BarButton {
    id: root

    readonly property var nightLight: Services.NightLightService

    implicitWidth: 30
    implicitHeight: Core.Theme.moduleHeight

    onPrimary: root.nightLight.toggle
    onScrolled: function (delta) {
        if (delta !== 0)
            root.nightLight.step(delta > 0);
    }

    Text {
        anchors.centerIn: parent

        text: root.nightLight.active ? Core.Icons.moonWarm : Core.Icons.sunNeutral

        font.family: Core.Theme.iconFont

        font.pixelSize: Core.Theme.iconSize

        color: root.nightLight.active ? Core.Theme.accent : Core.Theme.foregroundMuted
    }

    IpcHandler {
        target: "nightlight"

        function toggle(): void {
            root.nightLight.toggle();
        }
    }
}
