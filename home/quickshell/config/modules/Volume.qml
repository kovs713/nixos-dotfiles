import QtQuick

import "../core" as Core
import "../services" as Services

Core.BarButton {
    id: root

    implicitWidth: 58
    implicitHeight: Core.Theme.moduleHeight

    readonly property var svc: Services.AudioService

    popupId: "audio"

    popTarget: icon

    onSecondary: root.svc.toggleOutputMute
    onAlternate: root.svc.toggleMicMute
    onScrolled: function (delta) {
        root.svc.stepVolume(root.svc.sink, delta > 0 ? 0.05 : -0.05);
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

            color: root.svc.muted ? Core.Theme.foregroundMuted : (root.open ? Core.Theme.accent : Core.Theme.foreground)

            Behavior on color {
                ColorAnimation {
                    duration: 120
                    easing.type: Easing.OutQuint
                }
            }

            onTextChanged: root.pop()
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter

            text: root.svc.volumePercent + "%"

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSize
            font.weight: Font.Medium

            color: root.svc.muted ? Core.Theme.foregroundMuted : Core.Theme.foreground

            renderType: Text.QtRendering
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 1
        anchors.top: parent.top
        anchors.topMargin: 2

        width: 8
        height: 8

        radius: 4

        color: Core.Theme.danger

        visible: root.svc.source !== null && root.svc.micMuted

        scale: visible ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutQuint
            }
        }
    }
}
