import QtQuick

import "." as Core

// SectionHeader
//
// A small caps label above a group of rows.
//
// Eight of them, in three shapes, all the same idea: fontSizeSmall, DemiBold,
// letterSpacing 1, foregroundFaint. Five wrote the letter spacing as `1` and
// AudioPopup wrote `1.0`; three had a right-hand annotation ("3 found") and the
// rest did not. Both are optional here.
//
// No line under it. There was one, on by default, which meant every section
// label drew a hairline its own height below itself -- and the popups stacking
// two labels had two of those 6px apart, so the middle of a card read as a
// thicket of one-pixel rules. The label already says which group it names and
// the rows under it already belong to it; the line said the same thing again,
// immediately, which is what made the label and the list look stuck together
// rather than grouped.
Item {
    id: root

    property string text: ""

    // A count, a state, anything short and right-aligned. Optional.
    property string trailing: ""

    // Faded rather than absent, for an annotation that is still true but does not
    // apply right now -- a row count while the radio is off.
    property real trailingOpacity: 1.0

    implicitHeight: 16

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        text: root.text

        font.family: Core.Theme.fontFamily
        font.pixelSize: Core.Theme.fontSizeSmall
        font.weight: Font.DemiBold
        font.letterSpacing: 1

        color: Core.Theme.foregroundFaint
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        visible: root.trailing !== ""

        text: root.trailing

        opacity: root.trailingOpacity

        font.family: Core.Theme.fontFamily
        font.pixelSize: Core.Theme.fontSizeSmall
        font.weight: Font.DemiBold
        font.letterSpacing: 1

        color: Core.Theme.foregroundFaint
    }

}
