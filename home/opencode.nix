{ ... }:
{
  programs.opencode = {
    enable = true;

    settings = builtins.fromJSON (builtins.readFile ./opencode/opencode.json);

    context = ./opencode/AGENTS.md;

    skills = ./opencode/skills;
  };

  # prompts, the teach agent and the notifier's own config have no home-manager
  # option; the notifier also writes its state file next to it, so the directory
  # stays a real one and only these are links.
  xdg.configFile = {
    "opencode/prompts".source = ./opencode/prompts;
    "opencode/agent".source = ./opencode/agent;
    "opencode/opencode-notifier.json".source = ./opencode/opencode-notifier.json;
  };
}
