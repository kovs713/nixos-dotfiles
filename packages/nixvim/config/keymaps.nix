{
  keymaps = [
    {
      mode = "n";
      key = "<leader>s";
      action = "<CMD>write<CR><ESC>";
      options.desc = "Save buffer";
    }
    {
      mode = "n";
      key = "<leader>ы";
      action = "<CMD>write<CR><ESC>";
      options.desc = "Save buffer";
    }

    {
      mode = "n";
      key = "<leader>nr";
      action = "<CMD>restart<CR>";
      options.desc = "[N]eovim [R]estart";
    }

    {
      mode = [
        "n"
        "v"
        "i"
        "c"
      ];
      key = "<M-Space>";
      action = "<Nop>";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<C-d>";
      action = "<C-d>zz";
    }
    {
      mode = "n";
      key = "<C-u>";
      action = "<C-u>zz";
    }
    {
      mode = "n";
      key = "n";
      action = "'Nn'[v:searchforward].'zv'";
      options = {
        expr = true;
        desc = "Next Search Result";
      };
    }
    {
      mode = "x";
      key = "n";
      action = "'Nn'[v:searchforward]";
      options = {
        expr = true;
        desc = "Next Search Result";
      };
    }
    {
      mode = "o";
      key = "n";
      action = "'Nn'[v:searchforward]";
      options = {
        expr = true;
        desc = "Next Search Result";
      };
    }
    {
      mode = "n";
      key = "N";
      action = "'nN'[v:searchforward].'zv'";
      options = {
        expr = true;
        desc = "Prev Search Result";
      };
    }
    {
      mode = "x";
      key = "N";
      action = "'nN'[v:searchforward]";
      options = {
        expr = true;
        desc = "Prev Search Result";
      };
    }
    {
      mode = "o";
      key = "N";
      action = "'nN'[v:searchforward]";
      options = {
        expr = true;
        desc = "Prev Search Result";
      };
    }
    {
      mode = "n";
      key = "*";
      action = "*zz";
    }
    {
      mode = "n";
      key = "#";
      action = "#zz";
    }
    {
      mode = "n";
      key = "g*";
      action = "g*zz";
    }
    {
      mode = "n";
      key = "g#";
      action = "g#zz";
    }
    {
      mode = "v";
      key = "<";
      action = "<gv";
    }
    {
      mode = "v";
      key = ">";
      action = ">gv";
    }
    {
      mode = "v";
      key = "p";
      action = "\"_dP";
      options.desc = "Paste without saving";
    }
    {
      mode = "n";
      key = "<ESC>";
      action = "<CMD>noh<CR>";
      options = {
        silent = true;
        desc = "Clear search";
      };
    }
    {
      mode = "n";
      key = "]-";
      action = "<CMD>normal! ]c<CR>";
      options.desc = "Diff next change";
    }
    {
      mode = "n";
      key = "[c";
      action = "<CMD>normal! [c<CR>";
      options.desc = "Diff prev change";
    }
  ];

  extraConfigLua = builtins.readFile ../lua/kovs/keymaps.lua;
}
