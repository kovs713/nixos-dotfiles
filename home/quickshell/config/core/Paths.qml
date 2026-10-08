pragma Singleton

import QtQml
import Quickshell

QtObject {
    id: root

    readonly property string home: Quickshell.env("HOME")

    readonly property string config: root.xdg("XDG_CONFIG_HOME", "/.config")

    readonly property string cache: root.xdg("XDG_CACHE_HOME", "/.cache")

    readonly property string state: root.xdg("XDG_STATE_HOME", "/.local/state")

    readonly property string runtime: Quickshell.env("XDG_RUNTIME_DIR")

    readonly property string shell: root.config + "/shell"

    readonly property string assets: root.config + "/quickshell"

    function xdg(name, fallback) {
        const value = Quickshell.env(name);

        return value && value !== "" ? value : root.home + fallback;
    }
}
