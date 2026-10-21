{
  programs.fish.enable = true;
  programs.fish.functions = {
    bd = {
      body = builtins.readFile ./bd.fish;
      description = "Copy contents of all files in directory to clipboard";
    };

    ssd = {
      body = ''
        set -l dir (zoxide query -l | fzf)
        if test -n "$dir"
            cd "$dir"
        end
      '';
      description = "Smart cd using zoxide and fzf";
    };

    sst = {
      body = builtins.readFile ./smart-tmux.fish;
      description = "Create/attach to smart tmux session based on directory name/hash";
    };

    tn = {
      body = builtins.readFile ./tmux-new.fish;
      description = "Create new tmux session named after current directory";
    };
  };

  programs.zoxide.enable = true;
  programs.zoxide.enableFishIntegration = true;

  programs.fzf.enable = true;
}
