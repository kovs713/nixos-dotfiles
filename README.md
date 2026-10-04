# nixos dotfiles ❄️ 

One flake, two machines, one shell. Laptop and desktop run the same
quickshell bar; what differs is the hardware under it, which the bar reads at
runtime.

---

## what's inside

| | |
|---|---|
| system | NixOS, Limine, zram + swapfile |
| shell | fish, autologin straight into hyprland |
| wm | hyprland (a fork of it) |
| bar | quickshell — bar, popups, notifications, launcher, notes |
| per-host bar | nothing. slots follow the hardware: no radio, no bluetooth, no backlight, no battery means no slot |
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
| `desktop-black` | desktop, dark |
| `desktop-white` | desktop, light |

`hosts/<name>/hardware-configuration.nix` is whatever the installer generated.

### layout

| | |
|---|---|
| `flake.nix` | inputs, `mkHost`, outputs, dev shell |
| `modules/` | shared, split by domain: base, boot, desktop, networking, users |
| `hosts/<name>/` | one directory per machine |
| `home/` | home-manager: `home.nix` and `hyprland.nix` are shared, `laptop/` and `desktop/` are the two hosts, `quickshell/` is the bar both of them run |
| `packages/` | what the repo builds rather than configures: `x`, `nixvim` |

---

## theme

`black` and `white` live in `home/themed/schemes/`, and every machine has one
output per variant. the variant is part of the output name, so switching is a
rebuild rather than a variable to edit, and `x theme` is that rebuild with the
name flipped:

```bash
x theme
```

stylix owns every color and font and nothing names a hex value. two things stay
hand written because stylix has no target for either: the bar's 18 roles in
`home/quickshell/theme.nix`, and monochrome in nvim, which reads
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
x sh            # list the dev shell stacks
x sh <stack>... # enter one or more: node, rust, go, python, lua,
                #   quickshell, data, infra
```

it reads the live target from `/etc/x/target`, written at every switch, so it
never has to guess the machine or the theme.

`x sh` is one dev shell per stack instead of one dev shell with everything in
it, because the union is a rust toolchain, four language servers and a
`qtdeclarative` build nobody wants at the same time. `flake.nix` holds the map,
`x sh` reads the names out of it. every stack gets gcc, pkg-config, make and jq
on top of its own list; `checks` is the one `x ch` uses. one stack goes through
`nix develop`; two or more go through `nix shell`, because `nix develop` takes a
single attribute and merges nothing while `nix shell` unions the PATH of
several. `default` is empty, because `nix develop` with no name should ask which
stack rather than answer for you.

---

## checks

`x ch` is `packages/x/check.sh`, run inside the `checks` dev shell because
`nixfmt` and `node` are in neither the system nor the user `PATH`. the script
takes the live target as its only argument:

```bash
bash packages/x/check.sh laptop-black 
```

those four node tests lift the bar's pure logic out of QML and assert it, which
is the part lint can't see. `home/quickshell/lint.sh` is qmllint over
every file — 344 warnings is the baseline, so diff against it.

`x ch desktop-black` is the same script against the other outputs. All four
share every file the checks read, so a run against one covers the other's
configuration too; only the two host directories differ, and neither is more
than a package list and an import.

---

> steal whatever, no attribution needed
