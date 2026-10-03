import QtQuick

import Quickshell

import "../core" as Core

// Clock (bar module)

Core.BarButton {
    id: root

    implicitWidth: showSeconds ? 72 : 48
    implicitHeight: Core.Theme.moduleHeight

    property bool showSeconds: false

    onSecondary: function () {
        root.showSeconds = !root.showSeconds;
    }

    popupId: "calendar"

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuint
        }
    }

    SystemClock {
        id: systemClock

        precision: root.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Row {
        anchors.centerIn: parent

        spacing: 0

        Text {
            text: Qt.formatDateTime(systemClock.date, "HH")

            color: root.open ? Core.Theme.accent : Core.Theme.foreground

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSize
            font.weight: Font.Medium

            renderType: Text.QtRendering

            Behavior on color {
                ColorAnimation {
                    duration: 120
                    easing.type: Easing.OutQuint
                }
            }
        }

        Text {
            text: ":"

            color: root.open ? Core.Theme.accent : Core.Theme.foregroundMuted

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSize
            font.weight: Font.Medium

            renderType: Text.QtRendering

            Behavior on color {
                ColorAnimation {
                    duration: 120
                    easing.type: Easing.OutQuint
                }
            }
        }

        Text {
            text: Qt.formatDateTime(systemClock.date, "mm")

            // The minutes are the accent whether the calendar is open or not:
            // `clockMinute` resolved to `accent` through the theme's `ui.clock`
            // key, which no theme wrote, so the open/closed branch was picking
            // the same colour twice.
            color: Core.Theme.accent

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSize
            font.weight: Font.Medium

            renderType: Text.QtRendering

            Behavior on color {
                ColorAnimation {
                    duration: 120
                    easing.type: Easing.OutQuint
                }
            }
        }

        Text {
            visible: root.showSeconds

            text: ":"

            color: Core.Theme.foregroundMuted

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSize
            font.weight: Font.Medium

            renderType: Text.QtRendering
        }

        Text {
            visible: root.showSeconds

            text: Qt.formatDateTime(systemClock.date, "ss")

            color: Core.Theme.foregroundFaint

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSize
            font.weight: Font.Medium

            renderType: Text.QtRendering
        }
    }
}
