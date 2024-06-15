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
  if M.last_quicklook_file ~= file then
    M.last_quicklook_file = file
    -- require 'dp_base'.system_run('start silent', [[quicklook %s]], file)
    require 'dp_base'.system_run('start silent', [["Image Eye.exe" -freeze -onlyone %s]], file)
  end
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
  if B.is(cfile) and B.file_exists(cfile) and vim.fn.filereadable(cfile) == 1 then
    M.quicklook_do(cfile)
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
      if not M.is_in_norg_fts(ev.file) and B.is_detected_as_bin(ev.file) then
        B.system_run('start silent', ev.file)
        vim.cmd('Bwipeout' .. ev.buf)
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

function M.create_norg_file_and_open_do(arr)
  local dirman = require 'neorg'.modules.get_module 'core.dirman'

  local workspace_match = dirman.get_workspace_match()
  print('workspace_match:', workspace_match)

  -- local current_workspace = dirman.get_current_workspace()
  -- print("vim.inspect(vim.tbl_keys(current_workspace)):", vim.inspect(vim.tbl_keys(current_workspace)))
  -- print("vim.inspect(current_workspace):", vim.inspect(current_workspace))

  -- local workspaces = dirman.get_workspaces()
  -- print("vim.inspect(vim.tbl_keys(workspaces)):", vim.inspect(vim.tbl_keys(workspaces)))

  dirman.create_file(vim.fn.join(arr, '/'), workspace_match, {
    no_open  = false, -- open file after creation?
    force    = false, -- overwrite file if exists
    metadata = {},    -- key-value table for metadata fields
  })
end

function M.create_norg_file_and_open()
  local cWORD = vim.fn.expand '<cWORD>'
  if string.match(cWORD, ':}%[') then
    B.notify_info '已是norg文件链接'
    return
  end
  if not string.match(cWORD, '([^,]+,[^,]+,[^,]+).*') then
    B.notify_info(cWORD .. ' not match: xx,yy,zz')
    return
  end
  cWORD = vim.split(cWORD, '->')[1]
  local paragraph = B.get_paragraph()
  local patt = '(20[%d][%d]%-[01][%d]%-[0123][%d])'
  local date = ''
  local year, month, day
  for _, line in ipairs(paragraph) do
    local res = string.match(line, patt)
    if res then
      date = res
      break
    end
  end
  if B.is(date) then
    year, month, day = unpack(vim.split(date, '-'))
  else
    year, month, day = vim.fn.strftime '%Y', vim.fn.strftime '%m', vim.fn.strftime '%d'
  end
  B.cmd('.s/%s/%s', cWORD, string.format('{:$\\/journal\\\\%s\\\\%s\\\\%s-%s:}[%s]', year, month, day, cWORD, cWORD))
  M.create_norg_file_and_open_do { 'journal', year, month, day .. '-' .. cWORD, }
end

function M.yank_rb_to_wxwork()
  local paragraph = B.get_paragraph()
  local paragraph_new = {}
  local cnt = 1
  for _, para in ipairs(paragraph) do
    para = vim.fn.trim(para, '* -~')
    local title = string.match(para, '%d+%-([^,]+,[^,]+,[^:]+):}')
    if not title then
      title = string.match(para, '%([^,]+,[^,]+,[^:]+)%->')
    end
    local text = string.match(para, '%->(.+)')
    if title and text then
      para = string.format('%d. %s->%s', cnt, title, text)
      cnt = cnt + 1
    else
      para = vim.fn.trim(para, '-周1234567一二三四五六日七')
    end
    paragraph_new[#paragraph_new + 1] = para
  end
  local lines = vim.fn.join(paragraph_new, '\n')
  vim.fn.setreg('+', lines)
  B.notify_info { 'copied to +', lines, }
end

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
  ['<leader>n<cr>'] = { function() M.create_norg_file_and_open() end, 'create_norg_file_and_open', mode = { 'n', 'v', }, silent = true, },
  ['<leader>n<tab>'] = { function() M.yank_rb_to_wxwork() end, 'yank_rb_to_wxwork', mode = { 'n', 'v', }, silent = true, },
}

return M
