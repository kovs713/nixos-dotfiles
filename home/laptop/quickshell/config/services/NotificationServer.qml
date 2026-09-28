pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The alias is load-bearing.
import Quickshell.Services.Notifications as Notifs

import "../core" as Core

// NotificationServer

Singleton {
    id: root

    // Same directory as the theme files, which home-manager guarantees exists.
    readonly property string configDirectory: Core.Paths.shell

    // On-screen lifetime used when an app asks for the server default (expire_timeout of -1).
    readonly property int defaultTimeout: 3500

    // Apps are allowed to request a longer life, but not forever;
    // a 5-minute toast is always a bug in the sending app.
    readonly property int maxTimeout: 10000

    // Older toasts are pushed out once this many are stacked.
    readonly property int maxVisible: 4

    // trackedNotifications has no upper bound of its own, so on a long uptime it
    // grows until the shell is restarted. The oldest entries are dropped past
    // this point.
    readonly property int maxHistory: 100

    readonly property alias notifications: server.trackedNotifications

    // Do not disturb. A user preference about notifications, so it lives with
    // notifications rather than on the popup registry — which is what let this
    // module reach into a view-layer singleton just to read it.
    property bool dnd: false

    property var toasts: []

    // The notification whose reply field is currently open, or null.
    //
    // Owned here rather than by either surface, because the toast overlay has to
    // switch its keyboard focus mode on it and the centre has to be able to close
    // it. Only one reply can be open at a time.
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

    // Urgency 2 == Critical in the freedesktop spec. Not a flag(): the hint is
    // absent on some senders and present-but-non-boolean on others, so this
    // reads it as a number.
    function isCritical(n) {
        return Number(Core.Util.get(n, "urgency", 0)) === 2;
    }

    // Sound.
    //
    // Two files in the config's own assets, because "the notification sound" is
    // a preference and the freedesktop set is a keyboard bell. `tink` is the
    // one macOS has used for notifications for years; `glass` is the louder,
    // lower variant, which is what a critical alert should be allowed to be.
    //
    // A toast the user is already looking at does not need to be heard, which is
    // the whole point of dnd — so dnd silences the bell as well as the overlay.
    // Critical is exempt, for the same reason it is exempt from dnd.
    readonly property string sounds: Quickshell.shellDir + "/assets/sounds/"

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

        // Reassigned, then restarted. QProcess::setProgram is a no-op while
        // running, and the file differs with urgency, so a stopped instance is
        // required -- same reason as NightLightService's gamma.
        soundProcess.command = [
            "pw-play",
            root.sounds + (root.isCritical(n) ? "mac_os_glass.mp3" : "mac_os_tink.mp3")
        ];
        Core.Util.restart(root.sound);
    }

    // The sender asked for this one NOT to be kept in a notification area.
    // Volume and brightness popups from other apps set it.
    function isTransient(n) {
        return Core.Util.flag(n, "transient");
    }

    // The sender wants the entry to survive an action being invoked, so it can
    // keep updating it. Media players use it for their transport buttons.
    function isResident(n) {
        return Core.Util.flag(n, "resident");
    }

    // Re-emitted from a previous generation after a config reload.
    function isLastGeneration(n) {
        return Core.Util.flag(n, "lastGeneration");
    }

    // The sender attached a reply field, e.g. a chat client.
    function hasInlineReply(n) {
        return Core.Util.flag(n, "hasInlineReply");
    }

    // Action button labels are icon NAMES rather than text when the sender set
    // the action-icons hint. See NotificationAction.identifier.
    function hasActionIcons(n) {
        return Core.Util.flag(n, "hasActionIcons");
    }

    function replyPlaceholder(n) {
        const hint = String(Core.Util.get(n, "inlineReplyPlaceholder", ""));

        return hint !== "" ? hint : "Reply";
    }

    // Best label for the sending application.
    function appLabel(n) {
        const name = String(Core.Util.get(n, "appName", ""));

        if (name !== "")
            return name;

        const entry = String(Core.Util.get(n, "desktopEntry", ""));

        return entry !== "" ? entry : "Notification";
    }

    // Icon source for a notification, or "" when the sender gave us nothing
    // usable and the caller should fall back to a glyph.
    //
    // `image` already covers image-data, image_data, icon_data AND
    // image-path/image_path: Quickshell resolves all of them into this one
    // property, so there is no separate path to check.
    //
    // A *name* is the one case that has to be dropped. image-path is the
    // freedesktop way to name an icon, and Quickshell turns a name into
    // `image://icon/<name>` -- a provider that hands Qt a null pixmap on 0.3.0.
    // A null pixmap is not a load failure, so it paints: the image comes out as
    // the magenta/black checkerboard, and the caller's `status === Image.Ready`
    // guard never fires. `iconPath(name, true)` is no way out either -- it
    // returns "" for every name, including ones the theme actually has. So the
    // name is discarded and the caller draws its glyph instead. Real payloads
    // (file and data URLs) still render.
    function iconFor(n) {
        const image = String(Core.Util.get(n, "image", ""));

        if (image !== "" && image.indexOf("image://") !== 0)
            return image;

        const name = String(Core.Util.get(n, "appIcon", ""));

        return name !== "" ? Quickshell.iconPath(name, true) : "";
    }

    // Arrival timestamps
    //
    // The notification spec carries no timestamp, and Quickshell does not add
    // one, so it has to be recorded here on arrival. Keyed by notification id and
    // dropped again when the entry closes.
    property var stamps: ({})

    // Bumped on a timer so relative "5m" labels re-evaluate. Read it inside an
    // age binding to make that binding depend on it.
    property int ageTick: 0

    function ageOf(n) {
        const id = Core.Util.get(n, "id", -1);

        if (id === -1)
            return 0;

        const t = root.stamps[id];

        // Restored entries have no live object behind them, so their arrival
        // time travels in the entry itself.
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

    // Only needed while the panel that shows these labels is actually up.
    Timer {
        interval: Core.Theme.slowPollMs

        repeat: true

        running: Core.PopupManager.isOpen("notifications")

        onTriggered: root.ageTick++
    }

    // On-screen lifetime in ms.
    function lifetimeFor(n) {
        if (root.isCritical(n))
            return 0;

        const t = Number(Core.Util.get(n, "expireTimeout", -1));

        if (isNaN(t) || t <= 0)
            return root.defaultTimeout;

        return Math.min(t * 1000, root.maxTimeout);
    }

    function showToast(n) {
        // Do-not-disturb hides the overlay, but never a critical alert: those are
        // the low-battery and imminent-shutdown warnings, and they stay on screen.
        // Everything else still reaches history, so nothing is actually lost.
        if (root.dnd && !root.isCritical(n))
            return;
        const next = root.toasts.slice();
        next.push(n);

        while (next.length > root.maxVisible)
            next.shift();

        root.toasts = next;
    }

    // Removes the card from the overlay but leaves the history entry alone.
    function hideToast(n) {
        const next = [];

        for (var i = 0; i < root.toasts.length; i++) {
            if (root.toasts[i] !== n)
                next.push(root.toasts[i]);
        }

        if (next.length !== root.toasts.length)
            root.toasts = next;

        // The reply field went with the card, so the overlay must be allowed to
        // give keyboard focus back.
        if (root.replyTarget === n)
            root.replyTarget = null;
    }

    // A toast reached the end of its life.
    //
    // Transient entries are discarded rather than filed: the sender explicitly
    // asked not to have them persisted. Everything else stays for the centre.
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

    // Removes the card AND the history entry.
    function dismiss(n) {
        // A restored entry is a plain object with no server behind it, so there is
        // nothing to close: it only has to leave the file.
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
                // Nothing more we can do; the entry will go away
                // when the sender closes it.
            }
        }
    }

    // Invoking an action already closes the notification unless the sender marked
    // it resident, so this must NOT dismiss afterwards: that would be a second
    // close on a destroyed object, which Quickshell logs as
    // "Cannot close destroyed notification".
    //
    // A resident entry deliberately survives, so only its toast is taken down.
    function invokeAction(n, action) {
        if (!n || !action)
            return;

        try {
            action.invoke();
        } catch (e) {
            // Sender dropped off the bus before we got here.
        }

        if (root.isResident(n))
            root.hideToast(n);
    }

    // Same closing semantics as invokeAction: sendInlineReply() closes a
    // non-resident notification itself.
    function sendReply(n, text) {
        if (!n || text === undefined || text === null || String(text) === "")
            return false;

        // Quickshell logs a critical error rather than throwing if the entry has
        // no reply action, so the guard has to happen here.
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

    // Drop the oldest history entries once the cap is passed.
    function prune() {
        const list = server.trackedNotifications;

        if (!list || !list.values)
            return;

        // Snapshot first: dismissing mutates the model we are walking.
        const values = list.values.slice();

        const excess = values.length - root.maxHistory;

        if (excess <= 0)
            return;

        for (var i = 0; i < excess; i++)
            root.dismiss(values[i]);
    }

    // History persistence
    //
    // trackedNotifications lives in the process, so a shell restart used to empty
    // the centre. What is on disk is deliberately not a notification: a restored
    // entry is a plain object, because the server that owned the original is long
    // gone. That means no actions and no inline reply on a restored row -- a
    // button that can no longer be delivered to anyone is worse than no button.
    //
    // Images are not persisted for the same reason, only cheaper: a notification
    // image is an inline data URL, and a hundred of them would turn this file
    // into tens of megabytes.

    readonly property string archivePath: root.configDirectory + "/notifications.json"

    property var archive: []

    // A persist before the first read would write an empty history over the file it
    // was about to restore.
    property bool archiveLoaded: false

    readonly property var archiveFile: FileView {
        path: root.archivePath

        watchChanges: true
        blockLoading: true
        printErrors: false

        onFileChanged: root.loadArchive()
    }

    // Live entries first, then what survived the last restart. Live entries are
    // always the newer ones, so this is already newest-first.
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

            // Shaped like a live notification so both surfaces can render the two
            // kinds from one delegate: the empty action list and the false
            // capability flags are what the delegate already checks.
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

        // Live entries and restored ones together. The live list is everything that
        // arrived this run and the archive is what was already on disk, so they
        // cannot hold the same entry, and the live ones are always newer.
        //
        // Writing only the live list would drop the archive on the first change
        // after a restart.
        const records = values.map(root.serialise).concat(root.archive.map(root.serialise));

        // Nothing at all: remove the file rather than leaving an empty array behind
        // for the next start to read.
        if (records.length === 0) {
            root.archiveFile.setText("");
            return;
        }

        root.archiveFile.setText(JSON.stringify(records.slice(0, root.maxHistory)));
    }

    // Works for a live notification and for a restored entry alike, which is what
    // lets persist() treat them as one list.
    function serialise(n) {
        // A restored entry is a plain object from our own file, so its fields are
        // read directly -- Util.get is for the live objects, whose properties the
        // sender is allowed to omit.
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

    // The live list changed shape: a notification arrived, was dismissed, or was
    // closed by its sender.
    Connections {
        target: server

        function onTrackedNotificationsChanged() {
            root.persist();
        }
    }

    function clearAll() {
        const list = server.trackedNotifications;

        if (list && list.values) {
            // Snapshot first: dismissing mutates the model we are walking.
            const values = list.values.slice();

            for (let i = 0; i < values.length; i++)
                root.dismiss(values[i]);
        }

        root.archive = [];

        root.persist();
    }

    Notifs.NotificationServer {
        id: server

        // Bring the unread backlog back across a config reload instead of wiping
        // it. Restored entries arrive flagged as lastGeneration, which is what
        // keeps them from re-toasting below.
        keepOnReload: true

        // Every one of these is opt-in, and an unset flag is not cosmetic: it is
        // reported through GetCapabilities, and well-behaved senders read that
        // and downgrade what they send. Leaving them off is how a desktop ends up
        // quietly receiving less than every other desktop.
        //
        // Nothing is advertised here that the UI does not actually render.
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false

        imageSupported: true

        actionsSupported: true
        actionIconsSupported: true

        // Lets chat clients attach a reply field. Both the toast and the centre
        // render one; without this flag they never offer it in the first place.
        inlineReplySupported: true

        persistenceSupported: true

        onNotification: function (notification) {
            // Required. An untracked notification is destroyed the moment this
            // handler returns, which would take the toast down with it.
            notification.tracked = true;

            // Captured now: the id is unreadable once the object is destroyed, so
            // the cleanup closure below cannot go and fetch it later.
            var id = -1;

            try {
                id = notification.id;
            } catch (e) {}

            if (id !== -1)
                root.stamps[id] = Date.now();

            // If the sender or the panel closes this entry, make sure a live toast for it does not outlive it.
            try {
                notification.closed.connect(function () {
                    root.hideToast(notification);

                    if (root.replyTarget === notification)
                        root.replyTarget = null;

                    if (id !== -1)
                        delete root.stamps[id];
                });
            } catch (e) {
                // Signal not available in this build; the toast
                // still expires on its own timer.
            }

            root.prune();

            // Restored by keepOnReload. It is already in history and was already
            // shown once, so toasting it would replay the entire backlog every
            // time the config is saved.
            if (root.isLastGeneration(notification))
                return;

            root.showToast(notification);
            root.playSound(notification);
        }
    }

    // The blocking FileView is loaded by the time this runs, but its first change
    // notification is not what a restore should depend on.
    Component.onCompleted: root.loadArchive()

    // Turning on do-not-disturb clears whatever is already on screen, otherwise the current batch would hang around.
    onDndChanged: {
        if (!root.dnd)
            return;

        // Criticals stay: they are not what do-not-disturb is for.
        const kept = [];

        for (var i = 0; i < root.toasts.length; i++) {
            if (root.isCritical(root.toasts[i]))
                kept.push(root.toasts[i]);
        }

        if (kept.length !== root.toasts.length)
            root.toasts = kept;
    }
}
