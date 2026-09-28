import QtQuick

import Quickshell

import "../core" as Core
import "../services" as Services

// BluetoothPopup

Core.PopupSurface {
    id: popup

    popupId: "bluetooth"

    cardWidth: 340
    maxCardHeight: 470

    readonly property var svc: Services.BluetoothService

    // Start discovering as soon as the menu opens
    onDidOpen: {
        if (popup.svc.powered)
            popup.svc.setDiscovering(true);
    }

    onDidClose: {
        if (popup.svc.discovering)
            popup.svc.setDiscovering(false);
    }

    // Content

    contentComponent: Component {
        Column {
            spacing: Core.Theme.spacing

            // Header

            Core.PopupHeader {
                width: parent.width

                title: "Bluetooth"

                subtitle: popup.svc.primaryLabel

                showToggle: true
                toggled: popup.svc.powered

                onToggleRequested: popup.svc.togglePowered()

                actions: [
                    {
                        icon: popup.svc.discovering ? Core.Icons.refresh : Core.Icons.scan,
                        spinning: popup.svc.discovering,
                        action: function () {
                            if (!popup.svc.powered)
                                popup.svc.setPowered(true);

                            popup.svc.toggleDiscovering();
                        }
                    },
                    {
                        icon: Core.Icons.gear,
                        action: function () {
                            popup.svc.openManager();
                            Core.PopupManager.close();
                        }
                    }
                ]
            }

            Core.SectionHeader {
                width: parent.width

                text: "DEVICES"

                trailing: popup.svc.discovering ? "scanning…" : popup.svc.deviceModel.count + " found"
            }

            // Device list

            Core.ExpandableList {
                id: list

                width: parent.width

                maxHeight: 300

                expanded: popup.svc.powered

                model: popup.svc.deviceModel

                delegate: Core.ListRow {
                    id: devRow

                    // These roles are prefixed because `name`, `icon` and `state` collide with ListRow's own properties, which produces a self-referential
                    required property string address
                    required property string deviceName
                    required property string deviceIcon
                    required property string stateText
                    required property bool connected
                    required property bool paired
                    required property bool trusted
                    required property bool blocked
                    required property int battery

                    width: list.width

                    icon: devRow.deviceIcon

                    title: devRow.deviceName

                    subtitle: devRow.stateText

                    trailing: devRow.battery >= 0 ? devRow.battery + "%" : devRow.connected ? Core.Icons.checkCircle : ""

                    trailingColor: devRow.battery >= 0 ? (devRow.battery < 20 ? Core.Theme.danger : Core.Theme.foregroundMuted) : Core.Theme.success

                    active: devRow.connected

                    dimmed: devRow.blocked

                    busy: popup.svc.pendingAddress === devRow.address

                    // Left click: connect / disconnect

                    onActivated: {
                        if (!devRow.paired && !devRow.connected) {
                            popup.svc.pairDevice(devRow.address);
                            return;
                        }

                        popup.svc.toggleDevice(devRow.address);
                    }

                    // Right click: full device menu

                    onContextRequested: function (mx, my) {
                        const items = [];

                        items.push({
                            icon: devRow.connected ? Core.Icons.btOff : Core.Icons.btConnected,
                            label: devRow.connected ? "Disconnect" : "Connect",
                            action: function () {
                                popup.svc.toggleDevice(devRow.address);
                            }
                        });

                        if (!devRow.paired) {
                            items.push({
                                icon: Core.Icons.accountPlus,
                                label: "Pair",
                                action: function () {
                                    popup.svc.pairDevice(devRow.address);
                                }
                            });
                        }

                        if (devRow.paired) {
                            items.push({
                                icon: devRow.trusted ? Core.Icons.close : Core.Icons.check,
                                label: devRow.trusted ? "Untrust device" : "Trust device",
                                action: function () {
                                    popup.svc.setTrusted(devRow.address, !devRow.trusted);
                                }
                            });
                        }

                        items.push({
                            icon: devRow.blocked ? Core.Icons.checkCircle : Core.Icons.closeCircle,
                            label: devRow.blocked ? "Unblock" : "Block",
                            action: function () {
                                popup.svc.setBlocked(devRow.address, !devRow.blocked);
                            }
                        });

                        items.push({
                            separator: true
                        });

                        items.push({
                            icon: Core.Icons.copy,
                            label: "Copy address",
                            action: function () {
                                Quickshell.clipboardText = devRow.address;
                            }
                        });

                        items.push({
                            icon: Core.Icons.info,
                            label: "Open Blueman",
                            action: function () {
                                popup.svc.openManager();
                                Core.PopupManager.close();
                            }
                        });

                        if (devRow.paired) {
                            items.push({
                                separator: true
                            });

                            items.push({
                                icon: Core.Icons.trash,
                                label: "Forget device",
                                danger: true,
                                action: function () {
                                    popup.svc.forgetDevice(devRow.address);
                                }
                            });
                        }

                        popup.openMenu(mx, my, items);
                    }
                }
            }

            // Empty / off state

            Core.EmptyState {
                width: parent.width

                shown: !popup.svc.powered || popup.svc.deviceModel.count === 0

                icon: popup.svc.powered ? Core.Icons.bluetooth : Core.Icons.btOff

                text: popup.svc.powered ? "No devices yet — hit scan" : "Bluetooth is turned off"
            }

        }
    }
}
