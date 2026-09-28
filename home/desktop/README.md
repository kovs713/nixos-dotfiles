# The desktop shell

The desktop's Quickshell config. Vendored, not written: it is
[openagentisland](https://github.com/patheonsceo/openagentisland) at `0c6cadc`
(2026-09-08), which is end-4/illogical-impulse with a macOS menubar, a macOS
dock and a Claude Code island on top.

The laptop keeps its own shell in `home/laptop/quickshell/`. They are different
programs that happen to both be Quickshell configs, not one shell with two
looks, and neither reads the other's theme: this one is themed by
`MaterialThemeLoader` out of `config.json`, the laptop's by a Stylix-written
`theme.json`. Both are installed under `~/.config/quickshell` on their own host;
the systemd unit runs a bare `qs` and does not know or care which one it got.

## What was cut, and why

| Cut | Why |
| --- | --- |
| the agent island: `IslandNotch`, `AgentSurface`, `IslandLeft/Right`, the kanban and dashboard surfaces, `agentIsland/`, `AgentService` | not wanted |
| `IslandPopup` **kept** | the menubar opens all six of its menus through it |
| the `waffle` panel family | a second, Windows-style shell; one family means nothing to cycle |
| `welcome.qml` + `FirstRunExperience` | the first-run wizard asked about policies and downloaded anime wallpapers; `config.json` is seeded by Nix instead |
| `Background` | the wallpaper is awww's, and macOS blurs panels over a sharp desktop picture rather than blurring the picture |
| `WallpaperSelector` | the only caller of `scripts/colors/switchwall.sh`, so dropping it is what keeps matugen uninstalled |
| `Bar`, `VerticalBar`, `Dock`, `Cheatsheet`, `OnScreenKeyboard`, `ScreenTranslator`, `Overlay`, `FocusOverlay` | no bar to reach them from; `Overlay`'s snip is `RegionSelector` and its recorder is the Capture menu |
| `modules/ii/bar/*` except the tray | `SysTray*` + `StyledPopup` are the menubar's and the lock screen's |
| 15 translations, `translations/tools` | `Translation.tr()` returns the literal when a key is missing |
| `scripts/` except `cava`, `videos`, `hyprland` | matugen, wallpaper thumbnails (a venv), keyring, AI helpers |

## Local edits to the vendored code

Five files differ from upstream. Do not "fix" them back.

- `shell.qml` — no waffle family, no agent service, no first-run wizard
- `panelFamilies/IllogicalImpulseFamily.qml` — the macOS panel list
- `modules/ii/menubar/Menubar.qml` — `exclusionMode: Normal` +
  `exclusiveZone: barHeight`; upstream left the top strip to the island
- `modules/ii/menubar/CaptureMenu.qml` — `Quickshell.shellPath` instead of a
  hardcoded `~/.config/quickshell/openagentisland/...`
- `modules/ii/desktopIcons/DesktopContextMenu.qml` — same, plus "Change
  Wallpaper" is `theme-set` now that the wallpaper is a theme colour

## Re-vendoring

```sh
rsync -a --delete ~/dotfiles-examples/openagentisland/quickshell/ home/desktop/quickshell/
# then re-apply the cuts and the five edits above; the cut list is the table
```

## Checking it

There is no linter for this tree the way the laptop shell has one; the check
that counts is loading it:

```sh
qs -p ~/.config/quickshell
journalctl --user -u quickshell | tail -50
```

`Settings` in the system menu opens the end-4 settings GUI
(`settings.qml`), which edits the same `~/.config/illogical-impulse/config.json`
Nix seeds. It is the one file here that is deliberately **not** read-only: the
shell rewrites it whole the first time anything changes, so a store symlink
would fail the write.
