-- Copyright (c) 2024 liudepei. All Rights Reserved.
-- create at 2024/06/11 00:16:34 Tuesday

local sta, B = pcall(require, 'dp_base')

if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

if B.check_plugins {
      'folke/which-key.nvim',
    } then
  return
end

local M               = {}

M.source              = B.getsource(debug.getinfo(1)['source'])
M.lua                 = B.getlua(M.source)

vim.o.conceallevel    = 2
vim.o.foldlevel       = 99

M.last_quicklook_file = ''
M.quicklook_filetypes = { 'jpg', 'png', 'pdf', 'html', 'docx', }

M.last_file           = ''

M.NORG_EXTS           = { 'norg', }

M.start_from_norg     = 0

require 'neorg'.setup {
  load = {
    ['core.defaults'] = {},
    ['core.concealer'] = {},
    ['core.esupports.metagen'] = {
      config = {
        update_date = false,
        type = 'empty',
        author = 'peter-lyr',
        timezone = 'implicit-local',
      },
    },
    ['core.export'] = {},
    ['core.export.markdown'] = {
      config = {
        extensions = 'all',
      },
    },
    ['core.ui'] = {},
    ['core.ui.calendar'] = {}, -- 解决中文乱码问题需要将Windows display language改为英文(美国)
    ['core.tempus'] = {},
    ['core.dirman'] = {
      config = {
        workspaces = {
          work = DepeiRepos .. '\\work',
          life = DepeiRepos .. '\\life',
          study = DepeiRepos .. '\\study',
        },
        default_workspace = 'work',
      },
    },
    ['core.integrations.telescope'] = {},
  },
}

function M.toggle_concealer_0_2()
  if vim.o.conceallevel == 0 then
    vim.o.conceallevel = 2
  else
    vim.o.conceallevel = 0
  end
  B.echo('vim.o.conceallevel: %s', vim.o.conceallevel)
end

function M.quicklook_do_do(file)
  if not file then
    file = B.rep(B.get_cfile())
  end
  if not file then
    file = B.buf_get_name()
  end
  if not B.is_file(file) then
    return
  end
  require 'dp_base'.system_run('start silent', [[quicklook %s]], file)
end

function M.quicklook_do(file)
  if not file then
    file = B.buf_get_name()
  end
  if not B.is_file_in_filetypes(file, M.quicklook_filetypes) then
    return
  end
  M.quicklook_do_do(file)
end

function M.quicklook()
  local cfile = B.rep(B.get_cfile())
  if B.is(cfile) and B.file_exists(cfile) and vim.fn.filereadable(cfile) == 1 and M.last_quicklook_file ~= cfile then
    M.quicklook_do(cfile)
    M.last_quicklook_file = cfile
    -- else
    --   M.quicklook_do(M.last_quicklook_file)
    --   M.last_quicklook_file = ''
  end
end

function M.is_in_norg_fts(file)
  return B.is_file_in_extensions(file, M.NORG_EXTS)
end

B.aucmd({ 'CursorMoved', 'CursorMovedI', }, 'neorg.CursorMoved', {
  callback = function()
    M.quicklook()
  end,
})

B.aucmd({ 'BufReadPre', }, 'neorg.BufReadPre', {
  callback = function()
    M.start_from_norg = 0
    if B.is(M.last_file) then
      if M.is_in_norg_fts(M.last_file) then
        M.start_from_norg = 1
      end
    end
  end,
})

B.aucmd({ 'BufReadPost', }, 'neorg.BufReadPost', {
  callback = function(ev)
    if M.start_from_norg == 1 then
      if not M.is_in_norg_fts(ev.file) then
        B.system_run('start silent', ev.file)
        vim.cmd(ev.buf .. 'bw!')
      end
    end
  end,
})

B.aucmd({ 'BufEnter', }, 'neorg.BufEnter', {
  callback = function(ev)
    M.last_file = B.rep(ev.file)
    if not B.is_file(M.last_file) then
      M.last_file = ''
    end
  end,
})

require 'which-key'.register {
  ['<leader>nw'] = { '<cmd>Neorg workspace work<cr>', 'Neorg workspace work', mode = { 'n', 'v', }, silent = true, },
  ['<leader>nl'] = { '<cmd>Neorg workspace life<cr>', 'Neorg workspace life', mode = { 'n', 'v', }, silent = true, },
  ['<leader>ns'] = { '<cmd>Neorg workspace study<cr>', 'Neorg workspace study', mode = { 'n', 'v', }, silent = true, },

  ['<leader>nf'] = { '<cmd>Telescope neorg insert_file_link<cr>', 'Neorg insert_file_link', mode = { 'n', 'v', }, silent = true, },
  ['<leader>nb'] = { '<cmd>Telescope neorg insert_link<cr>', 'Neorg insert_link', mode = { 'n', 'v', }, silent = true, },

  ['<leader>nt'] = { '<cmd>Neorg journal today<cr>', 'Neorg journal today', mode = { 'n', 'v', }, silent = true, },
  ['<leader>ny'] = { '<cmd>Neorg journal yesterday<cr>', 'Neorg journal yesterday', mode = { 'n', 'v', }, silent = true, },
  ['<leader>nm'] = { '<cmd>Neorg journal tomorrow<cr>', 'Neorg journal tomorrow', mode = { 'n', 'v', }, silent = true, },

  ['<leader>ne'] = { '<cmd>Neorg mode traverse-heading<cr>', 'Neorg mode traverse-heading', mode = { 'n', 'v', }, silent = true, },
  ['<leader>ni'] = { '<cmd>Neorg mode traverse-link<cr>', 'Neorg mode traverse-link', mode = { 'n', 'v', }, silent = true, },
  ['<leader>ng'] = { '<cmd>Neorg mode norg<cr>', 'Neorg mode norg', mode = { 'n', 'v', }, silent = true, },
  ['<leader>ndq'] = { function() M.quicklook_do_do() end, 'quicklook_do_do', mode = { 'n', 'v', }, silent = true, },
}

return M
