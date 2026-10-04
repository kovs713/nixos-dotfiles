import QtQuick

import Quickshell.Io

import "../core" as Core
import "../services" as Services

// Night light (bar module).
//
// The sun means the display is at its native temperature and the moon means it
// is shifted, so the state is readable from the bar without opening anything.
// There is no number: the control is a toggle between native and warm, so a
// readout of an intermediate temperature would describe a value the user cannot
// reach by clicking. The wheel still moves it, and the next click turns it off
// from wherever the wheel left it.

Core.BarButton {
    id: root

    readonly property var nightLight: Services.NightLightService

    implicitWidth: 30
    implicitHeight: Core.Theme.moduleHeight

    // A toggle, not a stepper: there is nothing to configure behind it, and the
    // row of temperatures is a choice the rest of the shell does not offer.
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

    // The keybind goes through the service rather than running `sct` itself: a
    // hyprland-side `sct 3000` would move the display without touching the
    // service's state file, and the bar would go on showing the old value.
    IpcHandler {
        target: "nightlight"

        function toggle(): void {
            root.nightLight.toggle();
        }
    }

}
