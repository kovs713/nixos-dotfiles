{ pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      # appearance
      dressing.enable = true;
      render-markdown = {
        enable = true;
        settings = {
          heading = {
            sign = false;
            icons = [
              "󰎤 "
              "󰎧 "
              "󰎪 "
              "󰎭 "
              "󰎱 "
              "󰎳 "
            ];
          };
          code = {
            sign = false;
            width = "block";
            right_pad = 1;
          };
          bullet.enabled = true;
          checkbox = {
            enabled = true;
            position = "inline";
            unchecked = {
              icon = "   󰄱 ";
              highlight = "RenderMarkdownUnchecked";
              scope_highlight = null;
            };
            checked = {
              icon = "   󰱒 ";
              highlight = "RenderMarkdownChecked";
              scope_highlight = null;
            };
          };
        };
      };
      highlight-colors = {
        enable = true;
        settings = {
          render = "virtual";
          exclude_filetypes = [
            "javascript"
            "typescript"
          ];
          enable_named_colors = false;
          enable_tailwind = true;
        };
      };

      # editing
      ts-context-commentstring = {
        enable = true;
        settings.enable_autocmd = false;
      };
      ts-autotag.enable = true;
      gitsigns = {
        enable = true;
        settings.on_attach.__raw = ''
          function(bufnr)
            local gitsigns = require 'gitsigns'
            vim.keymap.set('n', '[h', function()
              if vim.wo.diff then vim.cmd.normal { '[h', bang = true }
              else gitsigns.nav_hunk 'next' end
            end, { desc = 'Jump to next git change' })
            vim.keymap.set('n', ']h', function()
              if vim.wo.diff then vim.cmd.normal { ']h', bang = true }
              else gitsigns.nav_hunk 'prev' end
            end, { desc = 'Jump to previous git change' })
            vim.keymap.set('v', '<leader>gs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git stage hunk' })
            vim.keymap.set('v', '<leader>gr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git reset hunk' })
            vim.keymap.set('n', '<leader>gs', gitsigns.stage_hunk, { desc = 'git stage hunk' })
            vim.keymap.set('n', '<leader>gr', gitsigns.reset_hunk, { desc = 'git reset hunk' })
            vim.keymap.set('n', '<leader>gS', gitsigns.stage_buffer, { desc = 'git stage buffer' })
            vim.keymap.set('n', '<leader>gu', gitsigns.undo_stage_hunk, { desc = 'git undo stage hunk' })
            vim.keymap.set('n', '<leader>gR', gitsigns.reset_buffer, { desc = 'git reset buffer' })
            vim.keymap.set('n', '<leader>gp', gitsigns.preview_hunk, { desc = 'git preview hunk' })
            vim.keymap.set('n', '<leader>gb', gitsigns.blame_line, { desc = 'git blame line' })
            vim.keymap.set('n', '<leader>gd', gitsigns.diffthis, { desc = 'git diff against index' })
            vim.keymap.set('n', '<leader>gD', function() gitsigns.diffthis '@' end, { desc = 'git diff against last commit' })
            vim.keymap.set('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = 'Toggle git blame line' })
            vim.keymap.set('n', '<leader>tD', gitsigns.preview_hunk_inline, { desc = 'Toggle git show deleted' })
          end
        '';
      };
      comment = {
        enable = true;
        settings.pre_hook.__raw = "require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()";
      };
      bullets.enable = true;
      marks = {
        enable = true;
        settings = {
          default_mappings = true;
          builtin_marks = [
            "."
            "<"
            ">"
            "^"
          ];
          cyclic = true;
          force_write_shada = false;
          refresh_interval = 250;
          excluded_filetypes = { };
          excluded_buftypes = { };
          mappings = { };
        };
      };

      # formatting / lint (mason replaced by extraPackages in default.nix)
      conform-nvim = {
        enable = true;
        settings = {
          notify_on_error = false;
          formatters_by_ft = {
            javascript = [
              "prettier"
              "oxlint"
            ];
            typescript = [
              "prettier"
              "oxlint"
            ];
            javascriptreact = [
              "prettier"
              "oxlint"
            ];
            typescriptreact = [
              "prettier"
              "oxlint"
            ];
            vue = [
              "prettier"
              "oxlint"
            ];
            svelte = [
              "prettier"
              "oxlint"
            ];
            solidity = [ "solhint" ]; # ponytail: no nixpkgs package, install via npm i -g solhint
            astro = [
              "prettier"
              "oxlint"
            ];
            css = [ "prettier" ];
            html = [ "prettier" ];
            json = [ "prettier" ];
            yaml = [ "prettier" ];
            graphql = [ "prettier" ];
            lua = [ "stylua" ];
            python = [
              "ruff_fix"
              "ruff_format"
              "ruff_organize_imports"
            ];
            go = [ "gofumpt" ];
            rust = [ "rustfmt" ];
            bash = [ "shfmt" ];
            sql = [ "pg_format" ];
          };
        };
      };
      lint = {
        enable = true;
        lintersByFt = {
          java = [ "checkstyle" ];
          go = [ "golangcilint" ];
          typescript = [ "eslint_d" ];
          typescriptreact = [ "eslint_d" ];
          lua = [ "luacheck" ];
          python = [ "ruff" ];
          sql = [ "postgres-language-server" ];
        };
      };
      sleuth.enable = true;
      guess-indent.enable = true;

      # lsp helpers
      fidget.enable = true;
      otter = {
        enable = false;
        settings = {
          lsp.hover.border = [
            "╭"
            "─"
            "╮"
            "│"
            "╯"
            "─"
            "╰"
            "│"
          ]; # "rounded"
          buffers.set_filetype = true;
        };
      };
      tiny-inline-diagnostic = {
        enable = true;
        settings = {
          preset = "simple";
          transparent_cursorline = false;
          options.multilines.enabled = true;
        };
      };
      rustaceanvim.enable = true;

      # navigation (snacks via extraPlugins: module setup + manual setup conflict,
      # snacks errors "already setup" on second call)
      harpoon.enable = true;
      which-key.enable = true;
      trouble.enable = true;
      oil = {
        enable = true;
        settings = {
          win_options.signcolumn = "yes:2";
          default_file_explorer = true;
          watch_for_changes = true;
          buf_options = {
            buflisted = false;
            bufhidden = "hide";
          };
          view_options.show_hidden = true;
        };
      };
      oil-git-status = {
        enable = true;
        settings = {
          show_ignored = true;
          symbols = {
            index = {
              "!" = "!";
              "?" = "?";
              A = "A";
              C = "C";
              D = "D";
              M = "M";
              R = "R";
              T = "T";
              U = "U";
              " " = " ";
            };
            working_tree = {
              "!" = "!";
              "?" = "?";
              A = "A";
              C = "C";
              D = "D";
              M = "M";
              R = "R";
              T = "T";
              U = "U";
              " " = " ";
            };
          };
        };
      };
      flash.enable = true;
      toggleterm = {
        enable = true;
        settings.direction = "float";
      };

      # syntax
      treesitter = {
        enable = true;
        settings.highlight.enable = true;
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          lua
          markdown
          markdown-inline
          bash
          python
          go
          gomod
          gosum
          javascript
          typescript
          tsx
          vue
          svelte
          json
          json5
          yaml
          toml
          html
          css
          scss
          php
          rust
          solidity
          astro
          sql
          dockerfile
          git-config
          git-rebase
          gitcommit
          gitignore
          http
          # nix
        ];
      };

      treesitter-textobjects.enable = true;
      treesitter-context = {
        enable = true;
        settings = {
          enable = true;
          max_lines = 1;
        };
      };

      # utils
      mini-ai = {
        enable = true;
        settings.n_lines = 500;
      };
      mini-icons = {
        enable = true;
        settings.icons = {
          File = "󰈙";
          Folder = "󰉋";
          Module = "󰌗";
          Namespace = "󰌗";
          Package = "󰏖";
          Class = "󰌗";
          Method = "󰆧";
          Property = "󰜢";
          Field = "󰜢";
          Constructor = "󰆧";
          Enum = "󰕘";
          Interface = "󰕘";
          Function = "󰊕";
          Variable = "󰀫";
          Constant = "󰏿";
          String = "󰀬";
          Number = "󰎠";
          Boolean = "󰔨";
          Array = "󰅪";
          Object = "󰅩";
          Key = "󰌋";
          Null = "󰟢";
        };
      };
      mini-surround.enable = true;
      mini-pairs.enable = true;
      mini-indentscope.enable = true;
      mini-cursorword.enable = true;
      mini-statusline.enable = true;
      cord = {
        enable = true;
        # nixpkgs cord is 2.2.7 without the minecraft theme; track upstream tag
        package = pkgs.vimUtils.buildVimPlugin {
          pname = "cord.nvim";
          version = "v2.3.9";
          src = pkgs.fetchFromGitHub {
            owner = "vyfor";
            repo = "cord.nvim";
            rev = "v2.3.9";
            hash = "sha256-maRKcO1zR7J8wvPFTDx14DDTCLf6c6YTXW7BXu6NeAM=";
          };
          doCheck = false; # upstream require-check fails on cord.api.log.file
        };
      };
      img-clip = {
        enable = true;
        settings.default = {
          insert_mode_after_paste = true;
          url_encode_path = true;
          template = "$FILE_PATH";
          use_cursor_in_template = true;
          prompt_for_file_name = true;
          show_dir_path_in_prompt = true;
          use_absolute_path = false;
          relative_to_current_file = true;
          embed_image_as_base64 = false;
          max_base64_size = 10;
          dir_path.__raw = ''
            function()
              if vim.fn.getcwd():match 'obsidian-vault' then return 'static/images/' else return 'assets' end
            end
          '';
          drag_and_drop = {
            enabled = true;
            insert_mode = true;
            copy_images = true;
            download_images = true;
          };
        };
      };
      obsidian = {
        enable = true;
        settings = {
          legacy_commands = false;
          workspaces = [
            {
              name = "main";
              path = "~/obsidian-vault/";
            }
          ];
          ui.enable = false;
          daily_notes = {
            folder = "dailies";
            date_format = "daily note: %d.%m.%Y";
            default_tags = [ "daily-notes" ];
            template = null;
          };
          new_notes_location = "current_dir";
          completion = {
            blank = true;
            min_chars = 2;
          };
          picker = {
            name = "snacks.picker";
            note_mappings = {
              new = "<C-n>";
              insert_link = "<C-p>";
            };
          };
        };
      };
      wakatime.enable = true;

      # cmp
      luasnip.enable = true;
      friendly-snippets.enable = true;
      blink-cmp = {
        enable = true;
        settings = {
          keymap = {
            preset = "default";
            C-space = [ "show_and_insert" ];
            "<Tab>" = [
              "select_next"
              "fallback"
            ];
            "<S-Tab>" = [
              "select_prev"
              "fallback"
            ];
          };
          appearance = {
            nerd_font_variant = "mono";
            kind_icons = {
              Text = "󰉿";
              Method = "󰊕";
              Function = "󰊕";
              Constructor = "󰒓";
              Field = "󰜢";
              Variable = "󰆦";
              Property = "󰖷";
              Class = "󱡠";
              Interface = "󱡠";
              Struct = "󱡠";
              Module = "󰅩";
              Unit = "󰪚";
              Value = "󰦨";
              Enum = "󰦨";
              EnumMember = "󰦨";
              Keyword = "󰻾";
              Constant = "󰏿";
              Snippet = "󱄽";
              Color = "󰏘";
              File = "󰈔";
              Reference = "󰬲";
              Folder = "󰉋";
              Event = "󱐋";
              Operator = "󰪚";
              TypeParameter = "󰬛";
            };
          };
          completion = {
            menu = {
              auto_show = true;
              draw.components.kind_icon = {
                text.__raw = ''
                  function(ctx)
                    local icon = ctx.kind_icon
                    if ctx.item.source_name == 'LSP' then
                      local color_item = require('nvim-highlight-colors').format(ctx.item.documentation, { kind = ctx.kind })
                      if color_item and color_item.abbr ~= "" then icon = color_item.abbr end
                    end
                    return icon .. ctx.icon_gap
                  end
                '';
                highlight.__raw = ''
                  function(ctx)
                    local highlight = 'BlinkCmpKind' .. ctx.kind
                    if ctx.item.source_name == 'LSP' then
                      local color_item = require('nvim-highlight-colors').format(ctx.item.documentation, { kind = ctx.kind })
                      if color_item and color_item.abbr_hl_group then highlight = color_item.abbr_hl_group end
                    end
                    return highlight
                  end
                '';
              };
            };
            documentation = {
              auto_show = true;
              auto_show_delay_ms = 500;
            };
            ghost_text.enabled = true;
          };
          sources.default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
          snippets.preset = "luasnip";
          fuzzy.implementation = "lua";
          signature.enabled = true;
        };
      };
    };

    globals.bullets_delete_last_bullet_if_empty = 2;

    # No nixvim modules: vim-tpipeline + screenkey.nvim + blink.lib from pack.lua.
    extraPlugins = with pkgs.vimPlugins; [
      vim-tpipeline
      snacks-nvim
    ];

    keymaps = [
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<CR>";
        options.desc = "Diagnostics toggle";
      }
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Oil<CR>";
        options.desc = "Open Oil explorer";
      }
      {
        mode = "n";
        key = "<leader>pi";
        action = "<cmd>PasteImage<cr>";
        options.desc = "Paste image from system clipboard";
      }
      {
        mode = "n";
        key = "<leader>ts";
        action = "<CMD>Screenkey toggle<CR>";
        options.desc = "Toggle Screenkey";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<leader>tt";
        action = "<cmd>ToggleTerm<CR>";
        options.desc = "Toggle Terminal";
      }
      {
        mode = "n";
        key = "<leader>od";
        action = "<cmd>Obsidian dailies<cr>";
        options.desc = "[O]bsidian [D]ailies";
      }
      {
        mode = "n";
        key = "<leader>ony";
        action = "<cmd>Obsidian yesterday<cr>";
        options.desc = "[O]bsidian [N]ew [Y]esterday";
      }
      {
        mode = "n";
        key = "<leader>ont";
        action = "<cmd>Obsidian today<cr>";
        options.desc = "[O]bsidian [N]ew [T]oday";
      }
      {
        mode = "n";
        key = "<leader>onm";
        action = "<cmd>Obsidian tomorrow<cr>";
        options.desc = "[O]bsidian [N]ew to[M]orrow";
      }
      {
        mode = "n";
        key = "<leader>onn";
        action = "<cmd>Obsidian new<cr>";
        options.desc = "[O]bsidian [N]ew [N]ote";
      }
      {
        mode = "n";
        key = "<leader>os";
        action = "<cmd>Obsidian search<cr>";
        options.desc = "[O]bsidian [S]earch";
      }
    ];

    extraConfigLua = ''
      -- luasnip loaders (snippets.lua; from_lua path fixed: original pointed at
      -- ~/.config/nvim/lua/kovs/snippets which doesn't exist, so lua snippets never loaded)
      require('luasnip.loaders.from_vscode').lazy_load()
      require('luasnip.loaders.from_lua').lazy_load {
        paths = { vim.fn.stdpath 'config' .. '/lua/kovs/snippets' },
      }

      -- conform tweaks with function values
      do
        local conform = require 'conform'
        conform.setup {
          format_on_save = function(bufnr)
            if vim.tbl_contains({ 'php' }, vim.bo[bufnr].filetype) then return end
            return { timeout_ms = 500, lsp_format = 'fallback' }
          end,
        }
        conform.formatters.prettier = {
          args = { '--stdin-filepath', '$FILENAME' },
          cwd = require('conform.util').root_file { '.prettierrc', 'package.json', '.git' },
        }
        conform.formatters.shfmt = { prepend_args = { '-i', '4' } }
        vim.keymap.set('n', '<leader>f', function() conform.format { async = true, lsp_format = 'fallback' } end, { desc = 'Format buffer' })
      end

      -- nvim-lint: trigger + toggle
      do
        local lint = require 'lint'
        local g = vim.api.nvim_create_augroup('lint', { clear = true })
        vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
          group = g,
          callback = function() if vim.opt_local.modifiable:get() then lint.try_lint() end end,
        })
        vim.keymap.set('n', '<leader>lt', function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end, { desc = 'Lint Toggle' })
      end

      -- flash
      do
        local flash = require 'flash'
        vim.keymap.set({ 'n', 'x', 'o' }, 's', function() flash.jump() end, { desc = 'Flash' })
        vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() flash.treesitter() end, { desc = 'Flash Treesitter' })
      end

      -- which-key buffer-local popup
      vim.keymap.set('n', '<leader>?', function() require('which-key').show { global = false } end, { desc = 'Buffer Local Keymaps (which-key)' })

      -- harpoon2
      do
        local harpoon = require 'harpoon'
        harpoon:setup { settings = { save_on_toggle = true, sync_on_ui_close = true } }
        vim.keymap.set('n', '<leader>a', function() harpoon:list():add() end, { desc = 'Harpoon add file' })
        vim.keymap.set('n', '<leader>E', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon menu' })
        vim.keymap.set('n', '<leader>hh', function() harpoon:list():select(1) end, { desc = 'Harpoon select 1' })
        vim.keymap.set('n', '<leader>jj', function() harpoon:list():select(2) end, { desc = 'Harpoon select 2' })
        vim.keymap.set('n', '<leader>kk', function() harpoon:list():select(3) end, { desc = 'Harpoon select 3' })
        vim.keymap.set('n', '<leader>ll', function() harpoon:list():select(4) end, { desc = 'Harpoon select 4' })
        vim.keymap.set('n', '<leader>;', function() harpoon:list():select(5) end, { desc = 'Harpoon select 5' })
      end

      -- obsidian function keymaps (buffer = bufnr was nil in original = global)
      do
        local obsidian = require 'obsidian'
        vim.keymap.set('n', 'gf', function() return obsidian.util.gf_passthrough() end, { desc = '[G]oto markdown [F]ile', noremap = false, expr = true })
        vim.keymap.set('n', ']o', function() require('obsidian.api').nav_link 'prev' end, { desc = 'Go to previous Obsidian link' })
        vim.keymap.set('n', '[o', function() require('obsidian.api').nav_link 'next' end, { desc = 'Go to next Obsidian link' })
      end
    '';
  };
}
