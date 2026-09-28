import QtQuick
import Quickshell
import Quickshell.Io

import "../core" as Core
import "../services" as Services

// Application Launcher

Core.LauncherView {
    id: launcher

    launcherId: "launcher"
    promptIcon: Core.Icons.search
    // 285px in a field that is 316px wide with a four digit result count, which
    // is the most this field can ever be. The old one was 517px.
    placeholder: "Search apps, > for commands"

    cardWidth: 460
    rowHeight: 44

    columns: 1

    readonly property var results: Services.LauncherService.search(launcher.query)

    itemCount: launcher.results.length

    counterText: launcher.results.length + " results"

    onDidOpen: Services.ShellService.refresh()

    onAccepted: {
        const entry = launcher.results[launcher.selectedIndex];
        if (!entry)
            return;

        if (entry.kind === "reminder") {
            launcher.dismiss();
            Core.PopupManager.open("reminder", null);
            return;
        }

        // Dismiss first: otherwise the closing surface and the new window race for keyboard focus.
        launcher.dismiss();
        Services.LauncherService.run(entry);
    }

    contentComponent: Component {
        Core.ResultsView {
            id: list

            anchors.fill: parent

            // The inset is the view's, not the delegate's: a delegate that
            // offset itself with `x` fought the view for its own position.
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            model: launcher.results
            selectedIndex: launcher.selectedIndex

            rowHeight: 40

            emptyText: "No matching applications"

            delegate: Core.ListRow {
                id: row

                required property var modelData
                required property int index

                width: list.cellWidth
                height: list.rowHeight

                // A desktop entry has a real icon; a command or a switch does
                // not, and falls back to a glyph that names what it is. Adding a
                // kind without a glyph here reads as "this runs a command", so
                // every branch stays explicit.
                iconSource: row.modelData.kind === "app"
                    ? Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                    : ""

                icon: {
                    const kind = row.modelData.kind;

                    if (kind === "reminder")
                        return Core.Icons.timer;

                    if (kind === "nightlight")
                        return Core.Icons.whiteBalance;

                    return Core.Icons.terminal;
                }

                title: row.modelData.name

                readonly property string details: row.modelData.subtitle || ""
                readonly property string prefix: row.modelData.category
                    ? row.modelData.category + (details.length > 0 ? " · " + details : "")
                    : details

                subtitle: row.prefix
                trailing: row.modelData.category

                active: row.index === list.selectedIndex

                onActivated: {
                    launcher.selectedIndex = row.index;
                    launcher.accepted();
                }
            }
        }
    }
}
