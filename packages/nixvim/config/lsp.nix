{ pkgs, ... }:
let
  inlayHints = {
    includeInlayParameterNameHints = "all";
    includeInlayParameterNameHintsWhenArgumentMatchesName = true;
    includeInlayFunctionParameterTypeHints = true;
    includeInlayVariableTypeHints = true;
    includeInlayPropertyDeclarationTypeHints = true;
    includeInlayFunctionLikeReturnTypeHints = true;
  };

  k8sSchemaUrl = "https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/swagger.json";
in
{
  plugins.lsp = {
    enable = true;
    inlayHints = false;
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

      qmlls.enable = true;

      cssls = {
        enable = true;
        settings = {
          css.lint.unknownAtRules = "ignore";
          scss.lint.unknownAtRules = "ignore";
        };
        onAttach.function = ''
          client.server_capabilities.documentFormattingProvider = true
          client.server_capabilities.documentRangeFormattingProvider = true
        '';
      };

      jsonls.enable = true;

      pyright = {
        enable = true;
        settings = {
          pyright.disableOrganizeImports = true;
          python.analysis.ignore = [ "*" ];
        };
      };
      ruff = {
        enable = true;
        onAttach.function = ''
          client.server_capabilities.hoverProvider = false
          vim.keymap.set('n', '<leader>i', function()
            vim.lsp.buf.code_action {
              context = { only = { 'source.organizeImports' } },
              apply = true,
            }
          end, { buffer = bufnr, silent = true, desc = 'Organize Imports' })
        '';
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
        settings.svelte = {
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
        settings.typescript.inlayHints = inlayHints;
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
          showAbbreviationSuggestions = true;
          showExpandedAbbreviation = "always";
          showSuggestionsAsSnippets = false;
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

      protols = {
        enable = true;
        filetypes = [ "proto" ];
        package = pkgs.protols;
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

      yamlls = {
        enable = true;
        filetypes = [ "yaml" ];
        settings = {
          yaml = {
            format.enable = true;
            schemas = {
              "${k8sSchemaUrl}" = [
                "*.yaml"
                "*.yml"
              ];
            };
            customTags = [
              "!include"
              "!ref"
              "!anchor"
            ];
          };
        };
      };

      helm_ls = {
        enable = true;
        rootMarkers = [ "Chart.yaml" ];
        settings = {
          helm-ls = {
            lintOnSave = true;
            diagnostics.enabled = true;
          };
        };
      };
    };
  };

  extraConfigLua = ''
    vim.g.kovs_vue_ls_path = "${pkgs.vue-language-server}/lib/language-tools/packages/language-server";
  ''
  + builtins.readFile ../lua/kovs/lsp.lua;
}
