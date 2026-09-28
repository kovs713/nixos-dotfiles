import QtQuick

import "../core" as Core
import "../services" as Services

// Battery bar module

Core.BarButton {
    id: root

    implicitWidth: 58
    implicitHeight: Core.Theme.moduleHeight

    popupId: "battery"

    readonly property var svc: Services.BatteryService

    // Hide the module entirely on desktops with no battery.
    visible: root.svc.available

    popTarget: icon

    onPrimary: function () {
        Core.PopupManager.toggle("battery", root);
    }
    onSecondary: root.svc.openPowerSettings
    onAlternate: function () {
        root.cycleProfile();
    }
    onScrolled: function (delta) {
        if (delta !== 0)
            root.cycleProfile(delta > 0 ? 1 : -1);
    }

    // Critical-battery breathing glow

    Rectangle {
        anchors.fill: parent

        radius: height / 2

        color: "transparent"

        border.width: 0
        border.color: Core.Theme.danger

        opacity: root.svc.critical ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuint
            }
        }

        SequentialAnimation on scale {
            running: root.svc.critical
            loops: Animation.Infinite

            NumberAnimation {
                to: 1.06
                duration: 700
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: 1.0
                duration: 700
                easing.type: Easing.InOutSine
            }
        }
    }

    Row {
        anchors.centerIn: parent

        spacing: 5

        Text {
            id: icon

            anchors.verticalCenter: parent.verticalCenter

            text: root.svc.icon

            font.family: Core.Theme.iconFont
            font.pixelSize: Core.Theme.iconSize

            color: root.svc.color

            Behavior on color {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.OutQuint
                }
            }

            // Pop whenever the glyph changes (level crossed, charger plugged in, etc.)
            onTextChanged: root.pop()
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter

            text: root.svc.percentInt + "%"

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSize
            font.weight: Font.Medium

            color: root.svc.critical ? Core.Theme.danger : root.svc.low ? Core.Theme.warning : Core.Theme.foreground

            Behavior on color {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.OutQuint
                }
            }
        }
    }

    // Interaction

    function cycleProfile(direction) {
        if (!root.svc.profilesAvailable)
            return;
        const step = direction === undefined ? 1 : direction;

        const max = root.svc.hasPerformance ? 2 : 1;

        // From what was asked for, not from what powerprofilesd has echoed back:
        // a press inside the round trip would otherwise compute the same next
        // value again, so a burst of presses was one change.
        let next = root.svc.requestedProfile + step;

        if (next > max)
            next = 0;

        if (next < 0)
            next = max;

        root.svc.setProfile(next);
    }
}
