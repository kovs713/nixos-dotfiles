pragma Singleton

import QtQml
import Quickshell

// Paths
//
// Where the shell keeps things, in one place.
//
// It was nine copies of `Quickshell.env("HOME") + "/.config/shell"`, and the
// distinction it draws is not one to leave to nine files to get right:
//
//   ~/.config/shell      writable state the shell owns -- notes, reminders, the
//                        timer, the night light, the notification archive.
//                        Home Manager does not own it, because the shell writes
//                        it. The one exception is `theme.json`, which Home
//                        Manager does own, because the theme is build-time.
//   ~/.config/quickshell a Nix-owned read-only symlink into the store. FileView
//                        reads it happily and setText on it does nothing, with
//                        no error either way.
//
// Swapping the two fails silently, which is the worst way to fail.
//
// XDG_CONFIG_HOME is read with a fallback rather than trusted: none of these
// directories is created by anything, and a FileView pointed at a missing
// parent fails without a word. `~/.config` is the one a live session has.

QtObject {
    id: root

    readonly property string home: Quickshell.env("HOME")

    readonly property string config: root.xdg("XDG_CONFIG_HOME", "/.config")

    readonly property string cache: root.xdg("XDG_CACHE_HOME", "/.cache")

    // No fallback: a socket path guessed wrong is a socket that is not there.
    readonly property string runtime: Quickshell.env("XDG_RUNTIME_DIR")

    readonly property string shell: root.config + "/shell"

    readonly property string assets: root.config + "/quickshell"

    function xdg(name, fallback) {
        const value = Quickshell.env(name);

        return value && value !== "" ? value : root.home + fallback;
    }
}
