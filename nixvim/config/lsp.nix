{ pkgs, ... }:
let
  drizzleExclude = [
    "drizzle-orm/gel-core"
    "drizzle-orm/mysql-core"
    "drizzle-orm/sqlite-core"
    "drizzle-orm/singlestore-core"
    "drizzle-orm/cockroach-core"
  ];
  inlayHints = {
    includeInlayParameterNameHints = "all";
    includeInlayParameterNameHintsWhenArgumentMatchesName = true;
    includeInlayFunctionParameterTypeHints = true;
    includeInlayVariableTypeHints = true;
    includeInlayPropertyDeclarationTypeHints = true;
    includeInlayFunctionLikeReturnTypeHints = true;
  };
in
{
  programs.nixvim = {

    plugins.lsp = {
      enable = true;
      inlayHints = true;
      servers = {

        gopls = {
          enable = true;
          settings.gopls = {
            codelenses = {
              test = true;
              gc_details = true;
              generate = true;
              run_govulncheck = true;
              tidy = true;
              upgrade_dependency = true;
              vendor = true;
            };
            gofumpt = true;
            completeUnimported = true;
            usePlaceholders = false;
            staticcheck = true;
            hints = {
              assignVariableTypes = true;
              compositeLiteralFields = true;
              compositeLiteralTypes = true;
              constantValues = true;
              functionTypeParameters = true;
              parameterNames = true;
              rangeVariableTypes = true;
            };
            analyses = {
              recursiveiter = true;
              maprange = true;
              framepointer = true;
              modernize = true;
              nilness = true;
              hostport = true;
              gofix = true;
              sigchanyzer = true;
              stdversion = true;
              unreachable = true;
              unusedfunc = true;
              unusedparams = true;
              unusedvariable = true;
              unusedwrite = true;
              useany = true;
            };
          };
        };

        lua_ls = {
          enable = true;
          settings.Lua = {
            diagnostics.globals = [ "vim" ];
            completion.callSnippet = "Replace";
          };
        };

        html.enable = true;

        cssls = {
          enable = true;
          settings = {
            css.lint.unknownAtRules = "ignore";
            scss.lint.unknownAtRules = "ignore";
          };
          extraOptions.on_attach.__raw = ''
            function(client)
              client.server_capabilities.documentFormattingProvider = true
              client.server_capabilities.documentRangeFormattingProvider = true
            end
          '';
        };

        jsonls = {
          enable = true;
          settings.json.schemas = [
            {
              fileMatch = [ "package.json" ];
              url = "https://json.schemastore.org/package.json";
            }
            {
              fileMatch = [ "tsconfig*.json" ];
              url = "https://json.schemastore.org/tsconfig.json";
            }
            {
              fileMatch = [
                ".prettierrc"
                ".prettierrc.json"
                "prettier.config.json"
              ];
              url = "https://json.schemastore.org/prettierrc.json";
            }
            {
              fileMatch = [
                ".eslintrc"
                ".eslintrc.json"
              ];
              url = "https://json.schemastore.org/eslintrc.json";
            }
            {
              fileMatch = [
                ".babelrc"
                ".babelrc.json"
                "babel.config.json"
              ];
              url = "https://json.schemastore.org/babelrc.json";
            }
            {
              fileMatch = [ "lerna.json" ];
              url = "https://json.schemastore.org/lerna.json";
            }
            {
              fileMatch = [
                "now.json"
                "vercel.json"
              ];
              url = "https://json.schemastore.org/now.json";
            }
            {
              fileMatch = [ "ecosystem.json" ];
              url = "https://json.schemastore.org/pm2-ecosystem.json";
            }
          ];
        };

        pyright = {
          enable = true;
          settings = {
            pyright.disableOrganizeImports = true;
            python.analysis.ignore = [ "*" ];
          };
        };
        ruff = {
          enable = true;
          settings.init_options.settings.python.analysis = {
            typeCheckingMode = "basic";
            diagnosticMode = "openFilesOnly";
          };
        };

        astro = {
          enable = true;
          filetypes = [ "astro" ];
          settings = {
            astro = {
              diagnostic = {
                ignoreRefs = false;
                allowInvalidPeers = true;
              };
              completions = {
                autoImport = true;
                guide = true;
                icons = true;
              };
            };
            typescript.inlayHints = inlayHints;
          };
        };

        svelte = {
          enable = true;
          filetypes = [ "svelte" ];
          settings = {
            astro = {
              diagnostic = {
                ignoreRefs = false;
                allowInvalidPeers = true;
              };
              completions = {
                autoImport = true;
                guide = true;
                icons = true;
              };
            };
            typescript.inlayHints = inlayHints;
          };
        };

        emmet_ls = {
          enable = true;
          filetypes = [
            "css"
            "eruby"
            "html"
            "javascript"
            "javascriptreact"
            "less"
            "sass"
            "scss"
            "pug"
            "typescriptreact"
            "vue"
          ];
          settings.init_options = {
            includeLanguages = { };
            excludeLanguages = { };
            extensionsPath = { };
            preferences = { };
            showAbbreviationSuggestions = true;
            showExpandedAbbreviation = "always";
            showSuggestionsAsSnippets = false;
            syntaxProfiles = { };
            variables = { };
          };
        };

        tailwindcss = {
          enable = true;
          filetypes = [
            "html"
            "mdx"
            "javascript"
            "typescript"
            "javascriptreact"
            "typescriptreact"
            "vue"
            "svelte"
            "css"
            "scss"
            "less"
          ];
          settings.tailwindCSS = {
            lint = {
              cssConflict = "warning";
              invalidApply = "error";
              invalidConfigPath = "error";
              invalidScreen = "error";
              invalidTailwindDirective = "error";
              invalidVariant = "error";
              recommendedVariantOrder = "warning";
            };
            experimental.classRegex = [
              "tw`([^`]*)"
              "tw=\"([^\"]*)"
              "tw={([^\"]*)}"
              "tw\\.\\w+`([^`]*)"
              "tw\\(.*?\\)`([^`]*)"
            ];
            validate = true;
          };
          # classRegex function entries (clsx/cva/...) need lua; appended in extraConfigLua below.
        };

        biome = {
          enable = true;
          filetypes = [
            "astro"
            "css"
            "graphql"
            "html"
            "javascript"
            "javascriptreact"
            "json"
            "jsonc"
            "svelte"
            "typescript"
            "typescriptreact"
            "vue"
          ];
          extraOptions.workspace_required = true;
        };

        solidity_ls = {
          enable = true;
          package = pkgs.vscode-solidity-server;
        };

        nil_ls = {
          enable = true;
          settings.nil = {
            nix.flake.autoEval = true;
            diagnostics.statice.enabled = true;
            formatting.command = [ "nixfmt" ];
          };

          filetypes = [ "nix" ];
        };
      };
    };

    extraConfigLua = ''
      do
        local capabilities = require('blink.cmp').get_lsp_capabilities()
        local detect = require 'kovs.utils.detect'
        local drizzle = {
          'drizzle-orm/gel-core', 'drizzle-orm/mysql-core', 'drizzle-orm/sqlite-core',
          'drizzle-orm/singlestore-core', 'drizzle-orm/cockroach-core',
        }
        vim.lsp.config('vtsls', {
          capabilities = capabilities,
          filetypes = { 'vue', 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' },
          root_dir = function(bufnr, on_dir)
            local root = detect.nearest_package_root(bufnr)
            if not detect.is_vue_project(root) then return end
            on_dir(root)
          end,
          on_attach = function(client)
            client.server_capabilities.documentFormattingProvider = false
            vim.keymap.set('n', '<leader>i', function()
              vim.lsp.buf.code_action { context = { only = { 'source.organizeImports' } }, apply = true }
            end, { silent = true, desc = 'Organize Imports' })
          end,
          settings = {
            typescript = { preferences = { autoImportFileExcludePatterns = drizzle } },
            javascript = { preferences = { autoImportFileExcludePatterns = drizzle } },
            vtsls = { tsserver = { globalPlugins = { {
              name = '@vue/typescript-plugin',
              location = '${pkgs.vue-language-server}/lib/language-tools/packages/language-server',
              languages = { 'vue' },
              configNamespace = 'typescript',
            } } } },
          },
        })
        vim.lsp.enable 'vtsls'

        vim.lsp.config('tsc', {
          capabilities = capabilities,
          filetypes = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' },
          settings = { ['js/ts'] = { preferences = { autoImportFileExcludePatterns = drizzle } } },
          on_attach = function(client, bufnr)
            if detect.is_vue_project(detect.nearest_package_root(bufnr)) then client:stop(true) return end
            client.server_capabilities.documentFormattingProvider = false
            vim.keymap.set('n', '<leader>i', function()
              vim.lsp.buf.code_action { context = { only = { 'source.organizeImports' } }, apply = true }
            end, { buffer = bufnr, silent = true, desc = 'Organize Imports' })
          end,
        })
        vim.lsp.enable 'tsc'

        local tw = vim.lsp.config.tailwindcss or {}
        tw.settings = tw.settings or {}
        tw.settings.tailwindCSS = tw.settings.tailwindCSS or {}
        tw.settings.tailwindCSS.experimental = tw.settings.tailwindCSS.experimental or {}
        local cr = tw.settings.tailwindCSS.experimental.classRegex or {}
        vim.list_extend(cr, {
          { 'clsx\\(([^)]*)\\)', "(?:'|\"|`)([^']*)(?:'|\"|`)" },
          { 'classnames\\(([^)]*)\\)', "'([^']*)'" },
          { 'cva\\(([^)]*)\\)', '["\'`]([^"\'`]*).*?["\'`]' },
          { 'cn\\(([^)]*)\\)', "(?:'|\"|`)([^']*)(?:'|\"|`)" },
        })
        tw.settings.tailwindCSS.experimental.classRegex = cr
        -- snippetSupport=false + no color/folding (verbatim from lspconfigs.lua)
        local tw_caps = require('blink.cmp').get_lsp_capabilities()
        tw_caps.textDocument.completion.completionItem.snippetSupport = false
        tw_caps.textDocument.colorProvider = { dynamicRegistration = false }
        tw_caps.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
        tw.capabilities = tw_caps
        vim.lsp.config('tailwindcss', tw)
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client == nil or client.name ~= 'ruff' then return end
          vim.keymap.set('n', '<leader>i', function()
            vim.lsp.buf.code_action { context = { only = { 'source.organizeImports' } }, apply = true }
          end, { silent = true, desc = 'Organize Imports' })
          client.server_capabilities.hoverProvider = false
        end,
        desc = 'LSP: Disable hover capability from Ruff',
      })

      -- vim.api.nvim_create_autocmd('FileType', {
      --   pattern = { 'typescript', 'typescriptreact' },
      --   callback = function() require('otter').activate { 'sql', 'graphql', 'html', 'css' } end,
      -- })

      do
        local capabilities = require('blink.cmp').get_lsp_capabilities()
        vim.lsp.config('postgres-language-server', { capabilities = capabilities, filetypes = { 'sql' } })
        vim.lsp.enable 'postgres-language-server'
        vim.lsp.config('ellsp', {
          cmd = { 'ellsp' },
          filetypes = { 'lisp', 'elisp', 'scheme' },
          root_markers = { '.git', 'Cask', 'Eask' },
        })
        if vim.fn.executable 'ellsp' == 1 then vim.lsp.enable 'ellsp' end
      end
    '';
  };
}
