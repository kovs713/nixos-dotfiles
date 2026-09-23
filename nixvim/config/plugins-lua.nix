{
  programs.nixvim = {

    extraConfigLua = ''
      -- snacks.nvim (after/plugin/snacks.lua verbatim)
      do
        local snacks = require 'snacks'
        snacks.setup {
          scroll = { enabled = false },
          lazygit = { theme = {
            selectedLineBgColor = { bg = 'SnacksLazygitSelected' },
            defaultFgColor = { fg = 'Normal' },
            activeBorderColor = { fg = 'MatchParen', bold = true },
            searchingActiveBorderColor = { fg = 'MatchParen', bold = true },
          } },
          picker = {
            enabled = true, ui_select = true, hidden = true, ignored = true,
            matcher = { fuzzy = true, smartcase = true, ignorecase = true, frecency = true, cwd_bonus = true },
            layout = { preview = 'main', layout = {
              backdrop = false, width = 40, min_width = 40, height = 0,
              position = 'left', border = 'none', box = 'vertical',
              { win = 'input', height = 1, border = 'single', title = '{title} {live} {flags}', title_pos = 'center' },
              { win = 'list', border = 'none' },
              { win = 'preview', title = '{preview}', height = 0.4, border = 'top' },
            } },
            exclude = { '/node_modules/*', '/dist/*', '/.git/*', '/.DS_Store/*', '/coverage/*' },
          },
          image = {
            enabled = true,
            formats = { 'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'tiff', 'heic', 'avif', 'mp4', 'mov', 'avi', 'mkv', 'webm', 'pdf' },
            force = false,
            doc = { enabled = true, inline = false, float = true, max_width = 50, max_height = 25, conceal = false },
            img_dirs = { 'img', 'images', 'assets', 'static', 'public', 'media', 'attachments' },
            wo = { wrap = false, number = false, relativenumber = false, cursorcolumn = false, signcolumn = 'no', foldcolumn = '0', list = false, spell = false, statuscolumn = "" },
            cache = vim.fn.stdpath 'cache' .. '/snacks/image',
            debug = { request = false, convert = false, placement = false },
            env = {},
            convert = {
              notify = true,
              mermaid = function()
                local theme = vim.o.background == 'light' and 'neutral' or 'dark'
                return { '-i', '{src}', '-o', '{file}', '-b', 'transparent', '-t', theme, '-s', '{scale}' }
              end,
              magick = {
                default = { '{src}[0]', '-scale', '1920x1080>' },
                vector = { '-density', 192, '{src}[0]' },
                math = { '-density', 192, '{src}[0]', '-trim' },
                pdf = { '-density', 192, '{src}[0]', '-background', 'white', '-alpha', 'remove', '-trim' },
              },
            },
            math = { enabled = true },
          },
        }
        vim.keymap.set('n', '<leader>gl', function() Snacks.lazygit() end, { desc = '[G]it [L]azygit' })
        vim.keymap.set('n', '<leader>rN', function() Snacks.rename.rename_file() end, { desc = '[R]e[N]ame File' })
        vim.keymap.set('n', '<leader>fp', function() Snacks.picker.projects() end, { desc = '[F]ind [P]rojects' })
        vim.keymap.set('n', '<leader>ff', function() Snacks.picker.files() end, { desc = '[F]ind [F]iles' })
        vim.keymap.set('n', '<leader>fd', function() Snacks.picker.grep() end, { desc = '[F]ind by Grep [D]?' })
        vim.keymap.set('n', '<leader>fr', function() Snacks.picker.recent() end, { desc = '[F]ind [R]ecent' })
        vim.keymap.set('n', '<leader>fc', function() Snacks.picker.git_log() end, { desc = '[F]ind Git [C]ommits' })
        vim.keymap.set('n', '<leader>fb', function() Snacks.picker.git_branches() end, { desc = '[F]ind Git [B]ranches' })
        vim.keymap.set('n', '<leader>fs', function() Snacks.picker.git_status() end, { desc = '[F]ind Git [S]tatus' })
        vim.keymap.set('n', '<leader>ft', function() Snacks.picker.git_stash() end, { desc = '[F]ind Git S[T]ash' })
        vim.keymap.set('n', '<leader>fo', function()
          local cwd = vim.fn.getcwd()
          local dirs = {}
          local handle = io.popen(
            'find ' .. cwd .. ' -type d ! -path "*/node_modules/*" ! -path "*/.git/*"'
              .. ' ! -path "*/dist/*" ! -path "*/build/*" ! -path "*/.next/*"'
              .. ' ! -path "*/vendor/*" ! -name "node_modules" ! -name ".git"'
              .. ' ! -name "dist" ! -name "build" ! -name ".next" ! -name "vendor" 2>/dev/null'
          )
          for line in handle:lines() do
            if line ~= cwd and line ~= ''' then
              table.insert(dirs, { text = vim.fn.fnamemodify(line, ':.'), file = line })
            end
          end
          handle:close()
          Snacks.picker {
            prompt = 'Directories> ',
            items = dirs,
            format = function(item) return { { item.text, 'SnacksPickerIcon' } } end,
            preview = false,
            keys = { { '<cr>', function(picker)
              local item = picker:selected()[1]
              if item and item.file then require('oil').open(item.file) end
            end, desc = 'Open in oil', mode = 'n' } },
          }
        end, { desc = '[F]ind Directories [O]il' })
      end

      -- treesitter textobjects wiring (after/plugin/treesitter.lua minus install{})
      do
        local ts_select = require 'nvim-treesitter-textobjects.select'
        local ts_moves = require 'nvim-treesitter-textobjects.move'
        require('nvim-treesitter-textobjects').setup {
          select = { lookahead = true, include_surrounding_whitespace = false },
          move = { set_jumps = true },
        }
        vim.treesitter.language.register('javascript', 'tsx')
        vim.treesitter.language.register('typescript.tsc', 'tsx')
        local function setup_selects()
          local buf_opts = { buffer = true }
          vim.keymap.set({ 'o', 'x' }, 'aa', function() ts_select.select_textobject('@parameter.outer', 'textobjects') end, buf_opts)
          vim.keymap.set({ 'o', 'x' }, 'ia', function() ts_select.select_textobject('@parameter.inner', 'textobjects') end, buf_opts)
          vim.keymap.set({ 'o', 'x' }, 'af', function() ts_select.select_textobject('@function.outer', 'textobjects') end, buf_opts)
          vim.keymap.set({ 'o', 'x' }, 'if', function() ts_select.select_textobject('@function.inner', 'textobjects') end, buf_opts)
          vim.keymap.set({ 'o', 'x' }, 'ac', function() ts_select.select_textobject('@class.outer', 'textobjects') end, buf_opts)
          vim.keymap.set({ 'o', 'x' }, 'ic', function() ts_select.select_textobject('@class.inner', 'textobjects') end, buf_opts)
        end
        local function setup_moves()
          local buf_opts = { buffer = true }
          vim.keymap.set({ 'n', 'o', 'x' }, ']f', function() ts_moves.goto_previous_start('@function.outer', 'textobjects') end, buf_opts)
          vim.keymap.set({ 'n', 'o', 'x' }, '[f', function() ts_moves.goto_next_start('@function.outer', 'textobjects') end, buf_opts)
        end
        local ts_group = vim.api.nvim_create_augroup('kovs-treesitter', {})
        vim.api.nvim_create_autocmd('FileType', {
          pattern = { 'lua', 'python', 'go', 'javascript', 'typescript', 'typescriptreact', 'vim' },
          callback = function()
            vim.treesitter.start()
            setup_selects()
            setup_moves()
            vim.opt_local.foldmethod = 'expr'
            vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.opt_local.foldlevel = 99
          end,
          group = ts_group,
        })
        vim.keymap.set('n', '[c', function() require('treesitter-context').go_to_context(vim.v.count1) end, { silent = true })
      end

      -- mini.statusline custom content (after/plugin/mini-statusline.lua verbatim)
      do
        local statusline = require 'mini.statusline'
        vim.api.nvim_create_autocmd('FileType', {
          pattern = 'neo-tree',
          callback = function() vim.b.ministatusline_disable = true end,
        })
        local function get_relative_path()
          local filepath = vim.fn.expand '%:p'
          if filepath == ''' or vim.fn.filereadable(filepath) == 0 then return '[No Name]' end
          local cwd = vim.fn.getcwd()
          if cwd:sub(-1) ~= '/' then cwd = cwd .. '/' end
          if filepath:sub(1, #cwd) == cwd then return filepath:sub(#cwd + 1) end
          return vim.fn.fnamemodify(filepath, ':~:.')
        end
        statusline.setup {
          content = {
            active = function()
              local mode, mode_hl = MiniStatusline.section_mode { trunc_width = 100 }
              local path = get_relative_path()
              local git = MiniStatusline.section_git { trunc_width = 40 }
              return MiniStatusline.combine_groups {
                { hl = mode_hl, strings = { mode } },
                { hl = 'MiniStatuslineFilename', strings = { path } },
                { hl = 'MiniStatuslineDevinfo', strings = { git } },
              }
            end,
            inactive = function()
              return MiniStatusline.combine_groups {
                { hl = 'MiniStatuslineFilename', strings = { get_relative_path() } },
              }
            end,
          },
          use_icons = true,
        }
      end

      -- cord.nvim (after/plugin/cord.lua verbatim)
      do
        local cord = require 'cord'
        local cord_api_icon = require 'cord.api.icon'
        local data_path = vim.fn.stdpath 'data' .. '/cord/plugins/daily_timer/data.json'
        local state = { day = os.date '%F', ws = nil, start = nil, active = true, data = {} }
        local function read_json(path)
          if vim.fn.filereadable(path) == 0 then return nil end
          local ok, decoded = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(path), '\n'))
          return ok and decoded or nil
        end
        local function save_json(path, tbl)
          vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
          local ok, encoded = pcall(vim.fn.json_encode, tbl)
          if ok then vim.fn.writefile({ encoded }, path) end
        end
        state.data = read_json(data_path) or {}
        local function flush(now)
          if not (state.ws and state.active and state.start) then return end
          local day = os.date('%F', now)
          state.data[day] = state.data[day] or {}
          state.data[day][state.ws] = (state.data[day][state.ws] or 0) + (now - state.start)
          state.start = now
        end
        local function roll_day(now)
          local today = os.date('%F', now)
          if state.day ~= today then flush(now) state.day = today state.start = now end
        end
        vim.filetype.add {
          pattern = {
            ['.*/.*%.module%.ts'] = 'typescript',
            ['.*/.*%.controller%.ts'] = 'typescript',
            ['.*/.*%.service%.ts'] = 'typescript',
          },
        }
        cord.setup {
          enabled = true,
          log_level = vim.log.levels.OFF,
          editor = { client = 'neovim', tooltip = 'череп эмодзи 💀' },
          display = { theme = 'minecraft', flavor = 'accent', view = 'full', swap_fields = false, swap_icons = false },
          timestamp = { enabled = true, reset_on_idle = false, reset_on_change = false, shared = false },
          idle = { enabled = true, timeout = 5 * 60 * 1000, show_status = true, ignore_focus = true, unidle_on_focus = true, smart_idle = true, tooltip = '💤' },
          text = { workspace = ''', viewing = 'viewing', editing = 'editing', dashboard = 'home' },
          assets = vim.tbl_extend('force', (assets or {}), {
            ['.ts'] = { icon = cord_api_icon.get 'typescript', tooltip = 'TypeScript', type = 'language' },
            ['.tsx'] = { icon = cord_api_icon.get 'typescript', tooltip = 'TypeScript React', type = 'language' },
          }),
          variables = true,
          advanced = {
            plugin = { autocmds = true, cursor_update = 'on_hold', match_in_mappings = true },
            server = { update = 'fetch', timeout = 300000 },
            discord = { reconnect = { enabled = true, interval = 5000, initial = true } },
            workspace = { limit_to_cwd = false },
          },
          hooks = vim.tbl_extend('force', (hooks or {}), {
            post_activity = function(opts, activity)
              local v = vim.version()
              activity.assets.small_text = string.format('Neovim %d.%d.%d', v.major, v.minor, v.patch)
              local f = opts.filename or '''
              if f:match '%.module%.ts$' or f:match '%.controller%.ts$' or f:match '%.service%.ts$'
                or f:match '%.guard%.ts$' or f:match '%.interceptor%.ts$' or f:match '%.gateway%.ts$'
                or f:match '%.filter%.ts$' or f:match '%.resolver%.ts$' then
                activity.assets.large_image = require('cord.api.icon').get 'typescript'
                activity.assets.large_text = 'NestJS'
              end
            end,
            pre_activity = function(opts)
              local now = os.time()
              roll_day(now)
              state.ws = state.ws or (opts.workspace or 'global')
              state.start = state.start or now
              state.active = not opts.is_idle
              local acc = ((state.data[state.day] or {})[state.ws] or 0)
              if state.active and state.start then acc = acc + (now - state.start) end
              opts.timestamp = (now - acc) * 1000
            end,
            workspace_change = function(opts)
              local now = os.time()
              roll_day(now) flush(now)
              state.ws = opts.workspace or 'global'
              state.start = now
              state.active = not opts.is_idle
              save_json(data_path, state.data)
            end,
            idle_enter = function(_)
              local now = os.time()
              roll_day(now) flush(now)
              state.active = false
              save_json(data_path, state.data)
            end,
            idle_leave = function(_)
              state.start = os.time()
              state.active = true
            end,
            shutdown = function()
              local now = os.time()
              roll_day(now) flush(now)
              save_json(data_path, state.data)
            end,
          }),
        }
      end
    '';
  };
}
