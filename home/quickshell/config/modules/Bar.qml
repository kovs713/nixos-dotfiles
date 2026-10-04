import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "." as Mods
import "../core" as Core
import "../services" as Services

PanelWindow {
    id: root

    anchors {
        bottom: true
        left: true
        right: true
    }

    margins.bottom: 0

    implicitHeight: root.surfaceTop + Core.Theme.launcherMaxHeight + 40

    color: "transparent"

    exclusiveZone: 0

    WlrLayershell.namespace: "shell-bar"

    WlrLayershell.keyboardFocus: root.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property int surfaceTop: Core.Theme.barMarginTop

    readonly property var launchers: [appLauncher, reminderPicker, clipboardView, emojiPicker]

    readonly property var activeLauncher: {
        const list = root.launchers;
        const id = Core.PopupManager.current;

        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].launcherId === id)
                return list[i];
        }

        return null;
    }

    readonly property bool launcherOpen: root.activeLauncher !== null

    property Region surfaceInput: Region {
        item: surface
    }

    property Region edgeInput: Region {
        item: edge
    }

    property Region barInput: Region {
        regions: [root.surfaceInput, root.edgeInput]
    }

    mask: root.launcherOpen ? null : root.barInput

    readonly property bool modulePopupOpen: {
        const id = Core.PopupManager.current;

        if (id === "")
            return false;

        const list = root.launchers;

        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].launcherId === id)
                return false;
        }

        return true;
    }

    readonly property bool wantExpanded: !root.launcherOpen && ((root.autoReveal && (surfaceHover.hovered || edgeHover.hovered)) || root.modulePopupOpen)

    property bool autoReveal: true
    property bool expanded: false

    onWantExpandedChanged: {
        if (root.wantExpanded) {
            collapseTimer.stop();
            root.expanded = true;
            return;
        }

        collapseTimer.restart();
    }

    Timer {
        id: collapseTimer

        interval: Core.Theme.barCollapseDelay

        onTriggered: root.expanded = root.wantExpanded
    }

    property real reveal: root.expanded ? 1.0 : 0.0

    Behavior on reveal {
        NumberAnimation {
            duration: root.launcherOpen ? 0 : (root.expanded ? Core.Theme.barRevealDuration : Core.Theme.barHideDuration)
            easing.type: Easing.OutQuint
        }
    }

    property bool fromPill: false

    property bool closing: false

    function releasePill() {
        root.fromPill = false;
    }

    onLauncherOpenChanged: {
        collapseTimer.stop();
        root.expanded = false;

        if (root.launcherOpen) {
            closeTimer.stop();
            root.closing = false;

            root.fromPill = true;
            Qt.callLater(root.releasePill);
            return;
        }

        root.fromPill = false;
        root.closing = true;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer

        interval: Core.Theme.barRevealDuration

        onTriggered: root.closing = false
    }

    readonly property bool showing: root.reveal > 0.012 || root.osdMix > 0.01

    readonly property bool modulesVisible: root.reveal > 0.012 && !root.launcherOpen

    readonly property bool osd: Core.OsdController.active && !root.expanded && !root.launcherOpen

    property real osdMix: root.osd ? 1.0 : 0.0

    Behavior on osdMix {
        NumberAnimation {
            duration: root.launcherOpen ? 0 : Core.Theme.barRevealDuration
            easing.type: Easing.OutQuint
        }
    }

    readonly property real barContentWidth: root.showing
        ? content.implicitWidth + (osdView.implicitWidth - content.implicitWidth) * root.osdMix
        : 0

    readonly property bool popupShape: root.launcherOpen && !root.fromPill

    readonly property real targetWidth: root.popupShape
        ? root.activeLauncher.cardWidth
        : (root.showing ? root.barContentWidth + 24 : 240)

    readonly property real targetHeight: root.popupShape ? root.activeLauncher.viewHeight : Core.Theme.pillHeight

    readonly property real targetRadius: root.popupShape ? Core.Theme.radiusLarge : Core.Theme.pillHeight / 2

    readonly property int morphDuration: root.fromPill ? 0 : ((root.launcherOpen || root.closing) ? Core.Theme.barRevealDuration : 0)

    Item {
        id: edge

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        height: Core.Theme.barMarginTop

        HoverHandler {
            id: edgeHover
        }
    }

    Rectangle {
        id: surface

        anchors.horizontalCenter: parent.horizontalCenter

        y: parent.height - root.surfaceTop - height

        readonly property bool showing: root.showing || root.launcherOpen

        width: root.targetWidth

        height: root.targetHeight

        radius: root.targetRadius

        color: surface.showing ? Core.Theme.surface : "transparent"

        border.width: 1
        border.color: surface.showing ? Core.Theme.panelRim : "transparent"

        antialiasing: true

        clip: root.launcherOpen

        Behavior on width {
            NumberAnimation {
                duration: root.morphDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: root.morphDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: root.morphDuration
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            id: surfaceHover
        }

        Mods.BarOsd {
            id: osdView

            anchors.centerIn: parent

            opacity: root.osdMix

            visible: root.osdMix > 0.01 && !root.launcherOpen

            transform: Translate {
                y: (1.0 - root.osdMix) * 4
            }
        }

        RowLayout {
            id: content

            anchors.centerIn: parent

            spacing: 3

            opacity: 1.0 - root.osdMix

            visible: root.showing && root.osdMix < 0.99 && !root.launcherOpen

            BarSlot {
                reveal: root.reveal

                Mods.NotificationCenter { id: notificationCenter }
            }

            Separator {}

            BarSlot {
                reveal: root.reveal

                Mods.Volume { id: volume }
            }

            Separator {}

            BarSlot {
                reveal: root.reveal

                available: Services.BrightnessService.available

                Mods.Brightness { id: brightness }
            }

            Separator {
                available: Services.BrightnessService.available
            }

            BarSlot {
                reveal: root.reveal

                Mods.NightLight { id: nightLight }
            }

            Separator {}

            BarSlot {
                reveal: root.reveal

                Mods.Timer { id: timer }
            }

            Separator {}

            Mods.Clock {
                id: clockModule

                Layout.preferredWidth: clockModule.implicitWidth

                Layout.preferredHeight: clockModule.implicitHeight
            }

            Separator {}

            BarSlot {
                reveal: root.reveal

                available: Services.NetworkService.available

                Mods.Network { id: network }
            }

            Separator {
                available: Services.NetworkService.available
            }

            BarSlot {
                reveal: root.reveal

                available: Services.BluetoothService.available

                Mods.Bluetooth { id: bluetooth }
            }

            Separator {
                available: Services.BluetoothService.available
            }

            BarSlot {
                reveal: root.reveal

                available: Services.BatteryService.available

                Mods.Battery { id: battery }
            }

            Separator {
                available: Services.BatteryService.available
            }

            Mods.Tray {
                id: tray

                barWindow: root

                Layout.preferredWidth: tray.implicitWidth * root.reveal

                Layout.preferredHeight: tray.implicitHeight

                visible: root.modulesVisible

                opacity: root.reveal
            }
        }

        Item {
            anchors.fill: parent

            visible: root.launcherOpen

            Mods.AppLauncher {
                id: appLauncher

                anchors.fill: parent
            }

            Mods.ReminderPicker {
                id: reminderPicker

                anchors.fill: parent
            }

            Mods.Clipboard {
                id: clipboardView

                anchors.fill: parent
            }

            Mods.EmojiPicker {
                id: emojiPicker

                anchors.fill: parent
            }
        }
    }

    MouseArea {
        anchors.fill: parent

        z: -1

        enabled: root.launcherOpen

        acceptedButtons: Qt.LeftButton

        onClicked: Core.PopupManager.close()
    }

    IpcHandler {
        target: "bar"

        function toggleAutoReveal(): void {
            root.autoReveal = !root.autoReveal;
        }
    }

    component BarSlot: Item {
        id: slot

        property real reveal: 1.0

        property bool available: true

        readonly property Item module: slot.children.length > 0 ? slot.children[0] : null

        Layout.preferredWidth: slot.module ? slot.module.implicitWidth * slot.reveal : 0

        Layout.preferredHeight: slot.module ? slot.module.implicitHeight : 0

        Binding {
            target: slot.module

            property: "width"

            value: slot.width
        }

        Binding {
            target: slot.module

            property: "height"

            value: slot.height
        }

        visible: slot.available && slot.reveal > 0.012

        opacity: slot.reveal
    }

    component Separator: Item {
        id: sep

        property real reveal: root.reveal

        property bool available: true

        readonly property color tint: Core.Theme.separator

        Layout.preferredWidth: 1

        Layout.preferredHeight: 18

        visible: sep.available && sep.reveal > 0.012

        opacity: sep.reveal * 0.9

        Rectangle {
            anchors.centerIn: parent

            width: 1

            height: parent.height

            antialiasing: true

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(sep.tint.r, sep.tint.g, sep.tint.b, 0.0)
                }

                GradientStop {
                    position: 0.32
                    color: sep.tint
                }

                GradientStop {
                    position: 0.68
                    color: sep.tint
                }

                GradientStop {
                    position: 1.0
                    color: Qt.rgba(sep.tint.r, sep.tint.g, sep.tint.b, 0.0)
                }
            }
        }
    }
}
