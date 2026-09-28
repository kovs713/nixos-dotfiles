let
  defaultOpts = {
    localOpts = {
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      softtabstop = 2;
    };
  };
in
{
  files = {
    "ftplugin/nix.lua" = defaultOpts;
    "ftplugin/go.lua" = defaultOpts;
    "ftplugin/html.lua" = defaultOpts;
    "ftplugin/javascript.lua" = defaultOpts;
    "ftplugin/lua.lua" = defaultOpts;
    "ftplugin/python.lua" = defaultOpts;
    "ftplugin/twig.lua" = defaultOpts;
    "ftplugin/typescript.lua" = defaultOpts;
    "ftplugin/typescriptreact.lua" = defaultOpts;
    "ftplugin/vue.lua" = defaultOpts;

    "ftplugin/markdown.lua" = {
      localOpts = {
        textwidth = 80;
        linebreak = true;
      };
    };
    "ftplugin/sql.lua" = {
      localOpts.formatprg = "sqlfluff format --dialect postgres -";
    };
  };
}
