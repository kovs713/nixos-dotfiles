# nixos dotfiles ❄️ 

One flake, two machines, two very different desktops.  
Laptop runs a quickshell bar, desktop pretends to be a mac.

---

## what's inside

| | |
|---|---|
| system | NixOS, Limine, zram + swapfile |
| shell | fish, autologin straight into hyprland |
| wm | hyprland (a fork of it) |
| bar | quickshell — bar, popups, notifications, launcher, notes |
| desktop shell | illogical-impulse — menubar, mac dock, no agent island |
| editor | nvim through the nixvim module, monochrome |
| theme | stylix, two base16 schemes |
| rebuilds | `x` |

---

## setup

```bash
git clone https://github.com/kovs713/nixos-dotfiles.git ~/dotfiles
cd ~/dotfiles
sudo nixos-install --flake .#laptop-black
```

### outputs

| output | machine |
|---|---|
| `laptop-black` | laptop, dark |
| `laptop-white` | laptop, light |
| `desktop` | desktop, dark, mac shell |

`hosts/<name>/hardware-configuration.nix` is whatever the installer generated.
The desktop doesn't have one yet, so that output needs the file dropped in
before it evaluates.

### layout

| | |
|---|---|
| `flake.nix` | inputs, `mkHost`, outputs, dev shell |
| `modules/` | shared, split by domain: base, boot, desktop, networking, users |
| `hosts/<name>/` | one directory per machine |
| `home/` | home-manager: `laptop/` and `desktop/` are siblings |
| `packages/` | what the repo builds rather than configures: `x`, `nixvim` |

---

## theme

`black` and `white` live in `home/themed/schemes/`. The variant is part of the
output name, so switching is a rebuild, not a variable to edit:

```bash
x theme
```

stylix owns every color and font and nothing names a hex value. two things stay
hand written because stylix has no target for either: the bar's 18 roles in
`home/laptop/quickshell/theme.nix`, and monochrome in nvim, which reads
`org.gnome.desktop.interface color-scheme` by itself and likes whatever set it —
that's also why `stylix.targets.nixvim` is off.

---

## x

```bash
x               # this help
x theme         # flip black <-> white, then rebuild
x rb            # nixos-rebuild switch, live target
x b             # nixos-rebuild build, live target
x gc            # nix store gc
x upd [input]   # nix flake update
x ch            # everything under checks
```

it reads the live target from `/etc/x/target`, written at every switch, so it
never has to guess the machine or the theme.

---

## checks

`x check` runs it all inside the dev shell, because `nixfmt` and `node` are in
neither the system nor the user `PATH`:

```bash
nix develop --command bash -c '
  files=$(find modules home packages -name "*.nix")
  for file in $files; do nix-instantiate --parse "$file" >/dev/null; done
  nixfmt --check $files
  nix eval --no-update-lock-file .#nixosConfigurations.laptop-black.config.system.build.toplevel.drvPath
  for t in model-sync fuzzy calendar launcher-search; do node home/laptop/quickshell/$t.test.mjs; done
'
```

those four node tests lift the bar's pure logic out of QML and assert it, which
is the part lint can't see. `home/laptop/quickshell/lint.sh` is qmllint over
every file — 340 warnings is the baseline, so diff against it.

`desktop` is not part of any of this: it has no hardware configuration and no
display, so there is nothing on it to validate.

---

[home/desktop/README.md](home/desktop/README.md).

---

> steal whatever, no attribution needed
