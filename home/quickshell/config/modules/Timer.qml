import QtQuick

import "../core" as Core
import "../services" as Services

Core.BarButton {
    id: root

    readonly property var svc: Services.TimerService

    readonly property bool active: root.svc.live

    onPrimary: function () {
        Core.PopupManager.toggle("timer", root);
    }
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

    implicitWidth: 66
    implicitHeight: Core.Theme.moduleHeight

    popupId: "timer"

    Row {
        anchors.centerIn: parent

        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter

            text: root.svc.phase === "focus" ? Core.Icons.target : Core.Icons.timerSand

            font.family: Core.Theme.iconFont
            font.pixelSize: Core.Theme.iconSize

            color: !root.active ? Core.Theme.foregroundFaint : Core.Theme.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter

            text: {
                root.svc.tick;

                return root.svc.formatSeconds(root.svc.secondsLeft);
            }

            font.family: Core.Theme.fontMono
            font.pixelSize: Core.Theme.fontSize

            font.weight: Font.Medium

            color: !root.active ? Core.Theme.foregroundFaint : (root.svc.paused ? Core.Theme.foregroundMuted : Core.Theme.foreground)

            renderType: Text.QtRendering
        }
    }
}
