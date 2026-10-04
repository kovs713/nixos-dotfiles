pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import Quickshell.Services.Notifications as Notifs

import "../core" as Core

Singleton {
    id: root

    readonly property string configDirectory: Core.Paths.shell

    readonly property int defaultTimeout: 3500

    readonly property int maxTimeout: 10000

    readonly property int maxVisible: 4

    readonly property int maxHistory: 100

    readonly property alias notifications: server.trackedNotifications

    property bool dnd: false

    property var toasts: []

    property var replyTarget: null

    function beginReply(n) {
        if (root.hasInlineReply(n))
            root.replyTarget = n;
    }

    function cancelReply() {
        root.replyTarget = null;
    }

    function isReplying(n) {
        return n !== null && n !== undefined && root.replyTarget === n;
    }

    function isCritical(n) {
        return Number(Core.Util.get(n, "urgency", 0)) === 2;
    }

    readonly property string sounds: Core.Paths.assets + "/assets/sounds/"

    readonly property Process sound: Process {
        id: soundProcess

        running: false

        onExited: function (exitCode) {
            if (exitCode !== 0)
                console.warn("NotificationServer: pw-play exited with " + exitCode);
        }
    }

    function playSound(n) {
        if (root.dnd && !root.isCritical(n))
            return;

        soundProcess.command = [
            "pw-play",
            root.sounds + (root.isCritical(n) ? "mac_os_glass.mp3" : "mac_os_tink.mp3")
        ];
        Core.Util.restart(root.sound);
    }

    function isTransient(n) {
        return Core.Util.flag(n, "transient");
    }

    function isResident(n) {
        return Core.Util.flag(n, "resident");
    }

    function isLastGeneration(n) {
        return Core.Util.flag(n, "lastGeneration");
    }

    function hasInlineReply(n) {
        return Core.Util.flag(n, "hasInlineReply");
    }

    function hasActionIcons(n) {
        return Core.Util.flag(n, "hasActionIcons");
    }

    function replyPlaceholder(n) {
        const hint = String(Core.Util.get(n, "inlineReplyPlaceholder", ""));

        return hint !== "" ? hint : "Reply";
    }

    function appLabel(n) {
        const name = String(Core.Util.get(n, "appName", ""));

        if (name !== "")
            return name;

        const entry = String(Core.Util.get(n, "desktopEntry", ""));

        return entry !== "" ? entry : "Notification";
    }

    function iconFor(n) {
        const image = String(Core.Util.get(n, "image", ""));

        if (image !== "" && image.indexOf("image://") !== 0)
            return image;

        const name = String(Core.Util.get(n, "appIcon", ""));

        return name !== "" ? Quickshell.iconPath(name, true) : "";
    }

    property var stamps: ({})

    property int ageTick: 0

    function ageOf(n) {
        const id = Core.Util.get(n, "id", -1);

        if (id === -1)
            return 0;

        const t = root.stamps[id];

        if (t === undefined) {
            const born = Number(Core.Util.get(n, "time", 0));

            return born > 0 ? Math.max(0, Date.now() - born) : 0;
        }

        return Date.now() - t;
    }

    function ageText(n) {
        const seconds = Math.floor(root.ageOf(n) / 1000);

        if (seconds < 45)
            return "now";

        const minutes = Math.floor(seconds / 60);

        if (minutes < 1)
            return "now";

        if (minutes < 60)
            return minutes + "m";

        const hours = Math.floor(minutes / 60);

        if (hours < 24)
            return hours + "h";

        return Math.floor(hours / 24) + "d";
    }

    Timer {
        interval: Core.Theme.slowPollMs

        repeat: true

        running: Core.PopupManager.isOpen("notifications")

        onTriggered: root.ageTick++
    }

    function lifetimeFor(n) {
        if (root.isCritical(n))
            return 0;

        const t = Number(Core.Util.get(n, "expireTimeout", -1));

        if (isNaN(t) || t <= 0)
            return root.defaultTimeout;

        return Math.min(t * 1000, root.maxTimeout);
    }

    function showToast(n) {
        if (root.dnd && !root.isCritical(n))
            return;
        const next = root.toasts.slice();
        next.push(n);

        while (next.length > root.maxVisible)
            next.shift();

        root.toasts = next;
    }

    function hideToast(n) {
        const next = [];

        for (var i = 0; i < root.toasts.length; i++) {
            if (root.toasts[i] !== n)
                next.push(root.toasts[i]);
        }

        if (next.length !== root.toasts.length)
            root.toasts = next;

        if (root.replyTarget === n)
            root.replyTarget = null;
    }

    function expireToast(n) {
        if (root.isTransient(n)) {
            root.dismiss(n);
            return;
        }

        root.hideToast(n);
    }

    function clearToasts() {
        if (root.toasts.length > 0)
            root.toasts = [];

        root.replyTarget = null;
    }

    function dismiss(n) {
        if (n && n.archived) {
            root.archive = root.archive.filter(function (entry) {
                return entry.id !== n.id;
            });

            root.persist();

            return;
        }

        root.hideToast(n);

        try {
            n.dismiss();
        } catch (e) {
            try {
                n.expire();
            } catch (e2) {
            }
        }
    }

    function invokeAction(n, action) {
        if (!n || !action)
            return;

        try {
            action.invoke();
        } catch (e) {
        }

        if (root.isResident(n))
            root.hideToast(n);
    }

    function sendReply(n, text) {
        if (!n || text === undefined || text === null || String(text) === "")
            return false;

        if (!root.hasInlineReply(n))
            return false;

        try {
            n.sendInlineReply(String(text));
        } catch (e) {
            return false;
        }

        if (root.replyTarget === n)
            root.replyTarget = null;

        if (root.isResident(n))
            root.hideToast(n);

        return true;
    }

    function prune() {
        const list = server.trackedNotifications;

        if (!list || !list.values)
            return;

        const values = list.values.slice();

        const excess = values.length - root.maxHistory;

        if (excess <= 0)
            return;

        for (var i = 0; i < excess; i++)
            root.dismiss(values[i]);
    }

    readonly property string archivePath: root.configDirectory + "/notifications.json"

    property var archive: []

    property bool archiveLoaded: false

    readonly property var archiveFile: FileView {
        path: root.archivePath

        watchChanges: true
        blockLoading: true
        printErrors: false

        onFileChanged: root.loadArchive()
    }

    readonly property var history: {
        const live = (server.trackedNotifications && server.trackedNotifications.values) ? server.trackedNotifications.values : [];

        return live.concat(root.archive);
    }

    function loadArchive() {
        const raw = root.archiveFile.text();

        if (!raw) {
            root.archive = [];
            root.archiveLoaded = true;
            return;
        }

        let parsed;

        try {
            parsed = JSON.parse(raw);
        } catch (e) {
            root.archive = [];
            root.archiveLoaded = true;
            return;
        }

        if (!Array.isArray(parsed)) {
            root.archive = [];
            root.archiveLoaded = true;
            return;
        }

        const entries = [];

        for (let i = 0; i < parsed.length && entries.length < root.maxHistory; i++) {
            const e = parsed[i];

            if (!e || typeof e.summary !== "string")
                continue;

            entries.push({
                id: "archived:" + i + ":" + String(e.time),
                appName: e.app || "",
                summary: e.summary,
                body: e.body || "",
                urgency: e.urgency === undefined ? 0 : e.urgency,
                time: e.time,
                image: "",
                appIcon: "",
                actions: [],
                hasInlineReply: false,
                hasActionIcons: false,
                transient: false,
                resident: false,
                lastGeneration: false,
                archived: true
            });
        }

        root.archive = entries;
        root.archiveLoaded = true;
    }

    function persist() {
        if (!root.archiveLoaded)
            return;

        const list = server.trackedNotifications;
        const values = (list && list.values) ? list.values.slice() : [];

        const records = values.map(root.serialise).concat(root.archive.map(root.serialise));

        if (records.length === 0) {
            root.archiveFile.setText("");
            return;
        }

        root.archiveFile.setText(JSON.stringify(records.slice(0, root.maxHistory)));
    }

    function serialise(n) {
        if (n && n.archived)
            return { app: n.appName, summary: n.summary, body: n.body, time: n.time, urgency: n.urgency };

        return {
            app: root.appLabel(n),
            summary: String(Core.Util.get(n, "summary", "")),
            body: String(Core.Util.get(n, "body", "")),
            time: root.stamps[Core.Util.get(n, "id", -1)] || 0,
            urgency: Number(Core.Util.get(n, "urgency", 0))
        };
    }

    Connections {
        target: server

        function onTrackedNotificationsChanged() {
            root.persist();
        }
    }

    function clearAll() {
        const list = server.trackedNotifications;

        if (list && list.values) {
            const values = list.values.slice();

            for (let i = 0; i < values.length; i++)
                root.dismiss(values[i]);
        }

        root.archive = [];

        root.persist();
    }

    Notifs.NotificationServer {
        id: server

        keepOnReload: true

        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false

        imageSupported: true

        actionsSupported: true
        actionIconsSupported: true

        inlineReplySupported: true

        persistenceSupported: true

        onNotification: function (notification) {
            notification.tracked = true;

            var id = -1;

            try {
                id = notification.id;
            } catch (e) {}

            if (id !== -1)
                root.stamps[id] = Date.now();

            try {
                notification.closed.connect(function () {
                    root.hideToast(notification);

                    if (root.replyTarget === notification)
                        root.replyTarget = null;

                    if (id !== -1)
                        delete root.stamps[id];
                });
            } catch (e) {
            }

            root.prune();

            if (root.isLastGeneration(notification))
                return;

            root.showToast(notification);
            root.playSound(notification);
        }
    }

    Component.onCompleted: root.loadArchive()

    onDndChanged: {
        if (!root.dnd)
            return;

        const kept = [];

        for (var i = 0; i < root.toasts.length; i++) {
            if (root.isCritical(root.toasts[i]))
                kept.push(root.toasts[i]);
        }

        if (kept.length !== root.toasts.length)
            root.toasts = kept;
    }
}
