{ ... }:
{
  programs.opencode = {
    enable = true;

    settings = builtins.fromJSON (builtins.readFile ./opencode/opencode.json);
    context = ./opencode/AGENTS.md;
    skills = ./opencode/skills;
  };

  xdg.configFile = {
    "opencode/prompts".source = ./opencode/prompts;
    "opencode/agent".source = ./opencode/agent;
    "opencode/opencode-notifier.json".source = ./opencode/opencode-notifier.json;
  };
}
