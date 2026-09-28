pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../core" as Core

// BatteryService

Singleton {
    id: root

    // Main battery

    readonly property var device: (typeof UPower !== "undefined" && UPower.displayDevice) ? UPower.displayDevice : null

    // True when this machine actually has a battery worth showing.
    readonly property bool available: root.device !== null && root.device.isPresent === true && root.device.isLaptopBattery !== false

    // 0..100, always.
    readonly property real percent: root.device ? root.normalise(root.device.percentage) : 0

    readonly property int percentInt: Math.round(root.percent)

    // UPowerDeviceState numeric values: 0 Unknown 1 Charging 2 Discharging 3 Empty 4 FullyCharged 5 PendingCharge 6 PendingDischarge
    readonly property int state: root.device ? root.device.state : 0

    readonly property bool charging: root.state === 1 || root.state === 5

    readonly property bool full: root.state === 4

    readonly property bool discharging: root.state === 2 || root.state === 6

    // AC connected (either explicitly charging, full, or UPower says we are not running on battery).
    readonly property bool onAc: root.charging || root.full || (typeof UPower !== "undefined" && UPower.onBattery === false)

    readonly property int secondsToEmpty: root.device && root.device.timeToEmpty ? root.device.timeToEmpty : 0

    readonly property int secondsToFull: root.device && root.device.timeToFull ? root.device.timeToFull : 0

    // Watts. Negative means draining in some builds — take abs.
    readonly property real changeRate: root.device && root.device.changeRate ? Math.abs(root.device.changeRate) : 0

    readonly property real health: (root.device && root.device.healthSupported && root.device.healthPercentage) ? root.normalise(root.device.healthPercentage) : -1

    // Warning levels

    readonly property int lowThreshold: 20
    readonly property int criticalThreshold: 10

    readonly property bool low: root.available && !root.onAc && root.percentInt <= root.lowThreshold

    readonly property bool critical: root.available && !root.onAc && root.percentInt <= root.criticalThreshold

    // Peripherals (mouse, keyboard, headset, controller...)

    readonly property ListModel peripheralModel: ListModel {}

    readonly property var allDevices: (typeof UPower !== "undefined" && UPower.devices) ? UPower.devices.values : []

    onAllDevicesChanged: root.rebuildPeripherals()

    // Power profiles

    // 0 = power-saver, 1 = balanced, 2 = performance
    readonly property bool profilesAvailable: typeof PowerProfiles !== "undefined"

    readonly property int profile: root.profilesAvailable ? PowerProfiles.profile : 1

    // What the shell last asked for, which runs ahead of `profile`: the write is
    // a D-Bus round trip, and cycling from the read-back made every press inside
    // one compute the same next value -- three presses, one change, arriving
    // long after the finger stopped, which is what read as a button that does
    // not keep up. Followed back onto the read-back on every change, so a
    // profile switched from outside the shell is not left underneath it.
    property int requestedProfile: root.profile

    onProfileChanged: root.requestedProfile = root.profile

    readonly property bool hasPerformance: root.profilesAvailable ? PowerProfiles.hasPerformanceProfile !== false : false

    readonly property string degradationReason: (root.profilesAvailable && PowerProfiles.degradationReason) ? String(PowerProfiles.degradationReason) : ""

    function setProfile(value) {
        if (!root.profilesAvailable)
            return;
        root.requestedProfile = value;
        PowerProfiles.profile = value;
    }

    // Derived labels

    readonly property string stateLabel: {
        if (!root.available)
            return "No battery";

        if (root.full)
            return "Fully charged";

        if (root.charging)
            return root.secondsToFull > 0 ? root.formatTime(root.secondsToFull) + " until full" : "Charging";

        if (root.discharging)
            return root.secondsToEmpty > 0 ? root.formatTime(root.secondsToEmpty) + " remaining" : "On battery";

        if (root.onAc)
            return "Plugged in";

        return "Unknown";
    }

    readonly property string profileLabel: {
        if (!root.profilesAvailable)
            return "";

        switch (root.profile) {
        case 0:
            return "Power saver";
        case 2:
            return "Performance";
        default:
            return "Balanced";
        }
    }

    // The single glyph the bar shows.
    readonly property string icon: {
        if (!root.available)
            return Core.Icons.plug;

        if (root.critical && !root.charging)
            return Core.Icons.batteryAlert;

        const idx = Math.max(0, Math.min(10, Math.round(root.percent / 10)));

        return root.charging || root.full ? Core.Icons.batteryChargeRamp[idx] : Core.Icons.batteryRamp[idx];
    }

    // These are semantic states that already exist in the theme.

    readonly property color color: {
        if (!root.available)
            return Core.Theme.foregroundMuted;

        if (root.critical)
            return Core.Theme.danger;

        if (root.low)
            return Core.Theme.warning;

        if (root.charging || root.full)
            return Core.Theme.success;

        return Core.Theme.foreground;
    }

    function profileIcon(value) {
        switch (value) {
        case 0:
            return Core.Icons.profileSaver;
        case 2:
            return Core.Icons.profilePerformance;
        default:
            return Core.Icons.profileBalanced;
        }
    }

    // Helpers

    // UPower gives 0..1 in most builds, 0..100 in a few.
    function normalise(value) {
        if (value === undefined || value === null)
            return 0;

        const v = Number(value);

        if (isNaN(v))
            return 0;

        return v <= 1.0 ? v * 100 : v;
    }

    function formatTime(seconds) {
        if (!seconds || seconds <= 0)
            return "";

        const total = Math.round(seconds / 60);

        const h = Math.floor(total / 60);
        const m = total % 60;

        if (h <= 0)
            return m + "m";

        if (m <= 0)
            return h + "h";

        return h + "h " + m + "m";
    }

    function deviceLabel(dev) {
        if (!dev)
            return "Device";

        if (dev.model && String(dev.model).length > 0)
            return String(dev.model);

        if (dev.nativePath && String(dev.nativePath).length > 0)
            return String(dev.nativePath);

        return "Device";
    }

    // Peripheral list building

    function rebuildPeripherals() {
        const items = [];

        const list = root.allDevices || [];

        for (let i = 0; i < list.length; i++) {
            const dev = list[i];

            if (!dev)
                continue;

            // Skip the laptop battery + the synthetic display device + AC adapters — they have no useful percent.
            if (dev === root.device)
                continue;
            if (dev.isLaptopBattery === true)
                continue;
            if (dev.isPresent === false)
                continue;
            const pct = root.normalise(dev.percentage);

            if (pct <= 0)
                continue;
            items.push({
                label: root.deviceLabel(dev),
                deviceIcon: Core.DeviceIcons.forName(dev.iconName),
                percent: Math.round(pct),
                charging: dev.state === 1
            });
        }

        items.sort(function (a, b) {
            return a.percent - b.percent;
        });

        Core.ModelSync.sync(root.peripheralModel, items, "label", false);
    }

    // Reconcile a ListModel in place so ListView add/remove transitions actually run instead of everything flashing.

    // External helpers

    readonly property Process launcher: Process {}

    function launch(command) {
        Core.Util.restart(root.launcher, command);
    }

    function openPowerSettings() {
        // Try the usual suspects; the first one installed wins.
        root.launch(["sh", "-c", "command -v gnome-control-center >/dev/null " + "&& gnome-control-center power " + "|| command -v xfce4-power-manager-settings " + ">/dev/null && xfce4-power-manager-settings " + "|| command -v powerprofilesctl >/dev/null " + "&& powerprofilesctl list"]);
    }

    // Lifecycle

    Component.onCompleted: root.rebuildPeripherals()

    // UPower is event driven, but peripheral percentages update lazily — a slow tick keeps them honest without any cost.
    Timer {
        interval: Core.Theme.slowPollMs
        running: true
        repeat: true

        onTriggered: root.rebuildPeripherals()
    }
}
