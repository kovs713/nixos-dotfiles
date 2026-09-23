{ ... }:
let
  rt = ../runtime;
  ft = name: {
    target = "after/ftplugin/${name}.lua";
    source = rt + "/ftplugin/${name}.lua";
  };
in
{
  programs.nixvim = {
    extraFiles = {
      "colors/monochrome.lua".source = rt + "/colors/monochrome.lua";
      "lua/kovs/utils/detect.lua".source = rt + "/lua/kovs/utils/detect.lua";
      "lua/kovs/snippets.lua".source = rt + "/lua/kovs/snippets.lua";
    }
    // builtins.listToAttrs (
      map
        (name: {
          inherit name;
          value = ft name;
        })
        [
          "go"
          "python"
          "lua"
          "html"
          "twig"
          "vue"
          "typescript"
          "typescriptreact"
          "javascript"
          "markdown"
          "sql"
        ]
    )
    // builtins.listToAttrs (
      map
        (name: {
          name = "snippets-${name}";
          value = {
            target = "lua/kovs/snippets/${name}.lua";
            source = rt + "/snippets/${name}.lua";
          };
        })
        [
          "go"
          "javascript"
          "typescript"
          "markdown"
        ]
    );
  };
}
