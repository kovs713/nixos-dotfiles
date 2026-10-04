pragma Singleton

import QtQuick
import Quickshell.Io

import "." as Core

QtObject {
    id: theme

    // Shell Runtime Theme
    //
    // Один файл, один вариант. Раньше здесь было два FileView: на
    // `active-theme` (id варианта) и на `themes/<id>.json`, и смена темы
    // была мгновенной. Теперь тему выбирает stylix на этапе сборки, файл
    // один и он меняется вместе с Home Manager, так что второй FileView
    // только и делал, что перезагружал первый.

    property var themeFile: FileView {
        path: Core.Paths.shell + "/theme.json"

        watchChanges: true
        blockLoading: true

        onFileChanged: {
            this.reload();
        }
    }

    // Parsed Theme

    readonly property var data: {
        if (!theme.themeFile.loaded)
            return ({});

        try {
            return JSON.parse(theme.themeFile.text());
        } catch (error) {
            console.warn("Shell Theme: invalid JSON:", error);

            return ({});
        }
    }

    readonly property var fonts: data.fonts || ({})

    readonly property var colors: data.colors || ({})

    // Background

    readonly property color background: colors.background || "#000000"

    // Surfaces

    readonly property color surface: colors.surface || "#1c1c1c"

    readonly property color surfaceHover: colors.surfaceHover || "#303030"

    // Borders

    readonly property color border: colors.border || "#303030"

    readonly property color borderActive: colors.accent || "#d70000"

    readonly property color separator: colors.separator || "#303030"

    // Which variant Nix wrote. The JSON carries it so this never has to guess
    // from a colour's luminance.
    readonly property bool isLight: (data.mode || "dark") == "light"

    // Light hairline for floating surfaces.
    //
    // The themed `border` is a dark grey, which on a dark pill over a wallpaper
    // reads as a hole cut around the panel rather than an edge on it. A
    // translucent white rim reads as light catching the top of the surface, which
    // is what makes a translucent rectangle look like glass. One pixel, and
    // independent of `borderWidth`, which is 0 in the shipped themes.
    //
    // Inverted under `white`: a white rim on a white bar is invisible, and the
    // same argument that wants light on dark wants a dark edge on light.
    readonly property color panelRim: isLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.10)

    // Text

    readonly property color text: colors.text || "#dadada"

    readonly property color textSecondary: colors.textSecondary || "#707070"

    readonly property color textMuted: colors.textMuted || "#707070"

    // Accent

    readonly property color accent: colors.accent || "#d70000"

    readonly property color accentHover: colors.accentHover || "#d70000"

    readonly property color accentActive: colors.accentActive || "#ffffff"

    readonly property color accentMuted: colors.accentMuted || "#707070"

    readonly property color accentForeground: colors.accentForeground || "#000000"

    // Semantic States

    readonly property color success: colors.success || "#dadada"

    readonly property color warning: colors.warning || "#dadada"

    readonly property color error: colors.error || "#d70000"

    // Compatibility Aliases

    readonly property color foreground: text

    readonly property color foregroundMuted: textSecondary

    readonly property color foregroundFaint: textMuted

    readonly property color danger: error

    readonly property color accentSoft: accentMuted

    // UI
    //
    // Geometry, radii, glyph sizes and type scale. Deliberately not themeable.
    //
    // These used to read a `ui` object out of the theme JSON behind a
    // `!== undefined` guard, and no theme Nix renders writes one: themes.nix
    // emits `colors` and `fonts` and says so. So every value took its fallback,
    // and the guard existed to let a zero through a `||` that no caller could
    // reach anyway. If a theme ever does need to move these, write the key and
    // read it here.

    readonly property int borderWidth: 0

    readonly property int radius: 10

    readonly property int radiusSmall: 6

    readonly property int radiusLarge: 18

    readonly property int iconSize: 16

    // Glyph sizes were spread across ten different expressions from 10px to 26px,
    // several taken from FONT tokens, which is why some icons looked large and
    // others small. Four steps, derived from iconSize so they move together.
    readonly property int iconSizeSmall: Math.round(iconSize * 0.875)

    readonly property int iconSizeMedium: Math.round(iconSize * 1.25)

    readonly property int iconSizeLarge: Math.round(iconSize * 1.6)

    readonly property int fontSize: 15
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeLarge: 18

    // Existing QuickShell Geometry

    readonly property int pillHeight: 32

    readonly property int moduleHeight: 30

    readonly property int barMarginTop: 10

    // Was a hardcoded 18, identical to radiusLarge.
    readonly property int radiusMenu: radiusLarge

    // Was a hardcoded 12, an undeclared fourth radius step between radius (10) and radiusLarge (18).
    readonly property int radiusRow: radius + 2

    readonly property int padding: 10

    readonly property int spacing: 6

    // Typography

    readonly property string fontFamily: fonts.interface || "SFProDisplay Nerd Font"
    readonly property string fontMono: fonts.terminal || "CaskaydiaMono Nerd Font"

    // The family that actually contains the Nerd Font glyphs. Derived from the
    // theme so it cannot drift from fonts.terminal the way the hardcoded string
    // here had already drifted from the system font set.
    readonly property string iconFont: fonts.terminal || "CaskaydiaMono Nerd Font"

    // Colour font. Only NativeRendering draws its glyphs in colour.
    readonly property string emojiFont: fonts.emoji || "Twitter Color Emoji"

    // For a label mixing prose and glyphs in one string there is no
    // font.families list any more: nothing read it, so it was dropped. Qt would
    // resolve such a label by letting fontconfig guess a fallback. Set the family
    // per Text instead, or add the list back here, if a mixed label ever renders
    // with the wrong glyphs.

    // Popup Geometry

    readonly property int popupWidth: 340

    readonly property int popupMaxHeight: 460

    // Visible detachment from the bar pill. At 2 the cards looked welded to it.
    readonly property int popupGap: 10

    // Tallest a launcher popup may grow. Bar sizes its PanelWindow from this,
    // and LauncherView clamps itself to it, so the window is always big enough
    // to contain the popup it has to host.
    readonly property int launcherMaxHeight: 620

    readonly property int rowHeight: 42

    // Animation

    // Motion is intentionally short and deterministic.
    readonly property int durFast: 110

    readonly property int durBase: 180

    // Collapsing Bar

    readonly property int barRevealDuration: 200

    readonly property int barHideDuration: 140

    readonly property int barCollapseDelay: 180

    // How often a device service re-reads state that nothing pushes at it.
    // Peripheral battery percentages, the notification archive's age labels and
    // the reminders list all settle lazily, and a slow tick keeps them honest
    // without costing anything. Four services had the same 30000 written out.
    readonly property int slowPollMs: 30000
}
