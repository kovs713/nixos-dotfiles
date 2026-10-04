import QtQuick

import "." as Core

// ResultsView
//
// The scroll container behind every launcher's results: apps, reminders,
// clipboard items, the emoji grid. One column is a list, several are a grid --
// a GridView with a single column is a vertical list, so both shapes are one
// type instead of one that grows a second half per caller.
//
// It exists because the same two bugs were open-coded in all four launchers, and
// a fifth list would have grown them again:
//
//   * The row being left animated as well as the row being entered, so one
//     arrow key read as two rows moving and neither looked settled.
//   * The list itself slid. Nothing in the shell animated that: `currentIndex`
//     is not what scrolls a selection into view. Changing it makes Qt animate
//     the view's *highlight* towards the new current item over
//     `highlightMoveDuration` -- 150ms, and it does that even when no highlight
//     was ever declared, because one is created by default -- and the view
//     follows that animated highlight. `highlightRangeMode: ApplyRange` with
//     `preferredHighlight*` made it worse: the highlight is tracked, so the
//     content was pushed until the row sat 40px from the edge even when it was
//     already visible. That is the blink on the row you are leaving.
//
// So there is no `currentIndex` here, and no highlight range. `positionViewAtIndex`
// is the scroll, and it sets the content position in a single step. Dropping
// `currentIndex` is what actually kills the animation: it is the only thing that
// marks the view's move reason as "set index", and that mark is the only thing
// the highlight animation is allowed to move the view with.
//
// The delegate stays with the caller, for the same reason ExpandableList leaves
// it there: the roles and the click handler are per-launcher. What a delegate
// must not have is a `Behavior` on anything `selectedIndex` feeds. Selection is
// a state, not a transition, and animating it is the first bug above, twice.

GridView {
    id: root

    // The selection belongs to LauncherView, which also drives the keys, the
    // wheel and the card height. This view only follows it.
    property int selectedIndex: 0

    property string emptyText: ""

    // How many cells a row holds. A `GridView` has no `columns` property to set:
    // it derives the count from its own width and the cell width, so a list is
    // one cell per row and a grid is several. This is the count, not the cell
    // width, because that is the number the callers already have -- the
    // navigation step, in LauncherView.
    property int columns: 1

    // The height a delegate draws, and the gap the next one starts lower by.
    //
    // A `GridView` has no `spacing` either -- that is `ListView` -- so the gap
    // has to be part of the cell. The delegate states the height it draws and
    // the pitch is derived, rather than the other way round.
    property int rowHeight: 40
    property int gap: 4

    cellWidth: root.columns > 1 ? Math.floor(root.width / root.columns) : root.width
    cellHeight: root.rowHeight + root.gap

    // The selection moves by key and by wheel, never by dragging the list, so
    // the list never takes the pointer: LauncherView's MouseArea has it, and it
    // moves the selection rather than the content.
    interactive: false

    clip: true

    boundsBehavior: Flickable.StopAtBounds

    // Put the selected row in view without moving anything that is already in
    // view. Deferred, because the model and the selection change in the same
    // turn while typing, and positioning against a model that has not been laid
    // out yet lands on the old content.
    function reveal() {
        if (root.count === 0) {
            root.contentY = 0;
            return;
        }

        root.positionViewAtIndex(root.selectedIndex, GridView.Contain);
    }

    onSelectedIndexChanged: Qt.callLater(reveal)

    onCountChanged: Qt.callLater(reveal)

    // A child of the view rather than of the content, so it stays put when the
    // view scrolls. EmojiPicker binds all three of its states into this one
    // string: still loading, nothing to search, no match.
    Text {
        anchors.centerIn: parent

        visible: root.count === 0 && root.emptyText !== ""

        text: root.emptyText

        color: Core.Theme.foregroundFaint

        font.family: Core.Theme.fontMono

        font.pixelSize: Core.Theme.fontSize
    }
}
