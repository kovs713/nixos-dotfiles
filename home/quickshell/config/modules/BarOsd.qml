import QtQuick

import "../core" as Core
import "../services" as Services

Item {
    id: root

    readonly property string kind: Core.OsdController.kind

    readonly property real raw: {
        if (root.kind === "brightness")
            return Services.BrightnessService.fraction;

        if (root.kind === "mic")
            return Services.AudioService.micVolume;

        return Services.AudioService.volume;
    }

    readonly property real value: Math.max(0, Math.min(1, root.raw))

    readonly property bool muted: {
        if (root.kind === "brightness")
            return false;

        if (root.kind === "mic")
            return Services.AudioService.micMuted;

        return Services.AudioService.muted;
    }

    implicitWidth: row.implicitWidth
    implicitHeight: Core.Theme.moduleHeight

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

        Rectangle {
            id: track

            width: 96
            height: 4

            anchors.verticalCenter: parent.verticalCenter

            radius: 2

            color: Core.Theme.surface

            Rectangle {
                height: parent.height

                radius: parent.radius

                width: Math.round(track.width * root.value)

                color: root.tint

                antialiasing: true

                Behavior on color {
                    ColorAnimation {
                        duration: Core.Theme.durFast
                        easing.type: Easing.OutQuint
                    }
                }
            }
        }

        Text {
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
