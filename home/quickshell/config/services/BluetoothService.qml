pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

import "../core" as Core

// BluetoothService

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property bool available: root.adapter !== null

    readonly property bool powered: root.adapter ? root.adapter.enabled : false

    readonly property bool discovering: root.adapter ? root.adapter.discovering : false

    // Written by Bluetooth.qml through a string-keyed Binding, so nothing in the
    // services layer can see it and qmllint cannot check it. Poll faster while
    // the popup is up, where a connecting device has to be noticed at once.
    property bool fastPoll: false

    // Desktop notifications

    property var lastConnected: []
    property bool btPrimed: false

    property bool lastPowered: false
    property bool poweredPrimed: false

    // Fire and forget. One shared Process dropped the second notification
    // whenever two devices changed state in the same instant.
    function notify(summary, body, icon, urgency) {
        Core.Util.notify("Bluetooth", icon, urgency, summary, body);
    }

    function connectedAddresses() {
        const out = [];

        for (const d of root.allDevices)
            if (d && d.connected && d.address)
                out.push(String(d.address));

        return out;
    }

    function syncDeviceNotifications() {
        const now = root.connectedAddresses();
        const prev = root.lastConnected;

        root.lastConnected = now;

        // Devices arrive asynchronously after the adapter appears, so the first pass is bookkeeping only.
        if (!root.btPrimed) {
            root.btPrimed = true;
            return;
        }

        for (const addr of now)
            if (prev.indexOf(addr) === -1)
                root.notify(root.displayName(root.deviceByAddress(addr)), "Connected", "bluetooth-active", "low");

        for (const addr of prev)
            if (now.indexOf(addr) === -1) {
                const gone = root.deviceByAddress(addr);
                root.notify(gone ? root.displayName(gone) : addr, "Disconnected", "bluetooth-disabled", "normal");
            }
    }

    onPoweredChanged: {
        if (!root.poweredPrimed) {
            root.poweredPrimed = true;
            root.lastPowered = root.powered;
            return;
        }

        if (root.powered === root.lastPowered)
            return;

        root.lastPowered = root.powered;

        if (root.powered)
            root.notify("Bluetooth on", "Adapter powered on", "bluetooth-active", "low");
        else
            root.notify("Bluetooth off", "Adapter powered off", "bluetooth-disabled", "low");
    }

    // Address of a device with an operation in flight
    property string pendingAddress: ""

    readonly property ListModel deviceModel: ListModel {}

    // Raw device list from the binding

    readonly property var allDevices: {
        if (!Bluetooth.devices)
            return [];

        const src = Bluetooth.devices.values ? Bluetooth.devices.values : [];

        return src;
    }

    readonly property int connectedCount: {
        let n = 0;

        for (const d of root.allDevices)
            if (d && d.connected)
                n++;

        return n;
    }

    readonly property string primaryLabel: {
        for (const d of root.allDevices)
            if (d && d.connected)
                return root.displayName(d);

        if (!root.powered)
            return "Bluetooth off";

        return "Not connected";
    }

    // Helpers

    function displayName(dev) {
        if (!dev)
            return "Unknown";

        if (dev.alias && dev.alias !== "")
            return dev.alias;

        if (dev.name && dev.name !== "")
            return dev.name;

        if (dev.deviceName && dev.deviceName !== "")
            return dev.deviceName;

        return dev.address ? dev.address : "Unknown";
    }

    function stateLabel(dev) {
        if (!dev)
            return "";

        if (root.pendingAddress === dev.address)
            return "Working\u2026";

        if (dev.connected)
            return dev.batteryAvailable ? "Connected · " + Math.round(dev.battery * 100) + "%" : "Connected";

        if (dev.paired || dev.bonded)
            return dev.trusted ? "Paired · Trusted" : "Paired";

        return "Available";
    }

    function deviceByAddress(addr) {
        for (const d of root.allDevices)
            if (d && d.address === addr)
                return d;

        return null;
    }

    function rank(dev) {
        if (!dev)
            return 3;
        if (dev.connected)
            return 0;
        if (dev.paired || dev.bonded)
            return 1;
        return 2;
    }

    // Build the row objects, then hand them to ModelSync, which is what keeps
    // the delegates stable => real animations.

    function rebuildModel() {
        const list = [];

        for (const d of root.allDevices) {
            if (!d || !d.address)
                continue;
            list.push({
                address: String(d.address),
                deviceName: root.displayName(d),
                deviceIcon: Core.DeviceIcons.forName(d.icon),
                stateText: root.stateLabel(d),
                connected: d.connected === true,
                paired: (d.paired === true) || (d.bonded === true),
                trusted: d.trusted === true,
                blocked: d.blocked === true,
                battery: d.batteryAvailable ? Math.round(d.battery * 100) : -1
            });
        }

        list.sort(function (a, b) {
            const da = root.deviceByAddress(a.address);
            const db = root.deviceByAddress(b.address);

            const ra = root.rank(da);
            const rb = root.rank(db);

            if (ra !== rb)
                return ra - rb;

            return a.deviceName.localeCompare(b.deviceName);
        });

        Core.ModelSync.sync(root.deviceModel, list, "address", false);
    }

    // Rebuild first so deviceByAddress() can resolve names for anything that just appeared, then diff for notifications.
    onAllDevicesChanged: {
        root.rebuildModel();
        root.syncDeviceNotifications();
    }

    // A second trigger on the connected set used to sit here, as a
    // `connectedKey` derived from allDevices. It fired together with
    // onAllDevicesChanged on every device change, so rebuildModel sorted and
    // diffed the whole list twice and set() every row twice; the notification
    // diff survived that only because lastConnected had already caught up.
    // The key was a pure function of allDevices, so it could never change
    // without allDevices changing first.

    readonly property Timer syncTimer: Timer {
        interval: root.fastPoll ? 800 : Core.Theme.slowPollMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.rebuildModel()
    }

    // bluetoothctl fallback

    readonly property Process ctlProc: Process {
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    function btctl(args) {
        Core.Util.restart(root.ctlProc, ["bluetoothctl"].concat(args));
    }

    // Public API

    function setPowered(on) {
        if (root.adapter) {
            root.adapter.enabled = on;
            return;
        }

        root.btctl(["power", on ? "on" : "off"]);
    }

    function togglePowered() {
        root.setPowered(!root.powered);
    }

    function setDiscovering(on) {
        if (root.adapter) {
            root.adapter.discovering = on;
            return;
        }

        root.btctl(["scan", on ? "on" : "off"]);
    }

    function toggleDiscovering() {
        root.setDiscovering(!root.discovering);
    }

    function connectDevice(addr) {
        const dev = root.deviceByAddress(addr);
        root.pendingAddress = addr;
        clearPending.restart();

        if (dev && typeof dev.connect === "function") {
            dev.connect();
            return;
        }

        root.btctl(["connect", addr]);
    }

    function disconnectDevice(addr) {
        const dev = root.deviceByAddress(addr);
        root.pendingAddress = addr;
        clearPending.restart();

        if (dev && typeof dev.disconnect === "function") {
            dev.disconnect();
            return;
        }

        root.btctl(["disconnect", addr]);
    }

    function toggleDevice(addr) {
        const dev = root.deviceByAddress(addr);

        if (dev && dev.connected)
            root.disconnectDevice(addr);
        else
            root.connectDevice(addr);
    }

    function pairDevice(addr) {
        const dev = root.deviceByAddress(addr);
        root.pendingAddress = addr;
        clearPending.restart();

        if (dev && typeof dev.pair === "function") {
            dev.pair();
            return;
        }

        root.btctl(["pair", addr]);
    }

    function forgetDevice(addr) {
        const dev = root.deviceByAddress(addr);

        if (dev && typeof dev.forget === "function") {
            dev.forget();
        } else {
            root.btctl(["remove", addr]);
        }

        root.rebuildModel();
    }

    function setTrusted(addr, on) {
        const dev = root.deviceByAddress(addr);

        if (dev && dev.trusted !== undefined) {
            dev.trusted = on;
            root.rebuildModel();
            return;
        }

        root.btctl([on ? "trust" : "untrust", addr]);
    }

    function setBlocked(addr, on) {
        const dev = root.deviceByAddress(addr);

        if (dev && dev.blocked !== undefined) {
            dev.blocked = on;
            root.rebuildModel();
            return;
        }

        root.btctl([on ? "block" : "unblock", addr]);
    }

    function openManager() {
        Quickshell.execDetached(["blueman-manager"]);
    }

    readonly property Timer clearPending: Timer {
        interval: 6000
        repeat: false
        onTriggered: root.pendingAddress = ""
    }
}
