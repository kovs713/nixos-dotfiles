import QtQuick

import "../core" as Core
import "../services" as Services

// BarOsd

Item {
    id: root

    readonly property string kind: Core.OsdController.kind

    // Read live, by kind. The controller says which readout; the value is
    // whatever the service says right now, so nothing here can be a step
    // behind -- see the note on OsdController.
    readonly property real raw: {
        if (root.kind === "brightness")
            return Services.BrightnessService.fraction;

        if (root.kind === "mic")
            return Services.AudioService.micVolume;

        return Services.AudioService.volume;
    }

    // The clamp that used to be inside `show()`, and it has to be somewhere: a
    // sink is not 0..1. This one is left at 115% by an absolute set, and an
    // unclamped 1.15 would draw 110px of fill on a 96px track.
    readonly property real value: Math.max(0, Math.min(1, root.raw))

    // Brightness has no mute, so it never borrows the danger colour.
    readonly property bool muted: {
        if (root.kind === "brightness")
            return false;

        if (root.kind === "mic")
            return Services.AudioService.micMuted;

        return Services.AudioService.muted;
    }

    implicitWidth: row.implicitWidth
    implicitHeight: Core.Theme.moduleHeight

    // Colour + glyph per kind

    readonly property color tint: root.muted ? Core.Theme.danger : Core.Theme.accent

    readonly property string glyph: {
        if (root.kind === "brightness")
            return Core.Icons.forBrightness(root.value);

        if (root.kind === "mic")
            return root.muted ? Core.Icons.micOff : Core.Icons.mic;

        if (root.muted)
            return Core.Icons.volumeOff;

        if (root.value >= 0.66)
            return Core.Icons.volumeHigh;

        if (root.value >= 0.33)
            return Core.Icons.volumeMedium;

        return Core.Icons.volumeLow;
    }

    Row {
        id: row

        anchors.centerIn: parent

        spacing: 8

        // Icon

        Text {
            width: 20

            anchors.verticalCenter: parent.verticalCenter

            horizontalAlignment: Text.AlignHCenter

            text: root.glyph

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.iconSize

            color: root.tint

            Behavior on color {
                ColorAnimation {
                    duration: Core.Theme.durFast
                    easing.type: Easing.OutQuint
                }
            }
        }

        // Track

        Rectangle {
            id: track

            width: 96
            height: 4

            anchors.verticalCenter: parent.verticalCenter

            radius: 2

            color: Core.Theme.surface

            Rectangle {
                id: fill

                height: parent.height

                radius: parent.radius

                width: Math.round(track.width * root.value)

                color: root.tint

                antialiasing: true

                // No animation on the width, and the reason is the value it
                // follows rather than the width itself: a held volume or
                // brightness key is a new target every 40ms, and a 180ms
                // Behavior retargeted that often never arrives -- it covered
                // 40% of each step before the next one landed, so the bar crept
                // at half the key's speed and sat a few points behind its own
                // readout for the whole hold. The readout is a meter: it is
                // right when it is equal to the number beside it. The OSD still
                // eases in, on osdMix.

                Behavior on color {
                    ColorAnimation {
                        duration: Core.Theme.durFast
                        easing.type: Easing.OutQuint
                    }
                }
            }
        }

        // Readout

        Text {
            // 40, and it is the width of the widest thing this can say: "100%",
            // measured at 36.9px in SF Pro Display Medium. 34 was a three
            // character box, so the value that a brightness key reaches at the
            // top of its range painted 3px outside it.
            width: 40

            anchors.verticalCenter: parent.verticalCenter

            horizontalAlignment: Text.AlignRight

            text: root.muted && root.kind !== "brightness" ? "off" : Math.round(root.value * 100) + "%"

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSize
            font.weight: Font.Medium

            color: Core.Theme.foreground

            renderType: Text.QtRendering
        }
    }
}
