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
      vtsls = {
        tsserver = {
          globalPlugins = { {
            name = '@vue/typescript-plugin',
            location = vim.g.kovs_vue_ls_path,
            languages = { 'vue' },
            configNamespace = 'typescript',
          } }
        }
      },
    },
  })
  vim.lsp.enable 'vtsls'

  vim.lsp.config('tsc', {
    capabilities = capabilities,
    filetypes = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' },
    settings = { ['js/ts'] = { preferences = { autoImportFileExcludePatterns = drizzle } } },
    on_attach = function(client, bufnr)
      if detect.is_vue_project(detect.nearest_package_root(bufnr)) then
        client:stop(true)
        return
      end
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
    { 'clsx\\(([^)]*)\\)',       "(?:'|\"|`)([^']*)(?:'|\"|`)" },
    { 'classnames\\(([^)]*)\\)', "'([^']*)'" },
    { 'cva\\(([^)]*)\\)',        '["\'`]([^"\'`]*).*?["\'`]' },
    { 'cn\\(([^)]*)\\)',         "(?:'|\"|`)([^']*)(?:'|\"|`)" },
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
