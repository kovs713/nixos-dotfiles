import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "." as Mods
import "../core" as Core
import "../services" as Services

// The one PanelWindow for the bar and the launcher popups.
//
// A single `surface` morphs between three states:
//
//   normal pill   ->  contentWidth  x pillHeight,  fully rounded
//   OSD pill      ->  osdWidth      x pillHeight,  fully rounded
//   popup         ->  cardWidth     x viewHeight,  radiusLarge
//
// Only that surface animates. The window itself is a fixed tall box so the popup
// has somewhere to live, while the visible pill floats above the desktop.

PanelWindow {
    id: root

    anchors {
        bottom: true
        left: true
        right: true
    }

    // Flush to the bottom of the screen, so the trigger strip below is the last
    // `barMarginTop` pixels of it rather than a band floating above them. The
    // pill keeps `surfaceTop` between itself and the window's bottom edge, so it
    // moves 10px closer to the edge and the strip fills the gap it left.
    margins.bottom: 0

    // Fixed, and deliberately never animated: tall enough for the largest
    // launcher plus the pill above it. Animating this would move the reserved
    // area and shove windows around on every popup.
    implicitHeight: root.surfaceTop + Core.Theme.launcherMaxHeight + 40

    color: "transparent"

    // Floating overlay: never reserve space in the compositor work area.
    exclusiveZone: 0

    WlrLayershell.namespace: "shell-bar"

    // Keyboard only while a launcher is up; the bar itself never wants focus.
    WlrLayershell.keyboardFocus: root.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Where the surface sits inside the window: the pill floats this far above
    // the window's bottom edge, and the trigger strip fills the gap down to the
    // screen. PopupSurface measures the bar's band in its input mask off
    // barMarginTop + pillHeight -- two literals that have to agree.
    readonly property int surfaceTop: Core.Theme.barMarginTop

    // Launchers

    readonly property var launchers: [appLauncher, reminderPicker, clipboardView, emojiPicker]

    // A launcher's `open` is already `PopupManager.isOpen(launcherId)`, so the
    // registry knows which one is open. Asking all four in turn duplicated that
    // fact here; look it up by id instead.
    readonly property var activeLauncher: {
        const list = root.launchers;
        const id = Core.PopupManager.current;

        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].launcherId === id)
                return list[i];
        }

        return null;
    }

    // The bar draws the launcher's card, so it must know the card's size. That
    // coupling is inherent to the pill -> card morph and is left alone: the
    // alternative is a bar that does not draw the card.

    readonly property bool launcherOpen: root.activeLauncher !== null

    // While a launcher is open the whole window takes input, so clicking beside
    // the popup still dismisses it. Otherwise only the pill and the edge strip
    // are clickable and everything else passes through to the desktop.
    //
    // ONE Region holding a LIST, for the reason PopupSurface spells out: `mask`
    // is a PendingRegion whose `regions` is its default property, so a JS array
    // was never assignable to it.
    property Region surfaceInput: Region {
        item: surface
    }

    property Region edgeInput: Region {
        item: edge
    }

    property Region barInput: Region {
        regions: [root.surfaceInput, root.edgeInput]
    }

    mask: root.launcherOpen ? null : root.barInput

    // Reveal state

    // Only the module popups (network, bluetooth, battery, audio, calendar,
    // notifications) hold the bar open. Their cards are anchored under the icon
    // that spawned them, so that icon has to stay on screen.
    //
    // Launcher ids are filtered out here rather than leaning on `launcherOpen`.
    // That value is derived through the launcher items, so it settles one pass
    // later than `PopupManager.current` - long enough for the bar to start
    // expanding before the popup takes the surface over.
    readonly property bool modulePopupOpen: {
        const id = Core.PopupManager.current;

        if (id === "")
            return false;

        const list = root.launchers;

        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].launcherId === id)
                return false;
        }

        return true;
    }

    // Both hover sources, not just the pill. The strip is the edge trigger; the
    // pill is in the union so that reaching from the strip up into the expanded
    // bar does not drop it -- the two are adjacent, so that move crosses no dead
    // pixels, and a HoverHandler re-arms on pointer motion rather than on the
    // window changing, which is what used to close the bar under a still cursor.
    readonly property bool wantExpanded: !root.launcherOpen && ((root.autoReveal && (surfaceHover.hovered || edgeHover.hovered)) || root.modulePopupOpen)

    property bool autoReveal: true
    property bool expanded: false

    onWantExpandedChanged: {
        if (root.wantExpanded) {
            collapseTimer.stop();
            root.expanded = true;
            return;
        }

        collapseTimer.restart();
    }

    Timer {
        id: collapseTimer

        interval: Core.Theme.barCollapseDelay

        onTriggered: root.expanded = root.wantExpanded
    }

    // 0 = collapsed
    // 1 = fully expanded
    property real reveal: root.expanded ? 1.0 : 0.0

    Behavior on reveal {
        NumberAnimation {
            // Instant while a launcher is up. `onLauncherOpenChanged` clears
            // `expanded` the moment a popup appears, and that drop must not be
            // visible: an expanded bar shrinking underneath the growing card is
            // exactly the intermediate state we never want.
            duration: root.launcherOpen ? 0 : (root.expanded ? Core.Theme.barRevealDuration : Core.Theme.barHideDuration)
            easing.type: Easing.OutQuint
        }
    }

    // Popup takeover
    //
    // A popup always grows out of the normal pill, never out of the expanded bar.

    // True for one pass of the event loop when a launcher opens. While it is set
    // the surface is snapped back to pill geometry unanimated, so the morph has
    // the pill as its starting point even if the bar happened to be hovered open
    // a moment earlier.
    property bool fromPill: false

    // The surface has to keep animating for a moment after `launcherOpen` goes
    // false, otherwise the card would snap to the pill instead of shrinking into
    // it.
    property bool closing: false

    function releasePill() {
        root.fromPill = false;
    }

    onLauncherOpenChanged: {
        // No collapse delay and no collapse animation: the expanded bar is gone
        // before the popup draws a single frame.
        collapseTimer.stop();
        root.expanded = false;

        if (root.launcherOpen) {
            closeTimer.stop();
            root.closing = false;

            root.fromPill = true;
            Qt.callLater(root.releasePill);
            return;
        }

        root.fromPill = false;
        root.closing = true;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer

        interval: Core.Theme.barRevealDuration

        onTriggered: root.closing = false
    }

    // Is the surface showing anything at all?
    //
    // Written as `root.reveal > 0.012 || root.osdMix > 0.01` in ten places, with
    // two different epsilons and no name for either. `showing` on the surface
    // below already said exactly this and was read in two of the ten; the rest
    // spelled it out. The epsilons are not "0" because reveal is a real
    // mid-animation value here: a surface at 0.004 is invisible but not yet
    // collapsed, and dropping it at 0 would pop.
    readonly property bool showing: root.reveal > 0.012 || root.osdMix > 0.01

    readonly property bool modulesVisible: root.reveal > 0.012 && !root.launcherOpen

    // OSD takeover

    readonly property bool osd: Core.OsdController.active && !root.expanded && !root.launcherOpen

    property real osdMix: root.osd ? 1.0 : 0.0

    Behavior on osdMix {
        NumberAnimation {
            // Snapped for the same reason as `reveal`: the pill a popup grows out
            // of has to be the normal pill, not a half-faded OSD readout.
            duration: root.launcherOpen ? 0 : Core.Theme.barRevealDuration
            easing.type: Easing.OutQuint
        }
    }

    readonly property real barContentWidth: root.showing
        ? content.implicitWidth + (osdView.implicitWidth - content.implicitWidth) * root.osdMix
        : 0

    // Surface geometry
    //
    // One target per dimension, so there is exactly one animation on each and
    // nothing competes.

    // Bar shape until the pill snap has been released, so opening a launcher
    // reads pill -> card and never bar -> card.
    readonly property bool popupShape: root.launcherOpen && !root.fromPill

    readonly property real targetWidth: root.popupShape
        ? root.activeLauncher.cardWidth
        : (root.showing ? root.barContentWidth + 24 : 240)

    readonly property real targetHeight: root.popupShape ? root.activeLauncher.viewHeight : Core.Theme.pillHeight

    readonly property real targetRadius: root.popupShape ? Core.Theme.radiusLarge : Core.Theme.pillHeight / 2

    // Zero while the surface is a bar.
    //
    // In bar state the width comes from `content.implicitWidth`, which `reveal`
    // is already animating. Animating the surface on top of that was a second
    // animation on the same dimension: the surface trailed its own content, and
    // because it clips, the modules were sliced against its edge while expanding
    // and then popped into view. That is the hover jitter.
    //
    // So `reveal` owns hover motion, and the Behaviors below own only the
    // pill <-> card morph and the launcher's live resize as results filter.
    readonly property int morphDuration: root.fromPill ? 0 : ((root.launcherOpen || root.closing) ? Core.Theme.barRevealDuration : 0)

    // THE TRIGGER
    //
    // A full-width strip on the last `barMarginTop` pixels of the screen, and the
    // only reason the window's bottom margin is 0. The bar used to open on hover
    // over its own collapsed pill -- a 240x32 area that is transparent when
    // collapsed, so it asked to be found. macOS's auto-hidden dock asks for the
    // edge instead, and so does this.
    //
    // Hover only, no MouseArea: the strip has to stay in the input region while
    // the bar is expanded, or a cursor sitting on it would collapse the bar and
    // then have no region left to re-hover. The price is that those pixels of
    // every window stop reaching it, which is the trade macOS makes too.
    Item {
        id: edge

        // Parent-relative, not the `left: true` form the window itself uses:
        // that one is Quickshell's anchors group, and a plain Item's anchors
        // take an AnchorLine. qmllint reports both as the same
        // `incompatible-type`, and only one of them loads.
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        height: Core.Theme.barMarginTop

        HoverHandler {
            id: edgeHover
        }
    }

    // THE SURFACE

    Rectangle {
        id: surface

        anchors.horizontalCenter: parent.horizontalCenter

        y: parent.height - root.surfaceTop - height

        readonly property bool showing: root.showing || root.launcherOpen

        width: root.targetWidth

        height: root.targetHeight

        radius: root.targetRadius

        // One predicate for both the fill and the rim. The rim has to follow the
        // fill: an outlined but unfilled pill sits on the wallpaper as a floating
        // hairline, which is the bar's shape hanging there with nothing in it.
        color: surface.showing ? Core.Theme.surface : "transparent"

        border.width: 1
        border.color: surface.showing ? Core.Theme.panelRim : "transparent"

        antialiasing: true

        // Only needed to hold popup content inside the rounded card while it is
        // still growing into it. Left on in bar state it clipped the modules
        // against the surface edge during hover expansion.
        clip: root.launcherOpen

        Behavior on width {
            NumberAnimation {
                duration: root.morphDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: root.morphDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: root.morphDuration
                easing.type: Easing.OutCubic
            }
        }

        // Hover
        //
        // On the surface rather than a MouseArea, so it cannot swallow clicks
        // meant for the popup content inside it.
        HoverHandler {
            id: surfaceHover
        }

        // OSD READOUT

        Mods.BarOsd {
            id: osdView

            anchors.centerIn: parent

            opacity: root.osdMix

            visible: root.osdMix > 0.01 && !root.launcherOpen

            transform: Translate {
                y: (1.0 - root.osdMix) * 4
            }
        }

        // NORMAL BAR CONTENT

        RowLayout {
            id: content

            anchors.centerIn: parent

            spacing: 3

            opacity: 1.0 - root.osdMix

            visible: root.showing && root.osdMix < 0.99 && !root.launcherOpen

            BarSlot {
                reveal: root.reveal

                Mods.NotificationCenter { id: notificationCenter }
            }

            Separator {}

            BarSlot {
                reveal: root.reveal

                Mods.Volume { id: volume }
            }

            Separator {}

            BarSlot {
                reveal: root.reveal

                Mods.Brightness { id: brightness }
            }

            Separator {}

            BarSlot {
                reveal: root.reveal

                Mods.NightLight { id: nightLight }
            }

            Separator {}

            BarSlot {
                reveal: root.reveal

                Mods.Timer { id: timer }
            }

            Separator {}

            // The clock does not collapse with the rest: it is the one module
            // that is always meant to be readable, so its width does not carry a
            // reveal factor.
            Mods.Clock {
                id: clockModule

                Layout.preferredWidth: clockModule.implicitWidth

                Layout.preferredHeight: clockModule.implicitHeight
            }

            Separator {}

            BarSlot {
                reveal: root.reveal

                Mods.Network { id: network }
            }

            Separator {}

            BarSlot {
                reveal: root.reveal

                Mods.Bluetooth { id: bluetooth }
            }

            Separator {}

            BarSlot {
                reveal: root.reveal

                available: Services.BatteryService.available

                Mods.Battery { id: battery }
            }

            Separator {
                available: Services.BatteryService.available
            }

            Mods.Tray {
                id: tray

                barWindow: root

                Layout.preferredWidth: tray.implicitWidth * root.reveal

                Layout.preferredHeight: tray.implicitHeight

                visible: root.modulesVisible

                opacity: root.reveal
            }
        }

        // POPUP CONTENT
        //
        // The launchers live here instead of each owning a PanelWindow. They draw
        // content only: the background, border, radius and clipping all come from
        // the surface above.

        Item {
            anchors.fill: parent

            visible: root.launcherOpen

            Mods.AppLauncher {
                id: appLauncher

                anchors.fill: parent
            }

            Mods.ReminderPicker {
                id: reminderPicker

                anchors.fill: parent
            }

            Mods.Clipboard {
                id: clipboardView

                anchors.fill: parent
            }

            Mods.EmojiPicker {
                id: emojiPicker

                anchors.fill: parent
            }
        }
    }

    // Click-away dismiss while a launcher is open. Behind the surface, so popup
    // content is never blocked.
    MouseArea {
        anchors.fill: parent

        z: -1

        enabled: root.launcherOpen

        acceptedButtons: Qt.LeftButton

        onClicked: Core.PopupManager.close()
    }

    IpcHandler {
        target: "bar"

        function toggleAutoReveal(): void {
            root.autoReveal = !root.autoReveal;
        }
    }

    // A module in the bar.
    //
    // Ten of these, and the four properties below were written out ten times,
    // differing only in the id -- and in the battery module, which hides itself
    // when the machine has no battery.
    //
    // The reveal multiplication is the whole reason the bar's width animates: a
    // collapsed module still occupies its slot, at a fraction of it, rather than
    // disappearing and taking its neighbours' spacing with it.
    component BarSlot: Item {
        id: slot

        property real reveal: 1.0

        // A module with nothing to show hides itself instead of showing an empty
        // button, and its separator goes with it.
        property bool available: true

        // Exactly one child, the module itself, read off `children`.
        //
        // NOT a `default property alias` into a `list<Item>`: a list that is not
        // `data` never reparents its objects, so every module came out with
        // `parent: null` -- alive, sized, and never drawn, which is what turned
        // the bar's row into gaps. `children` is the list the inherited `data`
        // fills, so an inline child is a real visual child.
        readonly property Item module: slot.children.length > 0 ? slot.children[0] : null

        Layout.preferredWidth: slot.module ? slot.module.implicitWidth * slot.reveal : 0

        Layout.preferredHeight: slot.module ? slot.module.implicitHeight : 0

        // The module is a plain child of an Item rather than a layout child, so
        // nothing hands it a size any more. It takes the slot's box, which the
        // slot already took from its implicit size: the same width the RowLayout
        // used to give it, times the same reveal.
        Binding {
            target: slot.module

            property: "width"

            value: slot.width
        }

        Binding {
            target: slot.module

            property: "height"

            value: slot.height
        }

        visible: slot.available && slot.reveal > 0.012

        opacity: slot.reveal
    }

    component Separator: Item {
        id: sep

        // The bar's own reveal, so no call site has to restate it.
        // An inline component shares the enclosing file's ids.
        property real reveal: root.reveal

        property bool available: true

        readonly property color tint: Core.Theme.separator

        Layout.preferredWidth: 1

        Layout.preferredHeight: 18

        visible: sep.available && sep.reveal > 0.012

        opacity: sep.reveal * 0.9

        Rectangle {
            anchors.centerIn: parent

            width: 1

            height: parent.height

            antialiasing: true

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(sep.tint.r, sep.tint.g, sep.tint.b, 0.0)
                }

                GradientStop {
                    position: 0.32
                    color: sep.tint
                }

                GradientStop {
                    position: 0.68
                    color: sep.tint
                }

                GradientStop {
                    position: 1.0
                    color: Qt.rgba(sep.tint.r, sep.tint.g, sep.tint.b, 0.0)
                }
            }
        }
    }
}
