pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import "../core" as Core

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink

    readonly property var source: Pipewire.defaultAudioSource

    property bool showMonitors: false

    readonly property var allNodes: (Pipewire.nodes && Pipewire.nodes.values) ? Pipewire.nodes.values : []

    readonly property var sinks: {
        const out = [];

        for (let i = 0; i < root.allNodes.length; i++) {
            const n = root.allNodes[i];

            if (!n || !n.audio)
                continue;
            if (n.isStream)
                continue;
            if (!n.isSink)
                continue;
            out.push(n);
        }

        out.sort(function (a, b) {
            return root.label(a).localeCompare(root.label(b));
        });

        return out;
    }

    readonly property var sources: {
        const out = [];

        for (let i = 0; i < root.allNodes.length; i++) {
            const n = root.allNodes[i];

            if (!n || !n.audio)
                continue;
            if (n.isStream)
                continue;
            if (n.isSink)
                continue;
            if (!root.showMonitors && root.isMonitor(n))
                continue;
            out.push(n);
        }

        out.sort(function (a, b) {
            return root.label(a).localeCompare(root.label(b));
        });

        return out;
    }

    readonly property var streams: {
        const out = [];

        for (let i = 0; i < root.allNodes.length; i++) {
            const n = root.allNodes[i];

            if (!n || !n.audio)
                continue;
            if (!n.isStream)
                continue;

            if (!n.isSink)
                continue;
            out.push(n);
        }

        return out;
    }

    readonly property var tracked: {
        const out = [];

        if (root.sink)
            out.push(root.sink);

        if (root.source)
            out.push(root.source);

        return out.concat(root.sinks).concat(root.sources).concat(root.streams);
    }

    readonly property PwObjectTracker tracker: PwObjectTracker {
        objects: root.tracked
    }

    readonly property real volume: (root.sink && root.sink.audio) ? root.sink.audio.volume : 0

    readonly property bool muted: (root.sink && root.sink.audio) ? root.sink.audio.muted : true

    readonly property int volumePercent: Math.round(root.volume * 100)

    readonly property real micVolume: (root.source && root.source.audio) ? root.source.audio.volume : 0

    readonly property bool micMuted: (root.source && root.source.audio) ? root.source.audio.muted : true

    readonly property int micPercent: Math.round(root.micVolume * 100)

    onVolumeChanged: Core.OsdController.show("volume")

    onMutedChanged: Core.OsdController.show("volume")

    onMicMutedChanged: Core.OsdController.show("mic")

    readonly property string icon: {
        if (!root.sink || !root.sink.audio)
            return Core.Icons.volumeOff;

        if (root.muted)
            return Core.Icons.volumeOff;

        if (root.volume <= 0.01)
            return Core.Icons.volumeLow;

        if (root.volume < 0.34)
            return Core.Icons.volumeLow;

        if (root.volume < 0.67)
            return Core.Icons.volumeMedium;

        return Core.Icons.volumeHigh;
    }

    readonly property string micIcon: (!root.source || root.micMuted) ? Core.Icons.micOff : Core.Icons.mic

    function label(node) {
        if (!node)
            return "Unknown device";

        if (node.description && node.description !== "")
            return node.description;

        if (node.nickname && node.nickname !== "")
            return node.nickname;

        if (node.name && node.name !== "")
            return node.name;

        return "Unknown device";
    }

    function streamLabel(node) {
        if (!node)
            return "Unknown app";

        try {
            const props = node.properties;

            if (props) {
                if (props["application.name"])
                    return props["application.name"];

                if (props["media.name"])
                    return props["media.name"];
            }
        } catch (e) {
        }

        return root.label(node);
    }

    function isMonitor(node) {
        if (!node || !node.name)
            return false;

        return node.name.indexOf(".monitor") >= 0;
    }

    function iconFor(node) {
        if (!node)
            return Core.Icons.speaker;

        const text = (root.label(node) + " " + (node.name ? node.name : "")).toLowerCase();

        if (text.indexOf("headset") >= 0 || text.indexOf("headphone") >= 0 || text.indexOf("hands-free") >= 0)
            return Core.Icons.headset;

        if (!node.isSink)
            return Core.Icons.mic;

        return Core.Icons.speaker;
    }

    function isDefault(node) {
        if (!node)
            return false;

        if (node.isSink)
            return root.sink === node;

        return root.source === node;
    }

    function volumeOf(node) {
        if (!node || !node.audio)
            return 0;

        return node.audio.volume;
    }

    function mutedOf(node) {
        if (!node || !node.audio)
            return true;

        return node.audio.muted;
    }

    function percentOf(node) {
        return Math.round(root.volumeOf(node) * 100);
    }

    readonly property real maxVolume: 1.0

    function setVolume(node, value) {
        if (!node || !node.audio)
            return;
        const clamped = Math.max(0.0, Math.min(root.maxVolume, value));

        node.audio.volume = clamped;

        if (clamped > 0.0 && node.audio.muted)
            node.audio.muted = false;
    }

    function stepVolume(node, delta) {
        root.setVolume(node, root.volumeOf(node) + delta);
    }

    function toggleMute(node) {
        if (!node || !node.audio)
            return;
        node.audio.muted = !node.audio.muted;
    }

    function toggleOutputMute() {
        root.toggleMute(root.sink);
    }

    function toggleMicMute() {
        root.toggleMute(root.source);
    }

    function setDefaultSink(node) {
        if (!node)
            return;
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        if (!node)
            return;
        Pipewire.preferredDefaultAudioSource = node;
    }

    function setDefault(node) {
        if (!node)
            return;
        if (node.isSink)
            root.setDefaultSink(node);
        else
            root.setDefaultSource(node);
    }

    readonly property Process launcher: Process {
        id: launcherImpl
    }

    function launch(command) {
        if (launcherImpl.running)
            return;
        launcherImpl.command = command;
        launcherImpl.running = true;
    }

    function openMixer() {
        root.launch(["pavucontrol"]);
    }
}
