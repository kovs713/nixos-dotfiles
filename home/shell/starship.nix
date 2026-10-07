{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$git_metrics$character";

      git_status = {
        format = "\$all_status\$ahead_behind\$up_to_date ";
        up_to_date = "[±](green)";
        ahead = "[⇡\$count](green)";
        behind = "[⇣\$count](red)";
        diverged = "[⇡\$ahead_count⇣\$behind_count](yellow)";
        staged = "[+\$count](green)";
        modified = "[!\$count](yellow)";
        untracked = "[?\$count](red)";
      };

      # fish-default look
      directory.style = "bold cyan";
      directory.format = "[\$path](\$style) ";
      git_branch.symbol = "";
      git_branch.style = "bold green";
      git_branch.format = "[\$symbol\$branch](\$style) ";

      character.format = "[\$symbol](\$style) ";
      character.success_symbol = "[>](bold green)";
      character.error_symbol = "[>](bold red)";
    };
  };
}
