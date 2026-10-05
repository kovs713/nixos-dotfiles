import QtQuick
import Quickshell
import Quickshell.Io

import "../core" as Core
import "../services" as Services

Core.LauncherView {
    id: launcher

    launcherId: "launcher"
    promptIcon: Core.Icons.search
    placeholder: "Search apps, = calc, > commands"

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

        launcher.dismiss();
        Services.LauncherService.run(entry);
    }

    contentComponent: Component {
        Core.ResultsView {
            id: list

            anchors.fill: parent

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

                iconSource: row.modelData.kind === "app"
                    ? Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                    : ""

                icon: {
                    const kind = row.modelData.kind;

                    if (row.modelData.mdi)
                        return row.modelData.mdi;

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
