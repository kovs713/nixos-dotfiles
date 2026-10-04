import QtQuick

import "../core" as Core
import "../services" as Services

Core.PopupSurface {
    id: popup

    popupId: "audio"

    cardWidth: 350
    maxCardHeight: 520

    readonly property var svc: Services.AudioService

    property bool showOutputs: false
    property bool showInputs: false

    onDidClose: {
        popup.showOutputs = false;
        popup.showInputs = false;
    }

    function deviceMenu(node, mx, my) {
        const target = node;
        const svc = popup.svc;

        popup.openMenu(mx, my, [
            {
                label: "Set as default",
                icon: Core.Icons.check,
                action: function () {
                    svc.setDefault(target);
                }
            },
            {
                label: svc.mutedOf(target) ? "Unmute" : "Mute",
                icon: svc.mutedOf(target) ? Core.Icons.volumeHigh : Core.Icons.volumeOff,
                action: function () {
                    svc.toggleMute(target);
                }
            },
            {
                label: "Set to 100%",
                icon: Core.Icons.volumeHigh,
                action: function () {
                    svc.setVolume(target, 1.0);
                }
            },
            {
                separator: true
            },
            {
                label: "Open pavucontrol",
                icon: Core.Icons.gear,
                action: function () {
                    svc.openMixer();
                }
            }
        ]);
    }

    contentComponent: Component {
        Column {
            spacing: Core.Theme.spacing

            Core.PopupHeader {
                width: parent.width

                title: "Audio"

                subtitle: popup.svc.sink ? popup.svc.label(popup.svc.sink) : "No output device"

                actions: [
                    {
                        icon: Core.Icons.gear,
                        action: function () {
                            popup.svc.openMixer();
                        }
                    }
                ]
            }

            Rectangle {
                width: parent.width

                height: 76

                radius: Core.Theme.radiusRow

                color: Core.Theme.surface

                Column {
                    anchors.fill: parent
                    anchors.margins: 12

                    spacing: 8

                    Item {
                        width: parent.width
                        height: 20

                        Text {
                            id: outIcon

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter

                            text: popup.svc.icon

                            font.family: Core.Theme.iconFont
                            font.pixelSize: Core.Theme.iconSize

                            color: popup.svc.muted ? Core.Theme.foregroundFaint : Core.Theme.accent

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6

                                hoverEnabled: true

                                cursorShape: Qt.PointingHandCursor

                                onClicked: popup.svc.toggleOutputMute()
                            }
                        }

                        Text {
                            anchors.left: outIcon.right
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter

                            text: popup.svc.muted ? "Muted" : "Output"

                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.Theme.fontSizeSmall

                            color: Core.Theme.foregroundMuted
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            text: popup.svc.volumePercent + "%"

                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.Theme.fontSizeLarge
                            font.weight: Font.DemiBold

                            color: popup.svc.muted ? Core.Theme.foregroundFaint : Core.Theme.foreground
                        }
                    }

                    Core.VolumeSlider {
                        width: parent.width

                        value: popup.svc.volume
                        muted: popup.svc.muted

                        enabled: popup.svc.sink !== null

                        fillColor: Core.Theme.accent

                        onMoved: function (v) {
                            popup.svc.setVolume(popup.svc.sink, v);
                        }
                    }
                }
            }

            Core.SectionHeader {
                width: parent.width

                height: 22

                text: "OUTPUT DEVICES"

                trailing: popup.svc.sinks.length + (popup.showOutputs ? "  " + Core.Icons.chevronUp : "  " + Core.Icons.chevronDown)

                MouseArea {
                    anchors.fill: parent

                    hoverEnabled: true

                    cursorShape: Qt.PointingHandCursor

                    onClicked: popup.showOutputs = !popup.showOutputs
                }
            }

            Core.ExpandableList {
                id: outputList

                width: parent.width

                maxHeight: 190

                expanded: popup.showOutputs

                spacing: 2

                model: popup.svc.sinks

                delegate: Core.ListRow {
                    id: sinkRow

                    required property var modelData

                    width: outputList.width

                    icon: popup.svc.iconFor(sinkRow.modelData)

                    title: popup.svc.label(sinkRow.modelData)

                    subtitle: popup.svc.percentOf(sinkRow.modelData) + "%" + (popup.svc.mutedOf(sinkRow.modelData) ? "  \u00b7  muted" : "")

                    active: popup.svc.isDefault(sinkRow.modelData)

                    trailing: sinkRow.active ? Core.Icons.checkCircle : ""

                    trailingColor: Core.Theme.success

                    onActivated: {
                        popup.svc.setDefaultSink(sinkRow.modelData);
                    }

                    onContextRequested: function (mx, my) {
                        popup.deviceMenu(sinkRow.modelData, mx, my);
                    }
                }
            }

            Rectangle {
                width: parent.width

                height: 76

                radius: Core.Theme.radiusRow

                color: Core.Theme.surface

                Column {
                    anchors.fill: parent
                    anchors.margins: 12

                    spacing: 8

                    Item {
                        width: parent.width
                        height: 20

                        Text {
                            id: micIcon

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter

                            text: popup.svc.micIcon

                            font.family: Core.Theme.iconFont
                            font.pixelSize: Core.Theme.iconSize

                            color: popup.svc.micMuted ? Core.Theme.danger : Core.Theme.success

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6

                                hoverEnabled: true

                                cursorShape: Qt.PointingHandCursor

                                onClicked: popup.svc.toggleMicMute()
                            }
                        }

                        Text {
                            anchors.left: micIcon.right
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter

                            text: popup.svc.micMuted ? "Microphone muted" : "Microphone"

                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.Theme.fontSizeSmall

                            color: popup.svc.micMuted ? Core.Theme.danger : Core.Theme.foregroundMuted
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            text: popup.svc.micPercent + "%"

                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.Theme.fontSizeLarge
                            font.weight: Font.DemiBold

                            color: popup.svc.micMuted ? Core.Theme.foregroundFaint : Core.Theme.foreground
                        }
                    }

                    Core.VolumeSlider {
                        width: parent.width

                        value: popup.svc.micVolume
                        muted: popup.svc.micMuted

                        enabled: popup.svc.source !== null

                        fillColor: Core.Theme.success

                        onMoved: function (v) {
                            popup.svc.setVolume(popup.svc.source, v);
                        }
                    }
                }
            }

            Core.SectionHeader {
                width: parent.width

                height: 22

                text: "INPUT DEVICES"

                trailing: popup.svc.sources.length + (popup.showInputs ? "  " + Core.Icons.chevronUp : "  " + Core.Icons.chevronDown)

                MouseArea {
                    anchors.fill: parent

                    hoverEnabled: true

                    cursorShape: Qt.PointingHandCursor

                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: function (event) {
                        if (event.button === Qt.RightButton) {
                            popup.svc.showMonitors = !popup.svc.showMonitors;

                            popup.showInputs = true;

                            return;
                        }

                        popup.showInputs = !popup.showInputs;
                    }
                }
            }

            Core.ExpandableList {
                id: inputList

                width: parent.width

                maxHeight: 190

                expanded: popup.showInputs

                spacing: 2

                model: popup.svc.sources

                delegate: Core.ListRow {
                    id: sourceRow

                    required property var modelData

                    width: inputList.width

                    icon: popup.svc.iconFor(sourceRow.modelData)

                    title: popup.svc.label(sourceRow.modelData)

                    subtitle: popup.svc.percentOf(sourceRow.modelData) + "%" + (popup.svc.mutedOf(sourceRow.modelData) ? "  \u00b7  muted" : "")

                    active: popup.svc.isDefault(sourceRow.modelData)

                    trailing: sourceRow.active ? Core.Icons.checkCircle : ""

                    trailingColor: Core.Theme.success

                    onActivated: {
                        popup.svc.setDefaultSource(sourceRow.modelData);
                    }

                    onContextRequested: function (mx, my) {
                        popup.deviceMenu(sourceRow.modelData, mx, my);
                    }
                }
            }

            Core.SectionHeader {
                width: parent.width

                visible: popup.svc.streams.length > 0

                text: "PLAYING"
            }

            Core.ExpandableList {
                id: streamList

                width: parent.width

                maxHeight: 190

                spacing: 4

                model: popup.svc.streams

                delegate: Item {
                    id: streamRow

                    required property var modelData

                    width: streamList.width
                    height: 44

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.top: parent.top

                        width: parent.width - 60

                        elide: Text.ElideRight

                        text: popup.svc.streamLabel(streamRow.modelData)

                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.Theme.fontSize

                        color: Core.Theme.foreground
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.top: parent.top

                        text: popup.svc.percentOf(streamRow.modelData) + "%"

                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.Theme.fontSizeSmall

                        color: Core.Theme.foregroundMuted
                    }

                    Core.VolumeSlider {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        anchors.bottom: parent.bottom

                        value: popup.svc.volumeOf(streamRow.modelData)

                        muted: popup.svc.mutedOf(streamRow.modelData)

                        fillColor: Core.Theme.accentSoft

                        onMoved: function (v) {
                            popup.svc.setVolume(streamRow.modelData, v);
                        }
                    }
                }
            }

            Core.EmptyState {
                width: parent.width

                shown: popup.svc.sink === null

                icon: Core.Icons.volumeOff

                text: "No audio device found"
            }
        }
    }
}
