pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property int statePaused: 5;

    readonly property int stateActive: 6;

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

    readonly property bool screenSharing: root.hasStream(PwNodeType.VideoSource)

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
