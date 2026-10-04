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
        right: true
        bottom: true
    }

    color: "transparent"

    exclusiveZone: 0

    WlrLayershell.namespace: "shell-polkit"

    WlrLayershell.layer: WlrLayer.Overlay

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: Services.PolkitService.active

    readonly property int cardWidth: 400

    Rectangle {
        anchors.fill: parent

        color: Qt.rgba(0, 0, 0, 0.45)

        MouseArea {
            anchors.fill: parent

            onClicked: card.cancel()
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent

        width: root.cardWidth
        height: content.implicitHeight + Core.Theme.padding * 2

        radius: Core.Theme.radiusLarge

        color: Core.Theme.background

        border.width: 1
        border.color: Core.Theme.panelRim

        Keys.onEscapePressed: card.cancel()

        Keys.onReturnPressed: card.accept()
        Keys.onEnterPressed: card.accept()

        function cancel() {
            Services.PolkitService.cancel();
        }

        function accept() {
            Services.PolkitService.submit(input.text);
            Services.PolkitService.reset();

            input.text = "";
        }

        onVisibleChanged: {
            if (visible) {
                input.text = "";
                focusPulse.restart();
            }
        }

        SequentialAnimation {
            id: focusPulse

            running: false

            PauseAnimation {
                duration: 60
            }

            ScriptAction {
                script: input.forceActiveFocus()
            }
        }

        Column {
            id: content

            anchors.centerIn: parent

            width: card.width - Core.Theme.padding * 2

            spacing: 14

            Row {
                spacing: 10

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter

                    width: 30
                    height: 30

                    radius: width / 2

                    color: Core.Theme.accentSoft

                    Text {
                        anchors.centerIn: parent

                        text: Core.Icons.authLock

                        color: Core.Theme.accentActive

                        font.family: Core.Theme.iconFont
                        font.pixelSize: Core.Theme.iconSizeMedium
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter

                    width: parent.width - 40

                    spacing: 2

                    Text {
                        width: parent.width

                        text: "Authentication required"

                        color: Core.Theme.foreground

                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.Theme.fontSizeLarge
                        font.weight: Font.DemiBold

                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width

                        text: Services.PolkitService.message

                        visible: text !== ""

                        color: Core.Theme.foregroundMuted

                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.Theme.fontSize

                        wrapMode: Text.WordWrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                    }
                }
            }

            Core.TextField {
                id: input

                width: parent.width

                visible: Services.PolkitService.responseRequired

                label: Services.PolkitService.inputLabel

                echoPassword: !Services.PolkitService.echo

                Keys.onReturnPressed: card.accept()
                Keys.onEnterPressed: card.accept()
                Keys.onEscapePressed: card.cancel()

                onAccepted: card.accept()
            }

            Text {
                width: parent.width

                text: Services.PolkitService.supplementary

                visible: text !== ""

                color: Services.PolkitService.supplementaryIsError ? Core.Theme.danger : Core.Theme.foregroundFaint

                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.fontSizeSmall

                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            Row {
                anchors.right: parent.right

                spacing: 8

                Rectangle {
                    width: cancelLabel.implicitWidth + 32
                    height: 32

                    radius: Core.Theme.radiusRow

                    color: cancelMouse.containsMouse ? Core.Theme.surfaceHover : Core.Theme.surface

                    Text {
                        id: cancelLabel

                        anchors.centerIn: parent

                        text: "Cancel"

                        color: Core.Theme.foreground

                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.Theme.fontSize
                    }

                    MouseArea {
                        id: cancelMouse

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: card.cancel()
                    }
                }

                Rectangle {
                    width: authLabel.implicitWidth + 32
                    height: 32

                    radius: Core.Theme.radiusRow

                    color: !Services.PolkitService.responseRequired
                        ? Core.Theme.surface
                        : (authMouse.containsMouse ? Core.Theme.accentHover : Core.Theme.accent)

                    Text {
                        id: authLabel

                        anchors.centerIn: parent

                        text: Services.PolkitService.responseRequired ? "Authenticate" : "Continue"

                        color: Core.Theme.accentForeground

                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.Theme.fontSize
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: authMouse

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: card.accept()
                    }
                }
            }
        }
    }
}
