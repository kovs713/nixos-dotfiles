vim.api.nvim_create_augroup('UserLspConfig', { clear = true })
vim.api.nvim_create_autocmd('LspAttach', {
  group = 'UserLspConfig',
  callback = function(event)
    local opts = { buffer = event.buf, silent = true }
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf, group = highlight_augroup, callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf, group = highlight_augroup, callback = vim.lsp.buf.clear_references,
      })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      opts.desc = '[T]oggle Inlay [H]ints'
      opts.buffer = event.buf
      vim.keymap.set('n', '<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, opts)
    end
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  desc = 'Attach keymaps for quickfix list',
  callback = function()
    vim.keymap.set('n', 'dd', function()
      local qf_list = vim.fn.getqflist()
      local lnum = vim.fn.line '.'
      table.remove(qf_list, lnum)
      vim.fn.setqflist(qf_list, 'r')
      vim.fn.cursor(lnum, 1)
    end, { buffer = true, silent = true, desc = 'Remove quickfix item under cursor' })
    vim.keymap.set('v', 'd', function()
      local qf_list = vim.fn.getqflist()
      local first_line, last_line = vim.fn.line 'v', vim.fn.line '.'
      if first_line > last_line then first_line, last_line = last_line, first_line end
      for i = last_line, first_line, -1 do
        if qf_list[i] then table.remove(qf_list, i) end
      end
      vim.fn.setqflist(qf_list, 'r')
      vim.api.nvim_input '<Esc>'
      vim.fn.cursor(first_line, 1)
    end, { buffer = true, silent = true, desc = 'Remove selected quickfix items' })
  end,
})
