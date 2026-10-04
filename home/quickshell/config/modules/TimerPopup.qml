import QtQuick

import "../core" as Core
import "../services" as Services

// TimerPopup
//
// The pomodoro panel: what is left after the stopwatch went away. One shape, one
// job -- so it reads top to bottom as an answer to "what am I doing, for how
// long, and what happens next", and everything editable is below the fold under
// INTERVALS.
//
// What was missing and is not now: the durations were `readonly` constants in the
// service, so 25/5/15 was not a default but a decision nobody could revisit, and
// the three buttons (Start/Pause, Start/Stop, Lap) were three copies of one
// shape. Skip and Reset are header actions now, so the only filled button left is
// the one that starts and stops the block.

Core.PopupSurface {
    id: popup

    popupId: "timer"

    cardWidth: 340
    maxCardHeight: 470

    // This card is 470px tall, so the window beside it is a strip wide enough to
    // read as desktop. Pressing there is a mis-aim, not a dismissal, and a
    // mis-aim should not cost you the block you were reading. Escape and the
    // cross both still work.
    closeOnOutsideClick: false

    readonly property var svc: Services.TimerService

    // A labelled integer with -/+ at the right. Not a TextField: a number that
    // only has two legal neighbours is a stepper, and typing "0" into a minutes
    // box is a mistake rather than an intention.
    component Stepper: Item {
        id: stepper

        property string text: ""
        property int value: 0
        property int min: 1
        property int max: 120
        property int step: 1
        property string suffix: ""

        signal stepped(int delta)

        implicitHeight: 28

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            text: stepper.text

            color: Core.Theme.foregroundMuted

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSizeSmall
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter

            spacing: 2

            // Greyed rather than hidden: a control that vanishes at its own bound
            // makes the row jump, and the bound is not obvious.
            readonly property bool canDown: stepper.value > stepper.min
            readonly property bool canUp: stepper.value < stepper.max

            Core.IconButton {
                width: 24
                height: 24

                icon: Core.Icons.minus
                color: parent.canDown ? Core.Theme.foreground : Core.Theme.foregroundFaint
                pressScale: parent.canDown ? 0.88 : 1.0

                onClicked: stepper.stepped(-1)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter

                width: 46

                horizontalAlignment: Text.AlignHCenter

                text: stepper.value + stepper.suffix

                color: Core.Theme.foreground

                font.family: Core.Theme.fontMono
                font.pixelSize: Core.Theme.fontSizeSmall
            }

            Core.IconButton {
                width: 24
                height: 24

                icon: Core.Icons.plus
                color: parent.canUp ? Core.Theme.foreground : Core.Theme.foregroundFaint
                pressScale: parent.canUp ? 0.88 : 1.0

                onClicked: stepper.stepped(1)
            }
        }
    }

    contentComponent: Component {
        Column {
            id: body

            width: popup.cardWidth - 24

            spacing: Core.Theme.spacing

            Core.PopupHeader {
                width: body.width

                title: "Pomodoro"

                subtitle: popup.svc.live
                    ? popup.svc.phaseLabel + " · cycle " + (popup.svc.cycle + 1) + " of " + popup.svc.cyclesBeforeLongBreak
                    : "cycle " + (popup.svc.cycle + 1) + " of " + popup.svc.cyclesBeforeLongBreak

                // Close last, where a close button belongs, and for the same
                // reason the chip no longer toggles: dismissing should not need
                // the pointer to come back down to the bar.
                actions: [
                    {
                        icon: Core.Icons.chevronRight,
                        action: function () {
                            popup.svc.skip();
                        }
                    },
                    {
                        icon: Core.Icons.restart,
                        action: function () {
                            popup.svc.reset();
                        }
                    },
                    {
                        icon: Core.Icons.close,
                        action: function () {
                            Core.PopupManager.close();
                        }
                    }
                ]
            }

            // Phase, then the clock. The phase is the accent-coloured word above
            // the digits, so a glance at the panel says "break" without reading a
            // number.
            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: popup.svc.phaseLabel

                color: popup.svc.live ? (popup.svc.isBreak ? Core.Theme.success : Core.Theme.accent) : Core.Theme.foregroundFaint

                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.fontSizeSmall
                font.weight: Font.DemiBold
                font.letterSpacing: 1
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: popup.svc.formatSeconds(popup.svc.secondsLeft)

                color: popup.svc.paused ? Core.Theme.foregroundMuted : Core.Theme.foreground

                font.family: Core.Theme.fontMono
                font.pixelSize: 48
                font.weight: Font.DemiBold
            }

            // Progress as a bar under the clock rather than a ring around it: the
            // panel is 340 wide, a ring that size is mostly empty, and a bar reads
            // the same at a glance for a third of the code.
            Rectangle {
                width: body.width
                height: 4

                radius: 2

                color: Core.Theme.surfaceHover

                Rectangle {
                    width: parent.width * (1.0 - popup.svc.progress)
                    height: parent.height

                    radius: parent.radius

                    color: popup.svc.isBreak ? Core.Theme.success : Core.Theme.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: Core.Theme.durBase
                            easing.type: Easing.Linear
                        }
                    }
                }
            }

            // Which cycle this is, as dots. "Cycle 2 / 4" is a number to parse;
            // three filled and one hollow is read before the eye arrives.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 6

                Repeater {
                    model: popup.svc.cyclesBeforeLongBreak

                    delegate: Rectangle {
                        required property int index

                        width: 6
                        height: 6

                        radius: 3

                        // A long break is the cycle that was earned, so it fills
                        // the row whatever the count says.
                        color: index < popup.svc.cycle
                            ? (popup.svc.isBreak ? Core.Theme.success : Core.Theme.accent)
                            : Core.Theme.surfaceHover
                    }
                }
            }

            // What this block is for.
            Core.TextField {
                width: body.width

                text: popup.svc.label

                placeholder: "What are you working on?"

                onEdited: function (value) {
                    popup.svc.label = value;
                }
            }

            // One filled button, full width: it is the only thing in the panel
            // that has to be found without reading.
            Rectangle {
                width: body.width
                height: 38

                radius: Core.Theme.radiusRow

                color: runMouse.containsMouse ? Core.Theme.accentHover : Core.Theme.accent

                Behavior on color {
                    ColorAnimation {
                        duration: Core.Theme.durFast
                        easing.type: Easing.OutQuint
                    }
                }

                Text {
                    anchors.centerIn: parent

                    text: popup.svc.running ? "Pause" : (popup.svc.paused ? "Resume" : "Start " + popup.svc.phaseLabel.toLowerCase())

                    color: Core.Theme.accentForeground

                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.fontSize
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: runMouse

                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: popup.svc.toggle()
                }
            }

            // Intervals

            Core.SectionHeader {
                width: body.width

                text: "INTERVALS"

                // Only speaks up when the numbers are nobody's preset, which is
                // the one case the row of pills below cannot show.
                trailing: popup.svc.presetId === "custom" ? "Custom" : ""
            }

            // Presets, because picking a shape is faster than stepping four
            // numbers, and because most sessions are one of these three.
            Row {
                width: body.width

                spacing: 6

                Repeater {
                    model: popup.svc.presets

                    delegate: Rectangle {
                        required property var modelData

                        readonly property bool active: popup.svc.presetId === modelData.id

                        width: presetText.implicitWidth + 22
                        height: 26

                        radius: Core.Theme.radiusRow

                        color: active ? Core.Theme.accent : (presetMouse.containsMouse ? Core.Theme.surfaceHover : Core.Theme.surface)

                        Behavior on color {
                            ColorAnimation {
                                duration: Core.Theme.durFast
                                easing.type: Easing.OutQuint
                            }
                        }

                        Text {
                            id: presetText

                            anchors.centerIn: parent

                            text: modelData.label

                            color: parent.active ? Core.Theme.accentForeground : Core.Theme.foregroundMuted

                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.Theme.fontSizeSmall
                        }

                        MouseArea {
                            id: presetMouse

                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: popup.svc.applyPreset(modelData.id)
                        }
                    }
                }
            }

            Stepper {
                width: body.width

                text: "Focus"

                value: popup.svc.focusMinutes
                suffix: " min"
                step: 5

                onStepped: function (delta) {
                    popup.svc.setFocusMinutes(popup.svc.focusMinutes + delta * 5);
                }
            }

            Stepper {
                width: body.width

                text: "Break"

                value: popup.svc.breakMinutes
                suffix: " min"
                step: 1
                max: 60

                onStepped: function (delta) {
                    popup.svc.setBreakMinutes(popup.svc.breakMinutes + delta);
                }
            }

            Stepper {
                width: body.width

                text: "Long break"

                value: popup.svc.longBreakMinutes
                suffix: " min"
                step: 5
                max: 90

                onStepped: function (delta) {
                    popup.svc.setLongBreakMinutes(popup.svc.longBreakMinutes + delta * 5);
                }
            }

            Stepper {
                width: body.width

                text: "Cycles before long"

                value: popup.svc.cyclesBeforeLongBreak
                max: 12

                onStepped: function (delta) {
                    popup.svc.setCycles(popup.svc.cyclesBeforeLongBreak + delta);
                }
            }
        }
    }
}
