{
  config,
  ...
}:
let
  identity = "${config.xdg.configHome}/agenix/id_ed25519";
  sshDir = "${config.home.homeDirectory}/.ssh";
in
{
  age = {
    identityPaths = [ identity ];

    secrets = {
      "ssh-github" = {
        file = ../secrets/ssh-github.age;
        path = "${sshDir}/github";
        mode = "0600";
      };

      "ssh-gitverse" = {
        file = ../secrets/ssh-gitverse.age;
        path = "${sshDir}/gitverse";
        mode = "0600";
      };

      "ssh-signing" = {
        file = ../secrets/ssh-signing.age;
        path = "${sshDir}/signing";
        mode = "0600";
      };
    };
  };

  programs.ssh = {
    enable = true;

    settings = {
      "github.com" = {
        identityFile = [ "${sshDir}/github" ];
        identitiesOnly = true;
      };
      "gitverse.ru" = {
        identityFile = [ "${sshDir}/gitverse" ];
        identitiesOnly = true;
      };
    };
  };

  programs.git = {
    enable = true;

    userName = "kovs713";
    userEmail = "ovsyannikov.k.k@gmail.com";

    signing = {
      format = "ssh";
      key = "${sshDir}/signing";
      signByDefault = true;

      allowedSigners = "kovs713@ovsyannikov.k.k@gmail.com namespaces=\"git\" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAwMk8AqJNeWl7haZKq/mYXigjYQmQJ/OgYVaK2bDcX5";
    };

    extraConfig.init.defaultBranch = "master";
  };
}
