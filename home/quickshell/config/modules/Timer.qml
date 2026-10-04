import QtQuick

import "../core" as Core
import "../services" as Services

// Pomodoro (bar module)
//
// The chip always shows a clock. It used to show a four-pixel dot when nothing
// was counting, on the grounds that "a permanently visible 25:00 is noise" --
// but the bar is hidden until hovered anyway, so the dot was never anything but
// a gap with a speck in it, and it said nothing about what the timer was set
// to. Idle now reads as a full block, dimmed: you can see what pressing it will
// start.
//
// Left opens the panel, which is where the intervals live. Right starts or
// pauses from the bar. The wheel ends the current block, which is the one
// pomodoro action that would otherwise need a trip through the panel.

Core.BarButton {
    id: root

    readonly property var svc: Services.TimerService

    readonly property bool active: root.svc.live

    // toggle, not open. An `open` here means a second press on the chip is a
    // no-op, and the chip is the one control the user is looking AT while the
    // card is up -- pressing the thing that opened something is the most natural
    // way to close it. The objection was that a second press is "usually the one
    // aimed at a button on the card", which is true of the CARD and false of the
    // chip: the card is 340 wide and the bar sits 20px below it, so the two do
    // not overlap and a press that lands on the chip cannot be a mis-aim.
    onPrimary: function () {
        Core.PopupManager.toggle("timer", root);
    }
    // Middle opens it too. It always did -- the old handler dispatched only on the
    // right button and let everything else fall through to the toggle -- but by
    // accident, so it is written down here.
    onAlternate: function () {
        Core.PopupManager.toggle("timer", root);
    }

    onSecondary: function () {
        root.svc.toggle();
    }

    onScrolled: function (delta) {
        if (delta !== 0)
            root.svc.skip();
    }

    // Fixed like the other bar modules: the bar must not resize as the digits
    // change, or everything to the right of it would shuffle every second. Wide
    // enough for "25:00" plus the glyph, which is what it shows when idle.
    implicitWidth: 66
    implicitHeight: Core.Theme.moduleHeight

    popupId: "timer"

    Row {
        anchors.centerIn: parent

        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter

            // A break and a focus block are different states, not shades of one:
            // the glyph is the fastest way to tell them apart at a glance.
            text: root.svc.phase === "focus" ? Core.Icons.target : Core.Icons.timerSand

            font.family: Core.Theme.iconFont
            font.pixelSize: Core.Theme.iconSize

            color: !root.active ? Core.Theme.foregroundFaint : Core.Theme.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter

            // Reads root.svc.tick so the binding re-evaluates; the formatted
            // string is derived from the wall clock.
            text: {
                root.svc.tick;

                return root.svc.formatSeconds(root.svc.secondsLeft);
            }

            font.family: Core.Theme.fontMono
            font.pixelSize: Core.Theme.fontSize

            font.weight: Font.Medium

            // Frozen is not off: a paused block is dimmer than a running one and
            // dimmer still before it starts, so the three states are readable
            // without opening the panel.
            color: !root.active ? Core.Theme.foregroundFaint : (root.svc.paused ? Core.Theme.foregroundMuted : Core.Theme.foreground)

            renderType: Text.QtRendering
        }
    }
}
