# nixos dotfiles ❄️

my machines, one flake. nixos + hyprland + quickshell, laptop and desktop
running the same config, black and white themes.

| | |
|---|---|
| system | nixos, limine, zram + swapfile |
| shell | fish → hyprland, autologin |
| wm | hyprland (fork) |
| bar | quickshell — bar, popups, notifications, launcher, notes |
| editor | nvim via nixvim |
| theme | stylix, base16, monochrome black/white variants |
| rebuild | `x` — run `x` for help |

```
flake.nix      inputs, outputs, dev shells
modules/       shared nixos config
hosts/         one dir per machine
home/          home-manager, quickshell bar
packages/      nixvim, x
```

outputs are `{laptop,desktop}-{black,white}`, theme in the name. switch with
`x theme`. `x ch` runs the checks. keyboard is in [keyboard/](keyboard).

> steal whatever, no attribution needed
