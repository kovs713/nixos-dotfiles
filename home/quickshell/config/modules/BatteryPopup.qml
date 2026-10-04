import QtQuick

import "../core" as Core
import "../services" as Services

Core.PopupSurface {
    id: popup

    popupId: "battery"

    cardWidth: 340
    maxCardHeight: 460

    readonly property var svc: Services.BatteryService

    property bool showPeripherals: true

    contentComponent: Component {
        Column {
            id: body

            spacing: Core.Theme.spacing

            Core.PopupHeader {
                width: body.width

                title: "Battery"

                subtitle: popup.svc.stateLabel

                actions: [
                    {
                        icon: popup.svc.profileIcon(popup.svc.profile),
                        action: function () {
                            const max = popup.svc.hasPerformance ? 2 : 1;

                            let next = popup.svc.profile + 1;

                            if (next > max)
                                next = 0;

                            popup.svc.setProfile(next);
                        }
                    },
                    {
                        icon: Core.Icons.gear,
                        action: function () {
                            popup.svc.openPowerSettings();
                            popup.closeMenu();
                            Core.PopupManager.close();
                        }
                    }
                ]
            }

            Rectangle {
                id: gauge

                width: body.width

                height: 92

                radius: Core.Theme.radiusRow + 2

                color: Core.Theme.surface

                border.width: Core.Theme.borderWidth
                border.color: Core.Theme.border

                Text {
                    id: bigIcon

                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.top: parent.top
                    anchors.topMargin: 14

                    text: popup.svc.icon

                    font.family: Core.Theme.iconFont
                    font.pixelSize: Core.Theme.iconSizeLarge

                    color: popup.svc.color

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.OutQuint
                        }
                    }
                }

                Text {
                    anchors.left: bigIcon.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: bigIcon.verticalCenter

                    text: popup.svc.percentInt + "%"

                    font.family: Core.Theme.fontFamily
                    font.pixelSize: 24
                    font.weight: Font.DemiBold

                    color: Core.Theme.foreground
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: bigIcon.verticalCenter

                    text: popup.svc.changeRate > 0 ? popup.svc.changeRate.toFixed(1) + " W" : ""

                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.fontSizeSmall

                    color: Core.Theme.foregroundMuted
                }

                Rectangle {
                    id: barTrack

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.bottomMargin: 26

                    height: 8

                    radius: 4

                    color: Core.Theme.separator

                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        width: barTrack.width * Math.max(0.02, Math.min(1.0, popup.svc.percent / 100))

                        radius: 4

                        color: popup.svc.color

                        Behavior on width {
                            NumberAnimation {
                                duration: Core.Theme.durBase
                                easing.type: Easing.OutQuint
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 160
                                easing.type: Easing.OutQuint
                            }
                        }
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        width: 40

                        radius: 4

                        color: Core.Theme.text

                        opacity: popup.svc.charging ? 0.18 : 0.0

                        visible: opacity > 0.01

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutQuint
                            }
                        }

                        NumberAnimation on x {
                            running: popup.svc.charging
                            loops: Animation.Infinite

                            from: -40
                            to: barTrack.width

                            duration: 1600
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8

                    text: popup.svc.health >= 0 ? Core.Icons.health + "  Health " + Math.round(popup.svc.health) + "%" : popup.svc.stateLabel

                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.fontSizeSmall

                    color: Core.Theme.foregroundMuted
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8

                    text: popup.svc.profileLabel

                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.fontSizeSmall

                    color: Core.Theme.accent
                }

                MouseArea {
                    anchors.fill: parent

                    acceptedButtons: Qt.RightButton

                    onClicked: function (event) {
                        const p = gauge.mapToItem(null, event.x, event.y);

                        popup.openMenu(p.x, p.y, [
                            {
                                label: "Copy status",
                                icon: Core.Icons.copy,
                                action: function () {
                                    Services.ClipboardService.copy(popup.svc.percentInt + "% — " + popup.svc.stateLabel);
                                }
                            },
                            {
                                separator: true
                            },
                            {
                                label: "Power settings",
                                icon: Core.Icons.gear,
                                action: function () {
                                    popup.svc.openPowerSettings();
                                    Core.PopupManager.close();
                                }
                            }
                        ]);
                    }
                }
            }

            Core.SectionHeader {
                width: body.width

                visible: popup.svc.profilesAvailable

                text: "POWER PROFILE"
            }

            Column {
                id: profileColumn

                width: body.width

                spacing: 2

                visible: popup.svc.profilesAvailable

                Repeater {
                    model: popup.svc.hasPerformance ? [0, 1, 2] : [0, 1]

                    delegate: Core.ListRow {
                        id: profileRow

                        required property var modelData

                        width: profileColumn.width

                        icon: popup.svc.profileIcon(profileRow.modelData)

                        title: profileRow.modelData === 0 ? "Power saver" : profileRow.modelData === 2 ? "Performance" : "Balanced"

                        subtitle: profileRow.modelData === 0 ? "Longest battery life" : profileRow.modelData === 2 ? "Maximum speed, more heat" : "Default — good all round"

                        active: popup.svc.profile === profileRow.modelData

                        trailing: (popup.svc.profile === profileRow.modelData) ? Core.Icons.checkCircle : ""

                        trailingColor: Core.Theme.success

                        onActivated: {
                            popup.svc.setProfile(profileRow.modelData);
                        }

                        onContextRequested: function (mx, my) {
                            const value = profileRow.modelData;

                            popup.openMenu(mx, my, [
                                {
                                    label: "Apply profile",
                                    icon: Core.Icons.check,
                                    action: function () {
                                        popup.svc.setProfile(value);
                                    }
                                },
                                {
                                    separator: true
                                },
                                {
                                    label: "Power settings",
                                    icon: Core.Icons.gear,
                                    action: function () {
                                        popup.svc.openPowerSettings();
                                        Core.PopupManager.close();
                                    }
                                }
                            ]);
                        }
                    }
                }
            }

            Rectangle {
                width: body.width

                visible: popup.svc.degradationReason !== ""

                height: visible ? 34 : 0

                radius: Core.Theme.radiusRow

                color: Qt.alpha(Core.Theme.warning, 0.13)

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    verticalAlignment: Text.AlignVCenter

                    text: Core.Icons.info + "  Performance limited: " + popup.svc.degradationReason

                    elide: Text.ElideRight

                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.fontSizeSmall

                    color: Core.Theme.warning
                }
            }

            Core.SectionHeader {
                width: body.width

                height: 22

                visible: popup.svc.peripheralModel.count > 0

                text: "DEVICES"

                trailing: popup.svc.peripheralModel.count + (popup.svc.peripheralModel.count === 1 ? " device" : " devices")

                MouseArea {
                    anchors.fill: parent

                    hoverEnabled: true

                    cursorShape: Qt.PointingHandCursor

                    onClicked: popup.showPeripherals = !popup.showPeripherals
                }
            }

            Core.ExpandableList {
                id: peripheralList

                width: body.width

                maxHeight: 180

                expanded: popup.showPeripherals && popup.svc.peripheralModel.count > 0

                spacing: 2

                model: popup.svc.peripheralModel

                delegate: Core.ListRow {
                    id: devRow

                    required property string label
                    required property string deviceIcon
                    required property int percent
                    required property bool charging

                    width: peripheralList.width

                    icon: devRow.deviceIcon

                    title: devRow.label

                    subtitle: devRow.charging ? "Charging" : devRow.percent <= 20 ? "Low battery" : "On battery"

                    trailing: devRow.percent + "%"

                    trailingColor: devRow.percent <= 20 ? Core.Theme.danger : devRow.percent <= 40 ? Core.Theme.warning : Core.Theme.foregroundMuted

                    iconColor: devRow.percent <= 20 ? Core.Theme.danger : Core.Theme.foreground

                    onContextRequested: function (mx, my) {
                        const name = devRow.label;
                        const pct = devRow.percent;

                        popup.openMenu(mx, my, [
                            {
                                label: "Copy \"" + name + "\"",
                                icon: Core.Icons.copy,
                                action: function () {
                                    Services.ClipboardService.copy(name + " — " + pct + "%");
                                }
                            },
                            {
                                separator: true
                            },
                            {
                                label: "Refresh devices",
                                icon: Core.Icons.refresh,
                                action: function () {
                                    popup.svc.rebuildPeripherals();
                                }
                            }
                        ]);
                    }
                }
            }
        }
    }
}
