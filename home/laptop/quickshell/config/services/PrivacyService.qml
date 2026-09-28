pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

// Screen-share and microphone activity.
//
// Everything else in the shell reports state through the bar, but the bar is
// hidden until hovered, so a privacy dot that lives there is invisible exactly
// when it matters. This service only exposes the flags; the indicator is its own
// always-on surface (modules/Privacy.qml).
//
// A link group is a source wired to a target, so "is something recording" is a
// question about link groups, not about nodes: a node with no links is idle.
Singleton {
    id: root

    // PwLinkState: Error, Unlinked, Init, Negotiating, Allocating, Paused, Active.
    // Only the last two mean a link is carrying data; a group stuck in Init or
    // Negotiating is a capture that never started, and Unlinked is just a wire
    // that was made and dropped.
    readonly property int statePaused: 5;

    readonly property int stateActive: 6;

    // Only groups that are actually running count. A paused stream still has a
    // group, and reporting it as idle would hide a live capture.
    readonly property var activeGroups: {
        const values = (Pipewire.linkGroups && Pipewire.linkGroups.values) ? Pipewire.linkGroups.values : [];

        const result = [];

        for (let i = 0; i < values.length; i++) {
            const group = values[i];

            try {
                const state = Number(group.state);

                if (state === root.statePaused || state === root.stateActive)
                    result.push(group);
            } catch (e) {}
        }

        return result;
    }

    // Capture targets an application: a screen recorder, a meeting client. The
    // target is a stream, the source is what is being captured.
    readonly property bool screenSharing: root.hasStream(PwNodeType.VideoSource)

    // An app pulling microphone samples into a stream. Two-sided duplex (a call
    // that both plays and records) counts: the mic really is hot.
    readonly property bool micActive: root.hasStream(PwNodeType.AudioSource)

    readonly property bool active: root.screenSharing || root.micActive

    function hasStream(sourceType) {
        for (let i = 0; i < root.activeGroups.length; i++) {
            const group = root.activeGroups[i];

            try {
                if (Number(group.source.type) === sourceType && Number(group.target.type) === PwNodeType.Stream)
                    return true;
            } catch (e) {}
        }

        return false;
    }
}
