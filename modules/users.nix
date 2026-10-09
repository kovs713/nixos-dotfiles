{ pkgs, ... }:
{
  virtualisation.docker.enable = true;
  virtualisation.docker = {
    storageDriver = "btrfs";
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  programs.fish = {
    enable = true;

    loginShellInit = ''
      if status is-login; and test -z "$WAYLAND_DISPLAY"; and test "$(tty)" = "/dev/tty1"
          exec start-hyprland
      end
    '';

    shellAliases = {
      g = "git";

      gst = "git status";
      glo = "git log --oneline --decorate --graph --all";

      grs = "git restore";

      gc = "git commit --verbose --all";
      gca = "git commit --amend";

      gp = "git push";
      gpf = "git push --force";

      gl = "git pull";
      gf = "git fetch";

      gra = "git remote add";
      grrm = "git remote remove";

      gcl = "git clone --recurse-submodules";

      ga = "git add";
      gaa = "git add --all";

      gb = "git branch";
      gbd = "git branch --delete";
      gbD = "git branch --delete --force";
      gbm = "git branch --move";
      gsw = "git switch";
      gswc = "git switch --create";

      dcu = "docker compose up";
      dcd = "docker compose down";

      v = "nvim";
      rmsw = "rm ~/.local/state/nvim/swap/*.swp 2>/dev/null";

      c = "clear";
      tr = "tree -L 1 --dirsfirst";

      ta = "tmux attach";

      oc = "opencode";
    };
  };

  users.users.kovs = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "render"
      "input"
      "docker"
    ];
    initialPassword = " ";
    shell = pkgs.fish;
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      glibc
      zlib
      openssl
      icu
      libffi
    ];
  };
}
