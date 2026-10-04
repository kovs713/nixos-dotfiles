import QtQuick
import Quickshell
import Quickshell.Wayland

import "../core" as Core
import "../services" as Services

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
