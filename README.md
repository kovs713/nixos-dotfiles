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
x ch            # nix parse, nixfmt, flake eval, qmllint
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
on top of its own list. one stack goes through `nix develop`; two or more go
through `nix shell`, because `nix develop` takes a single attribute and merges
nothing while `nix shell` unions the PATH of several. `default` is empty, because
`nix develop` with no name should ask which stack rather than answer for you.

---

## keyboard
 
corne v4 with 3 layers, home row mods on `a s d f` / `j k l ;` (Super, Alt, Shift, Ctrl).
 
```
  layer 0 · base
  ┌─────┬─────┬─────┬─────┬─────┬─────┐     ┌─────┬─────┬─────┬─────┬─────┬─────┐
  │ tab │  q  │  w  │  e  │  r  │  t  │     │  y  │  u  │  i  │  o  │  p  │  [  │
  ├─────┼─────┼─────┼─────┼─────┼─────┤     ├─────┼─────┼─────┼─────┼─────┼─────┤
  │ esc │  a  │  s  │  d  │  f  │  g  │     │  h  │  j  │  k  │  l  │  ;  │  '  │
  ├─────┼─────┼─────┼─────┼─────┼─────┤     ├─────┼─────┼─────┼─────┼─────┼─────┤
  │  `  │  z  │  x  │  c  │  v  │  b  │     │  n  │  m  │  ,  │  .  │  /  │  \  │
  └─────┴─────┴─────┴─────┴─────┴─────┘     └─────┴─────┴─────┴─────┴─────┴─────┘
                      ┌─────┬─────┬─────┐ ┌─────┬─────┬─────┐
                      │ mo2 │ mo1 │ spc │ │ ent │ bsp │ del │
                      └─────┴─────┴─────┘ └─────┴─────┴─────┘
 
  layer 1 · sym
  ┌─────┬─────┬─────┬─────┬─────┬─────┐     ┌─────┬─────┬─────┬─────┬─────┬─────┐
  │ tab │  !  │  @  │  #  │  $  │  %  │     │  ^  │  &  │  *  │  (  │  )  │  ]  │
  ├─────┼─────┼─────┼─────┼─────┼─────┤     ├─────┼─────┼─────┼─────┼─────┼─────┤
  │ esc │  1  │  2  │  3  │  4  │  5  │     │  6  │  7  │  8  │  9  │  0  │  \  │
  ├─────┼─────┼─────┼─────┼─────┼─────┤     ├─────┼─────┼─────┼─────┼─────┼─────┤
  │  ~  │  _  │  +  │  -  │  =  │     │     │     │  {  │  }  │  <  │  >  │     │
  └─────┴─────┴─────┴─────┴─────┴─────┘     └─────┴─────┴─────┴─────┴─────┴─────┘
                      ┌─────┬─────┬─────┐ ┌─────┬─────┬─────┐
                      │ mo2 │ mo1 │ spc │ │ ent │ bsp │ del │
                      └─────┴─────┴─────┘ └─────┴─────┴─────┘
 
  layer 2 · nav
  ┌─────┬─────┬─────┬─────┬─────┬─────┐     ┌─────┬─────┬─────┬─────┬─────┬─────┐
  │  f1 │  f2 │  f3 │  f4 │  f5 │  f6 │     │  f7 │  f8 │  f9 │ f10 │ f11 │ f12 │
  ├─────┼─────┼─────┼─────┼─────┼─────┤     ├─────┼─────┼─────┼─────┼─────┼─────┤
  │ br+ │ prt │ mb3 │ mb2 │ mb1 │  wu │     │  ←  │  ↓  │  ↑  │  →  │  v+ │ pgu │
  ├─────┼─────┼─────┼─────┼─────┼─────┤     ├─────┼─────┼─────┼─────┼─────┼─────┤
  │ br- │ mut │  ◀◀ │  ❚❚ │  ▶▶ │  wd │     │  m← │  m↓ │  m↑ │  m→ │  v- │ pgd │
  └─────┴─────┴─────┴─────┴─────┴─────┘     └─────┴─────┴─────┴─────┴─────┴─────┘
                      ┌─────┬─────┬─────┐ ┌─────┬─────┬─────┐
                      │ mo2 │ mo1 │ spc │ │ ent │ bsp │ del │
                      └─────┴─────┴─────┘ └─────┴─────┴─────┘
```

---

## checks

`x ch` is `packages/x/check.sh`. it takes the live target as its only argument:

```bash
bash packages/x/check.sh laptop-black
```

it parses every `.nix`, checks formatting with `nixfmt`, evaluates the target's
toplevel, then runs `home/quickshell/lint.sh` — `qmllint` over every QML file.
344 warnings is the baseline, so diff against it; errors must be zero.

`x ch desktop-black` is the same script against the other outputs. All four
share every file the checks read, so a run against one covers the other's
configuration too; only the two host directories differ, and neither is more
than a package list and an import.

---

> steal whatever, no attribution needed
