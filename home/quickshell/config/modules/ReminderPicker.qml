import QtQuick
import Quickshell.Io

import "../core" as Core
import "../services" as Services

Core.LauncherView {
    id: launcher

    launcherId: "reminder"
    promptIcon: Core.Icons.timer
    placeholder: "set 10 drink water, list, clear"

    cardWidth: 480

    // The row extent, not the row: 44 plus the list's 4px gap. The card is
    // sized from this, so being short by the gap sliced the last row.
    rowHeight: 48

    columns: 1
    vimNavigation: true

    readonly property var results: Services.ReminderService.search(launcher.query)

    itemCount: launcher.results.length
    counterText: launcher.query.length === 0 ? launcher.results.length + " actions" : launcher.results.length + " reminders"

    onDidOpen: Services.ReminderService.refresh()

    onAccepted: {
        const entry = launcher.results[launcher.selectedIndex];
        if (!entry)
            return;

        if (entry.kind === "reminder-set-prompt") {
            launcher.setQuery("set ");
            return;
        }

        if (entry.kind === "reminder-list-prompt") {
            launcher.setQuery("list");
            return;
        }

        if (entry.kind === "reminder-set") {
            Services.ReminderService.add(entry.minutes, entry.message);
            launcher.dismiss();
            return;
        }

        if (entry.kind === "reminder-clear") {
            Services.ReminderService.clear();
            launcher.dismiss();
        }
    }

    contentComponent: Component {
        Core.ResultsView {
            id: list

            anchors.fill: parent

            anchors.leftMargin: 12
            anchors.rightMargin: 12

            model: launcher.results
            selectedIndex: launcher.selectedIndex

            rowHeight: 44

            emptyText: "No matching reminders"

            delegate: Core.ListRow {
                id: row

                required property var modelData
                required property int index

                width: list.cellWidth
                height: list.rowHeight

                icon: row.modelData.kind === "reminder-clear" ? Core.Icons.trash : Core.Icons.timer
                title: row.modelData.title
                subtitle: row.modelData.subtitle || ""
                trailing: row.modelData.trailing || ""
                active: row.index === list.selectedIndex

                onActivated: {
                    launcher.selectedIndex = row.index;
                    launcher.accepted();
                }
            }
        }
    }
}
