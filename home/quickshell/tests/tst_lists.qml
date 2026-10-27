import QtQuick
import QtTest
import "../config/core" as Core

TestCase {
    name: "ListInteraction"
    width: 750
    height: 200
    visible: true
    when: windowShown

    property int selectionIndex: 0
    property int gridIndex: 0

    Rectangle {
        anchors.fill: parent
        z: -1
        color: Core.Theme.surface
    }

    SignalSpy { id: activation; target: first; signalName: "activated" }
    SignalSpy { id: context; target: first; signalName: "contextRequested" }

    Column {
        Core.ListRow { id: first; width: 200; title: "First" }
        Core.ListRow { id: second; width: 200; title: "Second" }
    }

    Core.ResultsView {
        id: list
        x: 250
        width: 200
        height: 150
        model: 3
        selectedIndex: selectionIndex
        onSelectionRequested: index => selectionIndex = index
        delegate: Core.ListRow {
            required property int index
            width: list.cellWidth
            height: list.rowHeight
            title: "Row " + index
            selected: index === list.selectedIndex
        }
    }

    Core.ResultsView {
        id: grid
        x: 480
        width: 200
        height: 150
        columns: 2
        model: 4
        selectedIndex: gridIndex
        onSelectionRequested: index => gridIndex = index
        delegate: Core.ListItem {
            required property int index
            width: grid.cellWidth
            height: grid.rowHeight
            selected: index === grid.selectedIndex
        }
    }

    function test_pointerAndKeyboardShareSelection_data() {
        return [{ tag: "rows", view: list }, { tag: "grid", view: grid }];
    }

    function test_pointerAndKeyboardShareSelection(data) {
        const view = data.view;
        const previous = view.itemAtIndex(0);
        const next = view.itemAtIndex(1);
        verify(previous !== null && next !== null);
        mouseMove(previous, 10, 15);
        mouseMove(next, 10, 15);
        compare(view.selectedIndex, 1, "Hover updates the shared selection");
        compare(previous.color.a, 0);
        verify(next.color.a > 0);
        verify(!Qt.colorEqual(next.color, Core.Theme.surface), "Hovered item must stand out from the popup surface");

        // Keyboard selection must win even while the pointer remains over another item.
        if (view === list)
            selectionIndex = 0;
        else
            gridIndex = 0;
        compare(next.color.a, 0);
        verify(previous.color.a > 0);
        verify(!Qt.colorEqual(previous.color, Core.Theme.surface), "Keyboard selection must stand out from the popup surface");
    }

    function test_hoverHasNoTrailingHighlight() {
        mouseMove(first, 50, 15);
        wait(150);
        verify(first.color.a > 0);
        mouseMove(second, 50, 15);
        compare(first.color.a, 0, "Previous row must lose hover immediately");
        verify(second.color.a > 0, "Only the row under the pointer is hovered");
    }

    function test_activationAndContextMenu() {
        activation.clear();
        context.clear();
        mouseClick(first, 50, 15, Qt.LeftButton);
        compare(activation.count, 1);
        mouseClick(first, 50, 15, Qt.RightButton);
        compare(context.count, 1);
        compare(activation.count, 1, "Context menu must not activate the item");
    }

    function test_activeDeviceStateIsIndependentOfHover() {
        first.active = true;
        mouseMove(first, 50, 15);
        verify(!Qt.colorEqual(first.color, Core.Theme.surface), "Active items must also show hover");
        mouseMove(second, 50, 15);
        verify(first.emphasized);
        verify(first.color.a > 0);
        first.active = false;
        compare(first.color.a, 0);
    }
}
