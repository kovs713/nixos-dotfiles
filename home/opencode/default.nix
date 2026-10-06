{
  programs.opencode = {
    enable = true;

    settings = builtins.fromJSON (builtins.readFile ./opencode.json);
    context = ./AGENTS.md;
    skills = ./skills;
  };

  xdg.configFile = {
    "opencode/prompts".source = ./prompts;
    "opencode/agent".source = ./agent;
    "opencode/opencode-notifier.json".source = ./opencode-notifier.json;
  };
}
