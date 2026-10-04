import QtQuick

import Quickshell

import "../core" as Core
import "../services" as Services

Core.PopupSurface {
    id: popup

    popupId: "network"

    cardWidth: 340
    maxCardHeight: 470

    readonly property var svc: Services.NetworkService

    property string passwordFor: ""
    property string passwordError: ""

    property string passwordText: ""

    onDidClose: {
        popup.passwordFor = "";
        popup.passwordError = "";
        popup.passwordText = "";
    }

    Connections {
        target: popup.svc

        function onConnectFailed(ssid, message) {
            if (popup.passwordFor === ssid || popup.passwordFor === "") {
                popup.passwordFor = ssid;
                popup.passwordError = "Could not connect — check the password";
            }
        }

        function onConnectSucceeded(ssid) {
            if (popup.passwordFor === ssid) {
                popup.passwordFor = "";
                popup.passwordError = "";
                popup.passwordText = "";
            }
        }
    }

    function requestConnect(ssid, secured, saved) {
        if (secured && !saved) {
            popup.passwordError = "";
            popup.passwordFor = ssid;
            popup.passwordText = "";
            return;
        }

        popup.passwordFor = "";
        popup.svc.connectWifi(ssid, "");
    }

    contentComponent: Component {
        Column {
            spacing: Core.Theme.spacing

            Core.PopupHeader {
                width: parent.width

                title: "Network"

                subtitle: popup.svc.linkLabel

                showToggle: popup.svc.wifiAvailable

                toggled: popup.svc.wifiEnabled

                onToggleRequested: popup.svc.toggleWifi()

                actions: {
                    const out = [];

                    if (popup.svc.wifiAvailable)
                        out.push({
                            icon: Core.Icons.refresh,
                            spinning: popup.svc.scanning,
                            action: function () {
                                popup.svc.rescan();
                            }
                        });

                    out.push({
                        icon: Core.Icons.gear,
                        action: function () {
                            popup.svc.openEditor();
                            Core.PopupManager.close();
                        }
                    });

                    return out;
                }
            }

            Item {
                width: parent.width

                clip: true

                height: popup.svc.ethAvailable ? ethColumn.implicitHeight : 0

                opacity: popup.svc.ethAvailable ? 1.0 : 0.0

                Behavior on height {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutQuint
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuint
                    }
                }

                Column {
                    id: ethColumn

                    width: parent.width

                    spacing: 2

                    Core.SectionHeader {
                        width: parent.width

                        text: "WIRED"
                    }

                    Core.ListRow {
                        width: parent.width

                        icon: Core.Icons.ethernet

                        title: popup.svc.ethConnection !== "" ? popup.svc.ethConnection : "Ethernet"

                        subtitle: popup.svc.ethConnected ? "Connected · " + popup.svc.ethDevice : popup.svc.ethState === "unavailable" ? "Cable unplugged" : "Disconnected · " + popup.svc.ethDevice

                        trailing: popup.svc.ethConnected ? Core.Icons.checkCircle : ""

                        trailingColor: Core.Theme.success

                        active: popup.svc.ethConnected

                        dimmed: popup.svc.ethState === "unavailable"

                        onActivated: {
                            popup.svc.toggleEthernet();
                        }

                        onContextRequested: function (mx, my) {
                            popup.openMenu(mx, my, [
                                {
                                    icon: popup.svc.ethConnected ? Core.Icons.linkOff : Core.Icons.link,
                                    label: popup.svc.ethConnected ? "Disconnect" : "Connect",
                                    action: function () {
                                        popup.svc.toggleEthernet();
                                    }
                                },
                                {
                                    icon: Core.Icons.refresh,
                                    label: "Reconnect",
                                    action: function () {
                                        popup.svc.disconnectEthernet();
                                        popup.svc.connectEthernet(true);
                                    }
                                },
                                {
                                    separator: true
                                },
                                {
                                    icon: Core.Icons.gear,
                                    label: "Wired settings",
                                    action: function () {
                                        popup.svc.openEditor();
                                        Core.PopupManager.close();
                                    }
                                }
                            ]);
                        }
                    }
                }
            }

            Item {
                width: parent.width

                clip: true

                height: popup.svc.wifiAvailable ? wifiColumn.implicitHeight : 0

                opacity: popup.svc.wifiAvailable ? 1.0 : 0.0

                Behavior on height {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutQuint
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuint
                    }
                }

                Column {
                    id: wifiColumn

                    width: parent.width

                    spacing: Core.Theme.spacing

                    Core.SectionHeader {
                        width: parent.width

                        text: "WI-FI"

                        trailing: popup.svc.scanning ? "scanning…" : popup.svc.networkModel.count + " found"

                        trailingOpacity: popup.svc.wifiEnabled ? 1.0 : 0.0

                        Behavior on trailingOpacity {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutQuint
                            }
                        }
                    }

                    Item {
                        width: parent.width

                        clip: true

                        height: popup.passwordFor !== "" ? pwColumn.implicitHeight + 6 : 0

                        opacity: popup.passwordFor !== "" ? 1.0 : 0.0

                        Behavior on height {
                            NumberAnimation {
                                duration: Core.Theme.durBase
                                easing.type: Easing.OutQuint
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutQuint
                            }
                        }

                        Column {
                            id: pwColumn

                            width: parent.width

                            spacing: 4

                            Row {
                                width: parent.width

                                spacing: 6

                                Core.TextField {
                                    id: pwField

                                    width: parent.width - 32

                                    text: popup.passwordText

                                    icon: Core.Icons.lock

                                    placeholder: "Password for " + popup.passwordFor

                                    echoPassword: true

                                    onEdited: function (value) {
                                        popup.passwordText = value;
                                    }

                                    onAccepted: {
                                        if (text === "")
                                            return;

                                        popup.svc.connectWifi(popup.passwordFor, text);
                                    }
                                }

                                Core.IconButton {
                                    width: 26
                                    height: 26

                                    anchors.verticalCenter: parent.verticalCenter

                                    icon: Core.Icons.check

                                    color: pwField.text !== "" ? Core.Theme.accent : Core.Theme.foregroundFaint

                                    onClicked: {
                                        if (pwField.text === "")
                                            return;

                                        popup.svc.connectWifi(popup.passwordFor, pwField.text);
                                    }
                                }
                            }

                            Text {
                                width: parent.width

                                visible: popup.passwordError !== ""

                                text: popup.passwordError

                                leftPadding: 10

                                wrapMode: Text.WordWrap

                                font.family: Core.Theme.fontFamily
                                font.pixelSize: Core.Theme.fontSizeSmall

                                color: Core.Theme.danger
                            }
                        }
                    }

                    Core.ExpandableList {
                        id: list

                        width: parent.width

                        maxHeight: 250

                        expanded: popup.svc.wifiEnabled

                        animated: false

                        model: popup.svc.networkModel

                        delegate: Core.ListRow {
                            id: netRow

                            required property string ssid
                            required property int strength
                            required property string security
                            required property bool secured
                            required property bool inUse
                            required property bool saved

                            width: list.width

                            icon: popup.svc.signalIcon(netRow.strength, netRow.secured)

                            title: netRow.ssid

                            subtitle: netRow.inUse ? "Connected" : (netRow.saved ? "Saved · " : "") + (netRow.secured ? netRow.security : "Open")

                            trailing: netRow.secured ? Core.Icons.lock + " " + netRow.strength + "%" : netRow.strength + "%"

                            active: netRow.inUse

                            busy: popup.svc.pendingSsid === netRow.ssid && popup.svc.busy

                            onActivated: {
                                if (netRow.inUse) {
                                    popup.svc.disconnectWifi();
                                    return;
                                }

                                popup.requestConnect(netRow.ssid, netRow.secured, netRow.saved);
                            }

                            onContextRequested: function (mx, my) {
                                const items = [];

                                if (netRow.inUse) {
                                    items.push({
                                        icon: Core.Icons.linkOff,
                                        label: "Disconnect",
                                        action: function () {
                                            popup.svc.disconnectWifi();
                                        }
                                    });
                                } else {
                                    items.push({
                                        icon: Core.Icons.link,
                                        label: netRow.saved ? "Connect" : "Connect…",
                                        action: function () {
                                            popup.requestConnect(netRow.ssid, netRow.secured, netRow.saved);
                                        }
                                    });
                                }

                                if (netRow.saved) {
                                    items.push({
                                        icon: Core.Icons.refresh,
                                        label: "Reconnect",
                                        action: function () {
                                            popup.svc.disconnectWifi();
                                            popup.svc.connectWifi(netRow.ssid, "");
                                        }
                                    });

                                    items.push({
                                        icon: Core.Icons.check,
                                        label: "Enable autoconnect",
                                        action: function () {
                                            popup.svc.setAutoconnect(netRow.ssid, true);
                                        }
                                    });

                                    items.push({
                                        icon: Core.Icons.close,
                                        label: "Disable autoconnect",
                                        action: function () {
                                            popup.svc.setAutoconnect(netRow.ssid, false);
                                        }
                                    });
                                }

                                items.push({
                                    separator: true
                                });

                                items.push({
                                    icon: Core.Icons.copy,
                                    label: "Copy SSID",
                                    action: function () {
                                        Quickshell.clipboardText = netRow.ssid;
                                    }
                                });

                                items.push({
                                    icon: Core.Icons.info,
                                    label: "Network details",
                                    action: function () {
                                        popup.svc.openEditor();
                                        Core.PopupManager.close();
                                    }
                                });

                                if (netRow.saved) {
                                    items.push({
                                        separator: true
                                    });

                                    items.push({
                                        icon: Core.Icons.trash,
                                        label: "Forget network",
                                        danger: true,
                                        action: function () {
                                            popup.svc.forgetNetwork(netRow.ssid);
                                        }
                                    });
                                }

                                popup.openMenu(mx, my, items);
                            }
                        }
                    }

                    Core.EmptyState {
                        width: parent.width

                        shown: !popup.svc.wifiEnabled || popup.svc.networkModel.count === 0

                        icon: popup.svc.wifiEnabled ? Core.Icons.wifiNone : Core.Icons.wifiOff

                        text: popup.svc.wifiEnabled ? "No networks in range" : "Wi-Fi is turned off"
                    }
                }
            }
        }
    }
}
