import QtQuick
import QtQuick.Layouts

import "../core" as Core
import "../core/AirPods.js" as AirPods
import "../services" as Services

// A battery strip, a segmented control, two switches and one cycling row.
// A row per control needed 540px and overflowed the screen.
Core.PopupSurface {
    id: popup

    popupId: "airpods"

    cardWidth: 340
    maxCardHeight: 470

    readonly property var svc: Services.AirPodsService

    readonly property string subtitle: {
        if (!popup.svc.running)
            return "librepods is not running";

        if (popup.svc.error !== "")
            return popup.svc.error;

        if (popup.svc.deviceName === "")
            return popup.svc.connected ? "Connected" : "Not connected";

        return popup.svc.connected ? popup.svc.deviceName : popup.svc.deviceName + " · disconnected";
    }

    component BatteryCell: Column {
        id: cell

        property string label: ""
        property string value: "--"
        property string hint: ""
        property bool charging: false

        spacing: 1

        Text {
            text: cell.label

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSizeSmall

            color: Core.Theme.foregroundFaint
        }

        Text {
            text: cell.value

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSize

            font.weight: Font.DemiBold

            color: cell.value === "--" ? Core.Theme.foregroundFaint : Core.Theme.foreground
        }

        Text {
            width: cell.width

            visible: cell.hint !== ""

            text: cell.hint

            elide: Text.ElideRight

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSizeSmall

            color: cell.charging ? Core.Theme.success : Core.Theme.foregroundFaint
        }
    }

    component Segments: Item {
        id: seg

        property var values: []
        property int current: -1

        signal picked(int value)

        implicitHeight: 30

        Rectangle {
            anchors.fill: parent

            radius: Core.Theme.radiusSmall

            color: Core.Theme.surface

            // A literal hairline, not Theme.borderWidth: that is 0 here, and an
            // outlined-less segmented control is four floating words.
            border.width: 1
            border.color: Core.Theme.separator

            antialiasing: true
        }

        Row {
            id: cells

            // Cells size off the Row, not off seg: seg is 4px wider and taller than
            // the Row once the 2px margins are in, so a cell sized from seg hangs
            // over the border on the right and the bottom.
            anchors.fill: parent

            anchors.margins: 2

            Repeater {
                model: seg.values

                delegate: Item {
                    id: mode

                    required property var modelData

                    readonly property bool selected: modelData === seg.current

                    width: cells.width / seg.values.length
                    height: cells.height

                    Rectangle {
                        anchors.fill: parent

                        radius: Core.Theme.radiusSmall

                        color: mode.selected ? Core.Theme.accent : (cellMouse.containsMouse ? Core.Theme.surfaceHover : "transparent")

                        antialiasing: true

                        Behavior on color {
                            ColorAnimation {
                                duration: Core.Theme.durFast
                                easing.type: Easing.OutQuint
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        text: AirPods.noiseModeName(modelData)

                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.Theme.fontSizeSmall

                        color: mode.selected ? Core.Theme.accentForeground : Core.Theme.foregroundMuted
                    }

                    MouseArea {
                        id: cellMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        cursorShape: Qt.PointingHandCursor

                        onClicked: seg.picked(modelData)
                    }
                }
            }
        }
    }

    // A ListRow with a switch instead of a word, on the track PopupHeader uses.
    component SwitchRow: Core.ListRow {
        id: sw

        property bool on: false

        signal toggled

        Rectangle {
            id: track

            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter

            width: 34
            height: 18

            radius: 9

            // surfaceHover rather than surface: the card background is surface, so an
            // off track drawn in it is invisible and the row reads as a stray dot.
            color: sw.on ? Core.Theme.accent : Core.Theme.surfaceHover

            border.width: Core.Theme.borderWidth
            border.color: sw.on ? Core.Theme.accent : Core.Theme.border

            Behavior on color {
                ColorAnimation {
                    duration: 180
                    easing.type: Easing.OutQuint
                }
            }

            Rectangle {
                width: 12
                height: 12

                radius: 6

                anchors.verticalCenter: parent.verticalCenter

                x: sw.on ? track.width - width - 3 : 3

                color: sw.on ? Core.Theme.accentForeground : Core.Theme.foregroundMuted

                Behavior on x {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutQuint
                    }
                }
            }
        }
    }

    contentComponent: Component {
        Column {
            spacing: Core.Theme.spacing

            width: parent.width

            Core.PopupHeader {
                width: parent.width

                title: popup.svc.modelName !== "" ? popup.svc.modelName : "AirPods"

                subtitle: popup.subtitle

                actions: [
                    {
                        icon: Core.Icons.refresh,
                        spinning: popup.svc.busy,
                        action: popup.svc.refresh
                    }
                ]
            }

            Core.EmptyState {
                width: parent.width

                shown: !popup.svc.running

                icon: Core.Icons.headset

                text: "Per-pod battery, listening modes and ear detection come from librepods"
            }

            Text {
                width: parent.width

                visible: popup.svc.running && popup.svc.notice !== ""

                text: popup.svc.notice

                wrapMode: Text.WordWrap

                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.fontSizeSmall

                color: Core.Theme.danger
            }

            Core.SectionHeader {
                width: parent.width

                visible: popup.svc.running

                text: "BATTERY"

                trailing: popup.svc.lidState !== AirPods.LID_UNKNOWN ? "Lid " + AirPods.lidText(popup.svc.lidState) : ""
            }

            RowLayout {
                width: parent.width

                visible: popup.svc.running

                spacing: 8

                BatteryCell {
                    Layout.fillWidth: true

                    visible: !popup.svc.isHeadset

                    label: "Left"
                    value: AirPods.levelText(popup.svc.left.level)
                    hint: AirPods.podMeta(popup.svc.left)
                    charging: popup.svc.left.charging
                }

                BatteryCell {
                    Layout.fillWidth: true

                    visible: !popup.svc.isHeadset

                    label: "Right"
                    value: AirPods.levelText(popup.svc.right.level)
                    hint: AirPods.podMeta(popup.svc.right)
                    charging: popup.svc.right.charging
                }

                BatteryCell {
                    Layout.fillWidth: true

                    visible: !popup.svc.isHeadset

                    label: "Case"
                    value: AirPods.levelText(popup.svc.caseBattery.level)
                    hint: AirPods.podMeta(popup.svc.caseBattery)
                    charging: popup.svc.caseBattery.charging
                }

                BatteryCell {
                    Layout.fillWidth: true

                    visible: popup.svc.isHeadset

                    label: "Battery"
                    value: AirPods.levelText(popup.svc.headset.level)
                    hint: AirPods.podMeta(popup.svc.headset)
                    charging: popup.svc.headset.charging
                }
            }

            Core.SectionHeader {
                width: parent.width

                visible: popup.svc.connected && popup.svc.modes.length > 0

                text: "LISTENING MODE"
            }

            Segments {
                width: parent.width

                visible: popup.svc.connected && popup.svc.modes.length > 0

                values: popup.svc.modes
                current: popup.svc.noiseMode

                onPicked: function (mode) {
                    popup.svc.setNoiseMode(mode);
                }
            }

            Column {
                width: parent.width

                spacing: 2

                visible: popup.svc.connected
                    && popup.svc.supportsAdaptive
                    && popup.svc.noiseMode === AirPods.NOISE_ADAPTIVE

                RowLayout {
                    width: parent.width

                    Text {
                        Layout.fillWidth: true

                        text: "Adaptive noise level"

                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.Theme.fontSizeSmall

                        color: Core.Theme.foregroundMuted
                    }

                    Text {
                        text: popup.svc.adaptiveNoiseLevel + "%"

                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.Theme.fontSizeSmall

                        color: Core.Theme.foreground
                    }
                }

                Core.VolumeSlider {
                    width: parent.width

                    value: popup.svc.adaptiveNoiseLevel / 100

                    onMoved: function (fraction) {
                        popup.svc.setAdaptiveNoiseLevel(fraction * 100);
                    }
                }
            }

            SwitchRow {
                width: parent.width

                visible: popup.svc.connected && popup.svc.supportsConversationalAwareness

                title: "Conversation Awareness"

                on: popup.svc.conversationalAwareness

                onToggled: popup.svc.setConversationalAwareness(!popup.svc.conversationalAwareness)
            }

            SwitchRow {
                width: parent.width

                visible: popup.svc.connected && popup.svc.supportsOneBudANC

                title: "One-Bud ANC"

                on: popup.svc.oneBudANC

                onToggled: popup.svc.setOneBudANC(!popup.svc.oneBudANC)
            }

            Core.SectionHeader {
                width: parent.width

                visible: popup.svc.connected

                text: "EAR DETECTION"
            }

            Core.ListRow {
                width: parent.width

                visible: popup.svc.connected

                title: "Auto-pause"

                trailing: AirPods.earDetectionName(popup.svc.earDetectionBehavior)

                onActivated: popup.svc.cycleEarDetection()
            }
        }
    }
}