//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"
import "panelFamilies"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    // Stuff for every panel family
    ReloadPopup {}

    // The first-run wizard is gone with welcome.qml: it asked about policies and
    // random anime wallpapers, and the policies now come from the config.json Nix
    // seeds on the desktop.
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Idle.load()          // keep the idle inhibitor alive from startup (AC keep-awake policy)
        Updates.load()
    }


    // Panel families. One of them: the waffle family was a second, Windows-style
    // shell and went with the agent island, so there is nothing left to cycle.
    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && Config.options.panelFamily === identifier && extraCondition
    }

    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }


    // Live introspection: `qs ipc call debug guessIcon kitty`
    // (diagnose icon-resolution failures without restarting the shell)
    IpcHandler {
        target: "debug"

        function guessIcon(appId: string): string {
            return AppSearch.guessIcon(appId);
        }
        function iconPath(name: string): string {
            return Quickshell.iconPath(name, true);
        }
    }
}
