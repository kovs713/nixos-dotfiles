{
  autoGroups = {
    kickstart-highlight-yank = {
      clear = true;
    };
  };

  keymapsOnEvents.LspAttach = [
    {
      mode = [
        "n"
        "v"
      ];
      key = "<leader>ca";
      action.__raw = "function() vim.lsp.buf.code_action() end";
      options.desc = "[C]ode [A]ctions";
    }
    {
      mode = [
        "n"
        "v"
      ];
      key = "<leader>lL";
      action = "<cmd>lsp restart<CR>";
      options.desc = "[L][L]sp Restart";
    }
    {
      mode = "n";
      key = "<leader>li";
      action.__raw = "function() Snacks.picker.lsp_implementations() end";
      options.desc = "[L]sp [I]mplementations";
    }
    {
      mode = "n";
      key = "<leader>ld";
      action.__raw = "function() Snacks.picker.lsp_definitions() end";
      options.desc = "[L]sp [D]efinitions";
    }
    {
      mode = "n";
      key = "gd";
      action.__raw = "function() Snacks.picker.lsp_definitions() end";
      options.desc = "Go to [D]efinition";
    }
    {
      mode = "n";
      key = "<leader>lr";
      action.__raw = "function() Snacks.picker.lsp_references() end";
      options.desc = "[L]sp [R]eferences";
    }
    {
      mode = "n";
      key = "<leader>le";
      action.__raw = ''
        function()
          local tiny = require 'tiny-inline-diagnostic'
          tiny.disable()
          local win = vim.diagnostic.open_float()
          if win == nil then
            tiny.enable()
            return
          end
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'InsertEnter', 'BufLeave', 'WinLeave' }, {
            once = true,
            callback = function() tiny.enable() end,
          })
        end
      '';
      options.desc = "[L]sp Diagnostic Float [E]";
    }
    {
      mode = "n";
      key = "<leader>lh";
      action.__raw = "function() vim.lsp.buf.hover() end";
      options.desc = "[L]sp [H]over Doc";
    }
    {
      mode = "n";
      key = "<leader>ln";
      action.__raw = "function() vim.lsp.buf.rename() end";
      options.desc = "[L]sp Re[N]ame";
    }
    {
      mode = "n";
      key = "<leader>gn";
      action = "<CMD>!go run .<CR>";
      options.desc = "[G]o Ru[N] current project";
    }
    {
      mode = "n";
      key = "<leader>ge";
      action.__raw = ''
        function()
          vim.api.nvim_put({ 'if err != nil {', '    return', '}' }, 'l', true, true)
          vim.lsp.buf.format()
        end
      '';
      options.desc = "[G]o [E]rror handle pattern";
    }
  ];

  autoCmd = [
    {
      event = "TextYankPost";
      desc = "Highlight when yanking (copying) text";
      group = "kickstart-highlight-yank";
      callback.__raw = "function() vim.highlight.on_yank() end";
    }
  ];

  extraConfigLua = builtins.readFile ../lua/kovs/autocmds.lua;
}
