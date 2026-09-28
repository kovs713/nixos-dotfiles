{
  globals = {
    mapleader = " ";
    maplocalleader = " ";
    deprecation_warnings = false;
    skip_ts_context_commentstring_module = true;

    # vim-tpipeline otherwise replaces tmux `status-right` with its own
    # bridge file (autoload/tpipeline.vim, g:tpipeline_embedopts), and the
    # right half of that is the part of our stl after `%=` — which
    # mini.statusline has no section for, so it renders empty and the
    # keymap indicator in the tmux bar disappears while nvim runs.
    # With split=0 the left bridge carries the whole stl and tmux's own
    # status-right is left alone, so windows, vim status and locale stay
    # on one bar.
    tpipeline_split = 0;
  };

  opts = {
    number = true;
    relativenumber = true;
    mouse = "a";
    showmode = true;
    breakindent = true;
    undofile = true;
    ignorecase = true;
    smartcase = true;
    signcolumn = "yes";
    updatetime = 250;
    timeoutlen = 300;
    splitright = true;
    splitbelow = true;
    list = false;
    listchars = {
      tab = "» ";
      trail = "·";
      nbsp = "␣";
    };
    inccommand = "split";
    cursorline = true;
    scrolloff = 10;
    laststatus = 2;
    cmdheight = 1; # was 0, then 1 at end of options.lua
    autowrite = true;
    conceallevel = 2;
    confirm = true;
    fillchars = {
      foldopen = "";
      foldclose = "";
      fold = " ";
      foldsep = " ";
      diff = "╱";
      eob = " ";
    };
    expandtab = true;
    jumpoptions = "view";
    linebreak = true;
    ruler = false;
    shiftround = true;
    shiftwidth = 2;
    clipboard = "unnamedplus";
    langremap = true;
  };

  diagnostic.settings = {
    underline = true;
    virtual_text = false;
    update_in_insert = false;
    severity_sort = true;
    signs = false;
  };

  extraConfigLuaPre = builtins.readFile ../lua/kovs/display.lua;
}
