{ pkgs, ... }:
{
  plugins = {

    # appearance
    dressing.enable = true;

    render-markdown = {
      enable = true;
      settings = {
        ft = [
          "markdown"
          "org"
        ];
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

    # formatting / lint
    conform-nvim = {
      enable = true;
      settings = {
        notify_on_error = false;
        notify_on_formatter = false;

        format_on_save = {
          timeout_ms = 200;
          lsp_fallback = true;
        };

        formatters_by_ft = {
          javascript = [
            "oxfmt"
            "oxlint"
          ];
          typescript = [
            "oxfmt"
            "oxlint"
          ];
          javascriptreact = [
            "oxfmt"
            "oxlint"
          ];
          typescriptreact = [
            "oxfmt"
            "oxlint"
          ];
          vue = [
            "oxfmt"
            "oxlint"
          ];
          svelte = [
            "oxfmt"
            "oxlint"
          ];
          astro = [
            "oxfmt"
            "oxlint"
          ];
          solidity = [ "solhint" ];
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

        formatters = {
          prettier = {
            args = [
              "--stdin-filepath"
              "$FILENAME"
            ];
            cwd.__raw = ''
              require('conform.util').root_file {
                '.prettierrc',
                'package.json',
                '.git',
              }
            '';
          };

          shfmt.prepend_args = [
            "-i"
            "4"
          ];
        };
      };
    };
    lint = {
      enable = true;
      autoCmd = {
        event = [
          "BufEnter"
          "BufWritePost"
          "InsertLeave"
        ];
        callback.__raw = ''
          function()
            if vim.opt_local.modifiable:get() then
              require('lint').try_lint()
            end
          end
        '';
      };
      lintersByFt = {
        java = [ "checkstyle" ];
        go = [ "golangcilint" ];
        typescript = [ "oxlint" ];
        typescriptreact = [ "oxlint" ];
        lua = [ "luacheck" ];
        python = [ "ruff" ];
        sql = [ "postgres-language-server" ];
      };
    };

    sleuth.enable = true;
    guess-indent.enable = true;

    # lsp helpers
    rustaceanvim.enable = true;
    fidget.enable = true;
    tiny-inline-diagnostic = {
      enable = true;
      settings = {
        preset = "simple";
        transparent_cursorline = false;
        options.multilines.enabled = true;
      };
    };

    harpoon = {
      enable = true;
      settings.settings = {
        save_on_toggle = true;
        sync_on_ui_close = true;
      };
    };

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

    which-key.enable = true;
    trouble.enable = true;
    flash.enable = true;
    toggleterm = {
      enable = true;
      settings.direction = "float";
    };

    # syntax
    treesitter = {
      enable = true;
      nixGrammars = true;
      languageRegister = {
        javascript = "tsx";
        "typescript.tsc" = "tsx";
      };
      settings = {
        highlight.enable = true;

        ensure_installed = [
          "lua"
          "markdown"
          "markdown_inline"
          "bash"
          "python"
          "go"
          "gomod"
          "gosum"
          "javascript"
          "typescript"
          "tsx"
          "vue"
          "svelte"
          "json"
          "json5"
          "yaml"
          "toml"
          "html"
          "css"
          "scss"
          "php"
          "rust"
          "solidity"
          "astro"
          "sql"
          "dockerfile"
          "git_config"
          "git_rebase"
          "gitcommit"
          "gitignore"
          "http"
          "nix"
          "proto"
        ];
      };
    };

    treesitter-textobjects = {
      enable = true;
      settings = {
        select = {
          lookahead = true;
          include_surrounding_whitespace = false;
        };
        move.set_jumps = true;
      };
    };
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
    web-devicons.enable = false;
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
    mini-surround = {
      enable = true;
      settings.custom_surroundings = {
        b = {
          input = [
            "%*%*.-%*%*"
            "^()%*%*()%a.-()%*%*()$"
          ];
          output = {
            left = "**";
            right = "**";
          };
        };
        e = {
          input = [
            "%*[^*]-%*"
            "^()%*()%a.-()%*()$"
          ];
          output = {
            left = "_";
            right = "_";
          };
        };
        c = {
          input = [
            "%`.-%`"
            "()%`()%a.-()%`()"
          ];
          output = {
            left = "`";
            right = "`";
          };
        };
      };
    };
    mini-pairs.enable = true;
    mini-indentscope.enable = true;
    mini-cursorword.enable = true;
    mini-statusline.enable = true;

    cord = {
      enable = true;

      # nixpkgs has 2.2.7, latest is >=2.3.39
      package = import ../cord.nix { inherit pkgs; };
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
            if vim.fn.getcwd():match 'vault' then return 'static/images/' else return 'assets' end
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
            path = "~/Documents/vault/";
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

    orgmode = {
      enable = true;
      settings = {
        org_agenda_files = "~/Documents/vault/org/**/*";
        org_default_notes_file = "~/Documents/vault/org/refile.org";
      };
    };

    wakatime.enable = true;

    # cmp
    luasnip = {
      enable = true;
      fromLua = [
        {
          paths = [ ../lua/snippets ];
        }
      ];
    };
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
          "<C-k>" = [
            "show_signature"
            "hide_signature"
            "fallback"
          ];
        };
        signature = {
          enabled = true;
          window.show_documentation = true;
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
      };
    };

  };

  globals.bullets_delete_last_bullet_if_empty = 2;

  extraPlugins =
    with pkgs.vimPlugins;
    [
      vim-tpipeline
      snacks-nvim
      orgmode
    ]
    ++ [
      (pkgs.vimUtils.buildVimPlugin {
        pname = "auto-gnome-theme";
        version = "2025-12-02";
        src = pkgs.fetchgit {
          url = "https://github.com/itsfernn/auto-gnome-theme.nvim";
          rev = "5be5489d52dd3aa2436e2fb04c1df7a869270f0e";
          hash = "sha256-4Dt8IHeMBE6nPCNjWJ/rOb9IeYDYPEGwRy4b0sP0Ec0=";
        };
      })
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
    {
      mode = "n";
      key = "<leader>f";
      action.__raw = ''
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end
      '';
      options.desc = "Format buffer";
    }
    {
      mode = "n";
      key = "<leader>lt";
      action.__raw = ''
        function()
          vim.diagnostic.enable(not vim.diagnostic.is_enabled())
        end
      '';
      options.desc = "Lint Toggle";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "s";
      action.__raw = "function() require('flash').jump() end";
      options.desc = "Flash";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "S";
      action.__raw = "function() require('flash').treesitter() end";
      options.desc = "Flash Treesitter";
    }
    {
      mode = "n";
      key = "<leader>?";
      action.__raw = "function() require('which-key').show { global = false } end";
      options.desc = "Buffer Local Keymaps (which-key)";
    }
    {
      mode = "n";
      key = "<leader>a";
      action.__raw = "function() require('harpoon'):list():add() end";
      options.desc = "Harpoon add file";
    }
    {
      mode = "n";
      key = "<leader>E";
      action.__raw = ''
        function()
          local harpoon = require 'harpoon'
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end
      '';
      options.desc = "Harpoon menu";
    }
    {
      mode = "n";
      key = "<leader>h";
      action.__raw = ''
        function()
          local n = vim.v.count
          if n > 0 then require('harpoon'):list():select(n) end
        end
      '';
      options.desc = "Harpoon select N";
    }
    {
      mode = "n";
      key = "gf";
      action.__raw = "function() return require('obsidian').util.gf_passthrough() end";
      options = {
        desc = "[G]oto markdown [F]ile";
        noremap = false;
        expr = true;
      };
    }
    {
      mode = "n";
      key = "]o";
      action.__raw = "function() require('obsidian.api').nav_link 'prev' end";
      options.desc = "Go to previous Obsidian link";
    }
    {
      mode = "n";
      key = "[o";
      action.__raw = "function() require('obsidian.api').nav_link 'next' end";
      options.desc = "Go to next Obsidian link";
    }
  ];

  extraConfigLua = builtins.readFile ../lua/kovs/plugins.lua;
}
