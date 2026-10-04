pragma Singleton

import QtQuick
import Quickshell.Io

import "." as Core

QtObject {
    id: theme

    property var themeFile: FileView {
        path: Core.Paths.shell + "/theme.json"

        watchChanges: true
        blockLoading: true

        onFileChanged: {
            this.reload();
        }
    }

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

    readonly property color background: colors.background || "#000000"

    readonly property color surface: colors.surface || "#1c1c1c"

    readonly property color surfaceHover: colors.surfaceHover || "#303030"

    readonly property color border: colors.border || "#303030"

    readonly property color borderActive: colors.accent || "#d70000"

    readonly property color separator: colors.separator || "#303030"

    readonly property bool isLight: (data.mode || "dark") == "light"

    readonly property color panelRim: isLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.10)

    readonly property color text: colors.text || "#dadada"

    readonly property color textSecondary: colors.textSecondary || "#707070"

    readonly property color textMuted: colors.textMuted || "#707070"

    readonly property color accent: colors.accent || "#d70000"

    readonly property color accentHover: colors.accentHover || "#d70000"

    readonly property color accentActive: colors.accentActive || "#ffffff"

    readonly property color accentMuted: colors.accentMuted || "#707070"

    readonly property color accentForeground: colors.accentForeground || "#000000"

    readonly property color success: colors.success || "#dadada"

    readonly property color warning: colors.warning || "#dadada"

    readonly property color error: colors.error || "#d70000"

    readonly property color foreground: text

    readonly property color foregroundMuted: textSecondary

    readonly property color foregroundFaint: textMuted

    readonly property color danger: error

    readonly property color accentSoft: accentMuted

    readonly property int borderWidth: 0

    readonly property int radius: 10

    readonly property int radiusSmall: 6

    readonly property int radiusLarge: 18

    readonly property int iconSize: 16

    readonly property int iconSizeSmall: Math.round(iconSize * 0.875)

    readonly property int iconSizeMedium: Math.round(iconSize * 1.25)

    readonly property int iconSizeLarge: Math.round(iconSize * 1.6)

    readonly property int fontSize: 15
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeLarge: 18

    readonly property int pillHeight: 32

    readonly property int moduleHeight: 30

    readonly property int barMarginTop: 10

    readonly property int radiusMenu: radiusLarge

    readonly property int radiusRow: radius + 2

    readonly property int padding: 10

    readonly property int spacing: 6

    readonly property string fontFamily: fonts.interface || "SFProDisplay Nerd Font"
    readonly property string fontMono: fonts.terminal || "CaskaydiaMono Nerd Font"

    readonly property string iconFont: fonts.terminal || "CaskaydiaMono Nerd Font"

    readonly property string emojiFont: fonts.emoji || "Twitter Color Emoji"

    readonly property int popupWidth: 340

    readonly property int popupMaxHeight: 460

    readonly property int popupGap: 10

    readonly property int launcherMaxHeight: 620

    readonly property int rowHeight: 42

    readonly property int durFast: 110

    readonly property int durBase: 180

    readonly property int barRevealDuration: 200

    readonly property int barHideDuration: 140

    readonly property int barCollapseDelay: 180

    readonly property int slowPollMs: 30000
}
