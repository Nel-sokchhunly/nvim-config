--------------------------------------------------------------------------------
-- GENERAL SETTINGS
--------------------------------------------------------------------------------

vim.cmd 'language en_US'

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = false -- set true if you have a Nerd Font installed/selected in terminal

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = true
vim.opt.mouse = 'a'
vim.opt.showmode = false -- statusline already shows mode
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '| ', trail = '·', nbsp = '+' }
vim.opt.inccommand = 'split' -- live preview of substitutions
vim.opt.cursorline = true
vim.opt.scrolloff = 10

-- Sync OS clipboard (deferred for startup time)
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

--------------------------------------------------------------------------------
-- KEYMAPS
--------------------------------------------------------------------------------

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window/split navigation with CTRL+hjkl.
-- NOTE: these intentionally take priority over tmux-navigator style bindings
-- below since Lua re-assigns the same keys; if you use tmux panes and want
-- seamless pane<->split navigation instead, delete this block and keep only
-- the TmuxNavigate* mappings.
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

--------------------------------------------------------------------------------
-- AUTOCOMMANDS
--------------------------------------------------------------------------------

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Auto-enter terminal insert mode on open, so keys (like `q` in lazygit,
-- fzf, etc.) go straight to the running program instead of being caught by
-- Neovim's terminal-normal mode.
vim.api.nvim_create_autocmd('TermOpen', {
  desc = 'Enter insert mode when opening a terminal',
  group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.cmd.startinsert()
  end,
})

-- TermOpen only fires once, the first time a terminal buffer is created.
-- Plugins like lazygit.nvim reuse the same terminal buffer on subsequent
-- opens, which would otherwise leave you back in terminal-normal mode
-- (where `q` gets caught by Neovim instead of reaching the program). This
-- re-asserts insert mode every time you enter/re-enter any terminal window.
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
  desc = 'Always re-enter insert mode when entering a terminal window',
  group = vim.api.nvim_create_augroup('custom-term-reenter-insert', { clear = true }),
  pattern = 'term://*',
  callback = function()
    vim.cmd.startinsert()
  end,
})

-- Close netrw (Vim's built-in file explorer) with <Esc> instead of `q`.
-- Netrw is a plain buffer, not a terminal, so `q` there is interpreted by
-- Vim as "start recording a macro" rather than "quit" -- this avoids that.
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Close netrw with <Esc>',
  group = vim.api.nvim_create_augroup('custom-netrw-esc', { clear = true }),
  pattern = 'netrw',
  callback = function(event)
    vim.keymap.set('n', '<Esc>', '<cmd>bd<CR>', { buffer = event.buf, silent = true, desc = 'Close netrw' })
  end,
})

-- Auto-close the terminal window/buffer once the process inside it exits
-- cleanly (exit code 0). Closes the window(s) showing the buffer FIRST,
-- then deletes the buffer — otherwise floating panels (like LazyGit) are
-- left as an empty "ghost" window since deleting a buffer alone doesn't
-- close the window displaying it.
vim.api.nvim_create_autocmd('TermClose', {
  desc = 'Auto-close terminal buffer on clean process exit',
  group = vim.api.nvim_create_augroup('custom-term-close', { clear = true }),
  callback = function(event)
    if vim.v.event.status == 0 and vim.api.nvim_buf_is_valid(event.buf) then
      for _, win in ipairs(vim.fn.win_findbuf(event.buf)) do
        if vim.api.nvim_win_is_valid(win) then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
      vim.api.nvim_buf_delete(event.buf, { force = true })
    end
  end,
})

--------------------------------------------------------------------------------
-- PLUGIN MANAGER BOOTSTRAP (lazy.nvim)
--------------------------------------------------------------------------------

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------------------------------------
-- PLUGINS
--------------------------------------------------------------------------------

require('lazy').setup({

  'tpope/vim-sleuth', -- Detect tabstop/shiftwidth automatically

  { -- Git signs in the gutter
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  { -- Pending keybind popup
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ', Down = '<Down> ', Left = '<Left> ', Right = '<Right> ',
          C = '<C-…> ', M = '<M-…> ', D = '<D-…> ', S = '<S-…> ',
          CR = '<CR> ', Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ', ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ', BS = '<BS> ', Space = '<Space> ', Tab = '<Tab> ',
          F1 = '<F1>', F2 = '<F2>', F3 = '<F3>', F4 = '<F4>', F5 = '<F5>', F6 = '<F6>',
          F7 = '<F7>', F8 = '<F8>', F9 = '<F9>', F10 = '<F10>', F11 = '<F11>', F12 = '<F12>',
        },
      },
      spec = {
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]ocument' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>w', group = '[W]orkspace' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },

  { -- Fuzzy finder
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        defaults = {
          file_ignore_patterns = { 'node%_modules/.*' },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  --------------------------------------------------------------------------
  -- LSP
  --------------------------------------------------------------------------

  { -- Lua LSP support for Neovim config/plugin APIs
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },
  { 'Bilal2453/luvit-meta', lazy = true },

  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', config = true }, -- must load before mason-lspconfig
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} }, -- LSP status updates
      'hrsh7th/cmp-nvim-lsp', -- extra completion capabilities
    },
    config = function()
      -- Runs whenever an LSP attaches to a buffer.
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- Highlight references of word under cursor
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- Toggle inlay hints if supported
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      -- Per-server overrides. Mason installs everything listed as a key here.
      local servers = {
        gopls = {},
        ts_ls = {},

        -- PHP / Laravel
        intelephense = {
          settings = {
            intelephense = {
              stubs = {
                'apache', 'bcmath', 'bz2', 'calendar', 'com_dotnet', 'Core', 'ctype', 'curl',
                'date', 'dba', 'dom', 'enchant', 'exif', 'FFI', 'fileinfo', 'filter', 'fpm',
                'ftp', 'gd', 'gettext', 'gmp', 'hash', 'iconv', 'imap', 'intl', 'json', 'ldap',
                'libxml', 'mbstring', 'meta', 'mysqli', 'oci8', 'odbc', 'openssl', 'pcntl',
                'pcre', 'PDO', 'pdo_ibm', 'pdo_mysql', 'pdo_pgsql', 'pdo_sqlite', 'pgsql',
                'Phar', 'posix', 'pspell', 'readline', 'Reflection', 'session', 'shmop',
                'SimpleXML', 'snmp', 'soap', 'sockets', 'sodium', 'SPL', 'sqlite3',
                'standard', 'superglobals', 'sysvmsg', 'sysvsem', 'sysvshm', 'tidy',
                'tokenizer', 'xml', 'xmlreader', 'xmlrpc', 'xmlwriter', 'xsl', 'Zend OPcache',
                'zip', 'zlib',
              },
              files = { maxSize = 5000000 },
            },
          },
        },

        -- Tailwind CSS (React / Next.js / React Native w/ nativewind, etc.)
        tailwindcss = {
          filetypes = {
            'html', 'css', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact',
          },
        },

        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
              -- Silences lua_ls's noisy "missing-fields" warning, which fires
              -- on tables like the lazy.nvim `opts` below that intentionally
              -- only set a few of the type's many optional fields.
              diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      require('mason').setup()

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, { 'stylua' })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },

  --------------------------------------------------------------------------
  -- FORMATTING
  --------------------------------------------------------------------------

  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        local lsp_format_opt = disable_filetypes[vim.bo[bufnr].filetype] and 'never' or 'fallback'
        return {
          timeout_ms = 500,
          lsp_format = lsp_format_opt,
        }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        golang = { 'prettierd', 'prettier', stop_after_first = true },
        css = { 'prettierd', 'prettier', stop_after_first = true },
      },
    },
  },

  --------------------------------------------------------------------------
  -- COMPLETION
  --------------------------------------------------------------------------

  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
      },
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
    },
    config = function()
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      luasnip.config.setup {}

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = 'menu,menuone,noinsert' },
        mapping = cmp.mapping.preset.insert {
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<enter>'] = cmp.mapping.confirm { select = true },
          ['<C-Space>'] = cmp.mapping.complete {},
          ['<C-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),
          ['<C-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),
        },
        sources = {
          { name = 'lazydev', group_index = 0 }, -- skip loading LuaLS completions (lazydev handles it)
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
        },
      }
    end,
  },

  --------------------------------------------------------------------------
  -- APPEARANCE
  --------------------------------------------------------------------------

  {
    'rose-pine/neovim',
    name = 'rose-pine',
    priority = 1000,
    init = function()
      vim.cmd.colorscheme 'rose-pine'
      vim.cmd.hi 'Comment gui=none'
    end,
  },

  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  { -- mini.nvim: textobjects, surround, statusline
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },

  { -- Syntax highlighting / indent
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'html', 'css', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
  },

  --------------------------------------------------------------------------
  -- EXTRA KICKSTART MODULES / CUSTOM PLUGINS
  --------------------------------------------------------------------------

  require 'kickstart.plugins.debug',
  require 'kickstart.plugins.indent_line',
  require 'kickstart.plugins.lint',
  require 'kickstart.plugins.autopairs',
  require 'kickstart.plugins.neo-tree',
  require 'kickstart.plugins.gitsigns',

  { import = 'custom.plugins' },

}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘', config = '🛠', event = '📅', ft = '📂', init = '⚙',
      keys = '🗝', plugin = '🔌', runtime = '💻', require = '🌙',
      source = '📄', start = '🚀', task = '📌', lazy = '💤 ',
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et