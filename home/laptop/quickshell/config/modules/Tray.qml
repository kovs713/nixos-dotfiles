import QtQuick
import QtQuick.Layouts

import Quickshell.Services.SystemTray

import "../core" as Core

Item {
    id: root

    property var barWindow: null

    implicitWidth: trayRow.implicitWidth
    implicitHeight: Core.Theme.moduleHeight

    // Hidden system tray applications

    // Why these are hidden: NetworkManager and Blueman each put an applet in the
    // tray, and the shell already has a button for both, so the tray entry is a
    // second control for something the bar owns. Matched on all three strings an
    // applet carries, because which one carries the name varies by version --
    // nm-applet is the id, NetworkManager and Blueman are usually the title.
    readonly property var hiddenMarkers: ["nm-applet", "networkmanager", "blueman"]

    function isHidden(item) {
        const id = String(item.id || "").toLowerCase();
        const title = String(item.title || "").toLowerCase();
        const tooltip = (String(item.tooltipTitle || "") + " " + String(item.tooltipDescription || "")).toLowerCase();

        return root.hiddenMarkers.some(function (marker) {
            return id.includes(marker) || title.includes(marker) || tooltip.includes(marker);
        });
    }

    RowLayout {
        id: trayRow

        anchors.centerIn: parent

        spacing: 2

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayItem

                required property var modelData

                // Hide NetworkManager and Blueman from the visual tray while keeping their processes alive.
                visible: !root.isHidden(modelData)

                implicitWidth: visible ? 26 : 0

                implicitHeight: Core.Theme.moduleHeight

                Rectangle {
                    anchors.fill: parent

                    radius: 14

                    color: mouse.containsMouse ? Core.Theme.surfaceHover : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                            easing.type: Easing.OutQuint
                        }
                    }
                }

                Image {
                    anchors.centerIn: parent

                    width: 17
                    height: 17

                    source: modelData.icon

                    fillMode: Image.PreserveAspectFit

                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent

                    hoverEnabled: true

                    cursorShape: Qt.PointingHandCursor

                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: function (event) {
                        if (event.button === Qt.LeftButton) {
                            if (modelData.onlyMenu || modelData.hasMenu) {
                                const p = trayItem.mapToItem(root.barWindow.contentItem, 0, trayItem.height);

                                modelData.display(root.barWindow, Math.round(p.x), Math.round(p.y));
                            } else {
                                modelData.activate();
                            }

                            return;
                        }

                        if (event.button === Qt.RightButton) {
                            if (modelData.hasMenu) {
                                const p = trayItem.mapToItem(root.barWindow.contentItem, 0, trayItem.height);

                                modelData.display(root.barWindow, Math.round(p.x), Math.round(p.y));
                            }

                            return;
                        }

                        if (event.button === Qt.MiddleButton) {
                            modelData.secondaryActivate();
                        }
                    }
                }
            }
        }
    }
}
