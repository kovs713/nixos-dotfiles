import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.ii.desktopIcons
import qs.modules.ii.desktopWidgets
import qs.modules.ii.hotCorners
import qs.modules.ii.lock
import qs.modules.ii.macDock
import qs.modules.ii.mediaControls
import qs.modules.ii.menubar
import qs.modules.ii.notificationPopup
import qs.modules.ii.onScreenDisplay
import qs.modules.ii.overview
import qs.modules.ii.polkit
import qs.modules.ii.regionSelector
import qs.modules.ii.screenCorners
import qs.modules.ii.sessionScreen
import qs.modules.ii.sidebarLeft
import qs.modules.ii.sidebarRight

/**
 * The macOS set: a menubar, a dock, a control centre, and no bar anywhere.
 *
 * The agent island is gone (it was the notch's whole job), and three panels that
 * existed only to be reachable from the bar go with it: Cheatsheet, the on-screen
 * keyboard and the wallpaper selector. The wallpaper selector is also the only
 * caller of scripts/colors/switchwall.sh, so dropping it is what lets matugen
 * stay uninstalled.
 *
 * Background is gone too, and that is a decision rather than an omission: the
 * wallpaper belongs to awww (a solid theme colour, drawn in the background
 * layer), and macOS blurs panels over a sharp desktop picture rather than blurring
 * the picture itself. A second Background on top would just cover awww.
 *
 * OnScreenDisplay is the notch's old job: the volume and brightness HUD.
 */
Scope {
    PanelLoader { component: Menubar {} }
    PanelLoader { extraCondition: Config.options.background.widgets.todo.enable; component: DesktopWidgets {} }
    PanelLoader { component: DesktopIcons {} }
    PanelLoader { extraCondition: Config.options.dock.enable && Config.options.dock.macStyleDock; component: MacDock {} }
    PanelLoader { component: MediaControls {} }
    PanelLoader { component: NotificationPopup {} }
    PanelLoader { component: OnScreenDisplay {} }
    PanelLoader { component: Overview {} }
    PanelLoader { component: Polkit {} }
    PanelLoader { component: RegionSelector {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { component: SessionScreen {} }
    PanelLoader { component: SidebarLeft {} }
    PanelLoader { component: SidebarRight {} }
    PanelLoader { component: HotCorners {} }
    PanelLoader { component: Lock {} }
}
