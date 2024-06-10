-- Copyright (c) 2024 liudepei. All Rights Reserved.
-- create at 2024/06/11 00:16:34 Tuesday

local sta, B = pcall(require, 'dp_base')

if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

if B.check_plugins {
      'folke/which-key.nvim',
    } then
  return
end

local M  = {}

M.source = B.getsource(debug.getinfo(1)['source'])
M.lua    = B.getlua(M.source)

vim.wo.conceallevel = 2
vim.wo.foldlevel = 99

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
    ['core.ui'] = {},
    ['core.ui.calendar'] = {},               -- 解决中文乱码问题需要将Windows display language改为英文(美国)
    ['core.tempus'] = {},
    ['core.dirman'] = {
      config = {
        workspaces = {
          notes = DepeiRepos .. '\\notes',
          work = DepeiRepos .. '\\notes\\.work',
          life = DepeiRepos .. '\\notes\\.life',
        },
        default_workspace = 'notes',
      },
    },
    ['core.integrations.telescope'] = {},
  },
}

require 'which-key'.register {
  ['<leader>nw'] = { '<cmd>Neorg workspace work<cr>', 'Neorg workspace work', mode = { 'n', 'v', }, silent = true, },
  ['<leader>nl'] = { '<cmd>Neorg workspace life<cr>', 'Neorg workspace life', mode = { 'n', 'v', }, silent = true, },
  ['<leader>nn'] = { '<cmd>Neorg workspace notes<cr>', 'Neorg workspace notes', mode = { 'n', 'v', }, silent = true, },
  ['<leader>nf'] = { '<cmd>Telescope neorg insert_file_link<cr>', 'Neorg insert_file_link', mode = { 'n', 'v', }, silent = true, },
  ['<leader>nt'] = { '<cmd>Neorg journal today<cr>', 'Neorg journal today', mode = { 'n', 'v', }, silent = true, },
  ['<leader>ny'] = { '<cmd>Neorg journal yestoday<cr>', 'Neorg journal yestoday', mode = { 'n', 'v', }, silent = true, },
  ['<leader>nm'] = { '<cmd>Neorg journal tomorrow<cr>', 'Neorg journal tomorrow', mode = { 'n', 'v', }, silent = true, },
}

return M
