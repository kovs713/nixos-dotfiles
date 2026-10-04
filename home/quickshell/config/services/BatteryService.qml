pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../core" as Core

Singleton {
    id: root

    readonly property var device: (typeof UPower !== "undefined" && UPower.displayDevice) ? UPower.displayDevice : null

    readonly property bool available: root.device !== null && root.device.isPresent === true && root.device.isLaptopBattery !== false

    readonly property real percent: root.device ? root.normalise(root.device.percentage) : 0

    readonly property int percentInt: Math.round(root.percent)

    readonly property int state: root.device ? root.device.state : 0

    readonly property bool charging: root.state === 1 || root.state === 5

    readonly property bool full: root.state === 4

    readonly property bool discharging: root.state === 2 || root.state === 6

    readonly property bool onAc: root.charging || root.full || (typeof UPower !== "undefined" && UPower.onBattery === false)

    readonly property int secondsToEmpty: root.device && root.device.timeToEmpty ? root.device.timeToEmpty : 0

    readonly property int secondsToFull: root.device && root.device.timeToFull ? root.device.timeToFull : 0

    readonly property real changeRate: root.device && root.device.changeRate ? Math.abs(root.device.changeRate) : 0

    readonly property real health: (root.device && root.device.healthSupported && root.device.healthPercentage) ? root.normalise(root.device.healthPercentage) : -1

    readonly property int lowThreshold: 20
    readonly property int criticalThreshold: 10

    readonly property bool low: root.available && !root.onAc && root.percentInt <= root.lowThreshold

    readonly property bool critical: root.available && !root.onAc && root.percentInt <= root.criticalThreshold

    readonly property ListModel peripheralModel: ListModel {}

    readonly property var allDevices: (typeof UPower !== "undefined" && UPower.devices) ? UPower.devices.values : []

    onAllDevicesChanged: root.rebuildPeripherals()

    readonly property bool profilesAvailable: typeof PowerProfiles !== "undefined"

    readonly property int profile: root.profilesAvailable ? PowerProfiles.profile : 1

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

    readonly property string icon: {
        if (!root.available)
            return Core.Icons.plug;

        if (root.critical && !root.charging)
            return Core.Icons.batteryAlert;

        const idx = Math.max(0, Math.min(10, Math.round(root.percent / 10)));

        return root.charging || root.full ? Core.Icons.batteryChargeRamp[idx] : Core.Icons.batteryRamp[idx];
    }

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

    function rebuildPeripherals() {
        const items = [];

        const list = root.allDevices || [];

        for (let i = 0; i < list.length; i++) {
            const dev = list[i];

            if (!dev)
                continue;

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

    readonly property Process launcher: Process {}

    function launch(command) {
        Core.Util.restart(root.launcher, command);
    }

    function openPowerSettings() {
        root.launch(["sh", "-c", "command -v gnome-control-center >/dev/null " + "&& gnome-control-center power " + "|| command -v xfce4-power-manager-settings " + ">/dev/null && xfce4-power-manager-settings " + "|| command -v powerprofilesctl >/dev/null " + "&& powerprofilesctl list"]);
    }

    Component.onCompleted: root.rebuildPeripherals()

    Timer {
        interval: Core.Theme.slowPollMs
        running: true
        repeat: true

        onTriggered: root.rebuildPeripherals()
    }
}
