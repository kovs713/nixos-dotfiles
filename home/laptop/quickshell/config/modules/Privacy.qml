import QtQuick
import Quickshell
import Quickshell.Wayland

import "../core" as Core
import "../services" as Services

// Privacy indicator.
//
// Deliberately not part of the bar: the bar is hidden until hovered, so an
// indicator living there would only ever be seen by someone already looking at
// it. This is its own tiny always-on surface, top-left, and it exists only while
// the microphone or the screen is actually being captured.
//
// Input is masked down to the pill, so the rest of the strip stays click-through
// and a screen recording that starts while the mouse is in the corner does not
// steal the click.
PanelWindow {
    id: root

    anchors {
        top: true
        left: true
    }

    margins {
        top: 12
        left: 12
    }

    implicitWidth: pill.width
    implicitHeight: pill.height

    color: "transparent"

    exclusiveZone: 0

    WlrLayershell.namespace: "shell-privacy"

    WlrLayershell.layer: WlrLayer.Overlay

    visible: Services.PrivacyService.active

    // The pill is the only thing that must swallow input, and it must not
    // swallow any: it is informational, so it is masked to its own painted area.
    mask: Region {
        item: pill
    }

    readonly property string label: Services.PrivacyService.screenSharing ? "SCREEN" : "MIC"

    readonly property color tint: Services.PrivacyService.screenSharing ? Core.Theme.error : Core.Theme.warning

    Rectangle {
        id: pill

        width: row.implicitWidth + 20
        height: 24

        radius: height / 2

        color: Qt.rgba(Core.Theme.background.r, Core.Theme.background.g, Core.Theme.background.b, 0.88)

        border.width: 1
        border.color: Core.Theme.panelRim

        Row {
            id: row

            anchors.centerIn: parent

            spacing: 7

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter

                width: 7
                height: 7

                radius: width / 2

                color: root.tint

                // A slow breath rather than a hard blink: recording is a state,
                // not an event, and a blinking dot reads as an alert that is
                // about to resolve itself.
                SequentialAnimation on opacity {
                    running: root.visible
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 0.35
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }

                    NumberAnimation {
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter

                text: root.label

                color: root.tint

                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.fontSizeSmall
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }
        }
    }
}
