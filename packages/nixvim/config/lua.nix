let
  lua = ../lua;
  queries = ../queries;
in
{
  extraFiles = {
    "colors/monochrome.lua".source = lua + "/monochrome.lua";
    "lua/kovs/utils/detect.lua".source = lua + "/detect.lua";

    "queries/markdown/textobjects.scm".source = queries + "/markdown/textobjects.scm";
    "queries/markdown_inline/textobjects.scm".source = queries + "/markdown_inline/textobjects.scm";
    "queries/typescript/highlights.scm".source = queries + "/typescript/highlights.scm";
    "queries/tsx/highlights.scm".source = queries + "/tsx/highlights.scm";
  };
}
