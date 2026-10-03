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
is the part lint can't see. `home/laptop/quickshell/lint.sh` is qmllint over
every file — 340 warnings is the baseline, so diff against it.

`desktop` is not part of any of this: it has no hardware configuration and no
display, so there is nothing on it to validate.

---

[home/desktop/README.md](home/desktop/README.md).

---

> steal whatever, no attribution needed
