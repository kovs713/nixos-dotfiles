import QtQuick

import "../core" as Core
import "../services" as Services

// Network bar module

Core.BarButton {
    id: root

    implicitWidth: 30
    implicitHeight: Core.Theme.moduleHeight

    // A function literal, not a `{ }` block: a block here is a binding, and this
    // one both reads PopupManager.current and writes it, which is a loop.
    onPrimary: function () {
        // Opening with an empty list is the moment a rescan is worth paying for.
        Core.PopupManager.toggle("network", root);

        if (Core.PopupManager.isOpen("network") && Services.NetworkService.networkModel.count === 0)
            Services.NetworkService.rescan();
    }
    onSecondary: Services.NetworkService.openEditor
    onAlternate: function () {
        Services.NetworkService.toggleWifi();
    }
    onScrolled: function (delta) {
        if (delta !== 0)
            Services.NetworkService.toggleWifi();
    }
    popupId: "network"

    readonly property string link: Services.NetworkService.primaryLink

    // The wired glyph is not only "ethernet won": on a host with no radio it is
    // the only link there is, so an unplugged cable still reads as ethernet and
    // not as a wifi icon for hardware that does not exist. Both glyphs stay
    // mounted and cross-fade, which is why this is not a choice of Text.
    readonly property bool showEthernet: root.link === "ethernet" || !Services.NetworkService.wifiAvailable

    // Signal tier, with a deadband

    property int tier: 3

    readonly property int rawSignal: Services.NetworkService.activeSignal

    onRawSignalChanged: {
        const s = root.rawSignal;
        const bounds = [25, 50, 75];
        const dead = 6;

        let t = root.tier;

        while (t < 3 && s >= bounds[t] + dead)
            t++;

        while (t > 0 && s < bounds[t - 1] - dead)
            t--;

        root.tier = t;
    }

    // Ethernet icon

    Text {
        anchors.centerIn: parent

        text: Core.Icons.ethernet

        font.family: Core.Theme.iconFont
        font.pixelSize: Core.Theme.iconSize

        // Muted while the cable is out, which on a wired-only host is the only
        // thing the glyph has left to say.
        color: root.link === "ethernet" ? Core.Theme.foreground : Core.Theme.foregroundMuted

        opacity: root.showEthernet ? 1.0 : 0.0

        scale: root.showEthernet ? 1.0 : 0.6

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuint
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutQuint
            }
        }
    }

    // Wi-Fi icon

    Text {
        anchors.centerIn: parent

        text: {
            const svc = Services.NetworkService;

            if (!svc.wifiEnabled)
                return Core.Icons.wifiOff;

            if (!svc.wifiConnected)
                return Core.Icons.wifiNone;

            if (root.tier >= 3)
                return Core.Icons.wifi3;
            if (root.tier === 2)
                return Core.Icons.wifi2;
            if (root.tier === 1)
                return Core.Icons.wifi1;

            return Core.Icons.wifi0;
        }

        font.family: Core.Theme.iconFont
        font.pixelSize: Core.Theme.iconSize

        color: Services.NetworkService.wifiConnected ? Core.Theme.foreground : Core.Theme.foregroundMuted

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutQuint
            }
        }

        opacity: root.showEthernet ? 0.0 : 1.0

        scale: root.showEthernet ? 0.6 : 1.0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuint
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutQuint
            }
        }
    }

    // Activity dot (connecting / scanning)

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right

        anchors.topMargin: 5
        anchors.rightMargin: 4

        width: 5
        height: 5

        radius: 3

        color: Core.Theme.accent

        opacity: Services.NetworkService.busy || Services.NetworkService.scanning ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutQuint
            }
        }

        SequentialAnimation on scale {
            running: Services.NetworkService.busy || Services.NetworkService.scanning

            loops: Animation.Infinite

            NumberAnimation {
                to: 1.5
                duration: 500
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: 1.0
                duration: 500
                easing.type: Easing.InOutSine
            }
        }
    }

    // Interaction
    // Poll faster while the menu is open
    Binding {
        target: Services.NetworkService
        property: "fastPoll"
        value: root.open
    }
}
