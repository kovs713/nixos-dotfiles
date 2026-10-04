import QtQuick

import "." as Core

Item {
    id: root

    property int maxHeight: 0

    property bool expanded: true

    property bool animated: true

    property int spacing: 1

    property var model: null

    property Component delegate

    implicitHeight: root.expanded ? Math.min(list.contentHeight, root.maxHeight) : 0

    clip: true

    Behavior on implicitHeight {
        enabled: root.animated
        NumberAnimation {
            duration: Core.Theme.durBase
            easing.type: Easing.OutQuint
        }
    }

    ListView {
        id: list

        anchors.fill: parent

        clip: true

        spacing: root.spacing

        boundsBehavior: Flickable.StopAtBounds

        model: root.model

        delegate: root.delegate

        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 160
                easing.type: Easing.OutQuint
            }
        }

        remove: Transition {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 160
                easing.type: Easing.InQuint
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 170
                easing.type: Easing.OutQuint
            }
        }

        addDisplaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 170
                easing.type: Easing.OutQuint
            }
        }

        removeDisplaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 160
                easing.type: Easing.OutQuint
            }
        }
    }
}
