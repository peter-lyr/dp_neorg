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
M.quicklook_filetypes = { 'jpg', 'png', }

M.last_file           = ''

M.NORG_EXTS           = { 'norg', }

M.start_from_norg     = 0

M.patt_plan           = '20[%d][%d]%-[01][%d]%-[0123][%d]计划'

M.quicklook_allow     = 1

M.max_text_fsize      = 1024 * 1024
M.norg_opend          = nil

M.norg_create_in_dirs = {
  '.rb|default', -- 日报
  '.zj',         -- 总结
}

require 'neorg'.setup {
  load = {
    ['core.defaults'] = {},
    ['core.concealer'] = {},
    ['core.esupports.metagen'] = {
      config = {
        update_date = false,
        -- type = 'empty',
        type = 'none',
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
    -- ['core.ui'] = {},
    -- ['core.ui.calendar'] = {}, -- 解决中文乱码问题需要将Windows display language改为英文(美国)
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
    -- ['core.integrations.telescope'] = {},
    -- ['external.integrations.figlet'] = {},
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
    require 'dp_base'.system_run('start silent', [["Image Eye.exe" -freeze -onlyone "%s"]], file)
  end
end

function M.quicklook_do(file)
  if M.quicklook_allow == 0 then
    B.echo('M.quicklook_allow: ' .. tostring(M.quicklook_allow))
    return
  end
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

function M.quicklook_toggle()
  M.quicklook_allow = 1 - M.quicklook_allow
  print('M.quicklook_allow: ' .. tostring(M.quicklook_allow))
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
  callback = function(ev)
    if M.norg_opend then
      local fsize = vim.fn.getfsize(ev.file)
      if fsize > M.max_text_fsize then
        B.system_run('start silent', 'nvim-qt.exe "%s"', ev.file)
      end
    end
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
        if B.is_detected_as_bin(ev.file) then
          B.system_run('start silent', ev.file)
          vim.cmd('Bwipeout' .. ev.buf)
        end
      end
    end
    if M.norg_opend then
      local fsize = vim.fn.getfsize(ev.file)
      if fsize > M.max_text_fsize then
        vim.cmd('Bwipeout' .. ev.buf)
      end
    end
  end,
})

B.aucmd({ 'BufEnter', }, 'neorg.BufEnter', {
  callback = function(ev)
    M.last_file = B.rep(ev.file)
    if M.is_in_norg_fts(M.last_file) then
      M.norg_opend = 1
    else
      M.last_file = ''
    end
  end,
})

function M.create_norg_file_and_open_do(arr)
  local dirman = require 'neorg'.modules.get_module 'core.dirman'
  local workspace_match = dirman.get_workspace_match()
  local file = B.get_file(vim.loop.cwd(), vim.fn.join(arr, '\\')) .. '.norg'
  if B.file_exists(file) then
    B.jump_or_edit(file)
    return
  end
  dirman.create_file(vim.fn.join(arr, '/'), workspace_match, {
    no_open  = false,
    force    = false,
    metadata = {},
  })
end

function M.create_journal_task_norg(cWORD)
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
    year, month, _ = unpack(vim.split(date, '-'))
  else
    year, month, _ = vim.fn.strftime '%Y', vim.fn.strftime '%m', vim.fn.strftime '%d'
  end
  if not M.anchor then
    B.cmd('.s/%s/%s', cWORD, string.format('[%s]{:$/journal/%s/%s/%s:}', cWORD, year, month, cWORD))
  else
    local link = string.format('~ [%s]{:$/journal/%s/%s/%s:}', cWORD, year, month, cWORD)
    local append = 1
    for _, line in ipairs(vim.fn.readfile(B.buf_get_name())) do
      if B.is_in_str('%[' .. cWORD .. '%]{:', line) then
        append = nil
      end
    end
    if append then
      vim.fn.append('$', link)
      local save_cursor = vim.fn.getpos '.'
      vim.cmd 'norm gg=G'
      pcall(vim.fn.setpos, '.', save_cursor)
    end
  end
  M.create_norg_file_and_open_do { 'journal', year, month, cWORD, }
end

function M.create_cur_dir_norg(cWORD)
  local cur_file = B.buf_get_name()
  local cur_dir = vim.fn.fnamemodify(cur_file, ':h')
  local new_file = B.get_file(cur_dir, cWORD)
  local new_file_rel = B.relpath(new_file, vim.loop.cwd())
  local paths = vim.split(B.rep(new_file_rel), '\\')
  local temp = string.gsub(new_file_rel, '/', '\\/')
  B.cmd('.s/%s/%s', cWORD, string.format('{:$\\/%s:}[%s]', temp, cWORD))
  M.create_norg_file_and_open_do(paths)
end

-- function M.create_norg_file_and_open(journal)
--   local cWORD = vim.fn.expand '<cWORD>'
--   local temp = string.match(cWORD, '%[(.+)%]')
--   M.anchor = nil
--   if temp then
--     M.anchor = 1
--     cWORD = temp
--   end
--   local res = B.not_allow_in_file_name(cWORD)
--   if res then
--     B.print('not_allow_in_file_name: %s', res)
--     return
--   end
--   if string.match(cWORD, ':}%[') then
--     vim.cmd [[call feedkeys("\<cr>")]]
--     return
--   end
--   if not journal and (not string.match(vim.fn.join(B.get_paragraph(), '\n'), M.patt_plan) or not string.match(cWORD, '([^,]+,[^,]+,[^,]+).*')) then
--     M.create_cur_dir_norg(cWORD)
--     return
--   end
--   M.create_journal_task_norg(cWORD)
-- end

function M.de_norg_link()
  local paragraph = B.get_paragraph()
  if string.match(vim.fn.join(paragraph, '\n'), M.patt_plan) then
    local save_cursor = vim.fn.getpos '.'
    local paragraph_new = {}
    for _, line in ipairs(paragraph) do
      line = vim.fn.trim(line, '* -~')
      local title = string.match(line, '%d+%-([^,]+,[^,]+,[^:]+):}')
      if not title then
        title = string.match(line, '([^,]+,[^,]+,[^:]+)%->')
        if not title then
          title = string.match(line, '%[([^,]+,[^,]+,[^:]+)%]%->')
        end
      end
      if title then
        line = string.format('~ %s', title)
      elseif string.match(line, M.patt_plan) then
        line = string.format('* %s', line)
      else
        line = string.format('~ %s', line)
      end
      paragraph_new[#paragraph_new + 1] = line
    end
    B.cmd 'norm dipk'
    vim.fn.append('.', paragraph_new)
    B.cmd 'norm =ap'
    pcall(vim.fn.setpos, '.', save_cursor)
  else
    local line = vim.fn.getline '.'
    line = vim.fn.trim(line, '* -~')
    local title = string.match(line, '{[^}]+}%[([^%]]+)%]')
    if title then
      vim.fn.setline('.', '~ ' .. title)
      B.cmd 'norm =='
    end
  end
end

function M.yank_rb_to_wxwork()
  local paragraph = B.get_paragraph()
  local paragraph_new = {}
  local cnt = 1
  for _, line in ipairs(paragraph) do
    line = vim.fn.trim(line, '* -~')
    local title = string.match(line, '%d+%-([^,]+,[^,]+,[^:]+):}')
    if not title then
      title = string.match(line, '%([^,]+,[^,]+,[^:]+)%->')
    end
    local text = string.match(line, '%->(.+)')
    if title and text then
      line = string.format('%d. %s->%s', cnt, title, text)
      cnt = cnt + 1
    else
      local temp = vim.fn.trim(line, '-周一二三四五六日七')
      if string.match(line, '([^,]+,[^,]+,[^:]+)') then
        title = string.match(line, '%[([^,]+,[^,]+,[^%]]+)%]')
        text = string.match(line, '%->(.+)')
        if title and text then
          line = string.format('%d. %s->%s', cnt, title, text)
        elseif title and not text then
          line = string.format('%d. %s', cnt, title)
        else
          line = tostring(cnt) .. '. ' .. temp
        end
        cnt = cnt + 1
      else
        line = temp
      end
    end
    paragraph_new[#paragraph_new + 1] = line
  end
  local lines = vim.fn.join(paragraph_new, '\n')
  vim.fn.setreg('+', lines)
  B.notify_info { 'copied to +', lines, }
end

function M.get_one_or_nil(text)
  local norg = B.get_text_in_bracket(text)
  if norg then
    -- NOTE: 这里也可能有多个
    -- 一个则直接返回
    local cnt = 0
    for _ in string.gmatch(text, '%[[^%]]+%]') do
      cnt = cnt + 1
    end
    for _ in string.gmatch(text, '}%[[^%]]+%]') do
      cnt = cnt - 1
    end
    for _ in string.gmatch(text, '%[[^%]]+%]{') do
      cnt = cnt - 1
    end
    if cnt == 1 then
      return norg
    end
  end
end

function M.get_near_bracket_text()
  local cWORD = vim.fn.expand '<cWORD>'
  local norg = M.get_one_or_nil(cWORD)
  if norg then
    return norg
  end
  local line = vim.fn.getline '.'
  local line_table = B.string_split_char_to_table(line)
  local cur_col = vim.fn.getcurpos()[3]
  local cur_index = B.get_char_index_of_arr(cur_col, line_table)
  local cur_char = line_table[cur_index]
  local left_index = cur_index
  local right_index = cur_index
  for index, char in ipairs(line_table) do
    if index < cur_index then
      if char == '[' then
        left_index = index
      end
    end
    if index > cur_index then
      if char == ']' then
        right_index = index
        break
      end
    end
  end
  if cur_char == ']' then
    right_index = cur_index
  elseif cur_char == '[' then
    left_index = cur_index
  end
  local temp = ''
  for index, char in ipairs(line_table) do
    if index >= left_index - 1 and index <= right_index + 1 then
      temp = temp .. char
    end
  end
  norg = M.get_one_or_nil(temp)
  return norg
end

function M.get_dir(dir)
  local temp = string.match(dir, '([^|]+)|default')
  if temp then
    dir = temp
  end
  return dir
end

function M.check_norg_if_exists(fname)
  local files = {}
  local first_exist = nil
  for i, dir in ipairs(M.norg_create_in_dirs) do
    dir = M.get_dir(dir)
    local file = B.get_file({ vim.loop.cwd(), dir, }, fname .. '.norg')
    if B.file_exists(file) then
      files[#files + 1] = file
      if i == 1 then
        first_exist = 1
      end
    end
  end
  return first_exist, files
end

function M.sel_create_in_other_dirs(fname)
  local temp = vim.deepcopy(M.norg_create_in_dirs)
  table.remove(temp, 1)
  if #temp == 1 then
    M.create_norg_file_and_open_do { temp[1], fname, }
  else
    B.ui_sel(temp, 'create norg in which dir', function(dir)
      if dir then
        M.create_norg_file_and_open_do { dir, fname, }
      end
    end)
  end
end

function M.create_or_jump(open_default, create_force)
  local fname = M.get_near_bracket_text()
  if not fname then
    return
  end
  if not create_force then
    create_force = nil
  end
  if create_force then
    B.ui_sel(M.norg_create_in_dirs, 'create norg in which dir', function(dir)
      if dir then
        dir = M.get_dir(dir)
        M.create_norg_file_and_open_do { dir, fname, }
      end
    end)
    return
  end
  if not open_default then
    open_default = 'default'
  end
  local first_exist, files = M.check_norg_if_exists(fname)
  if #files == 0 then
    if open_default == 'default' then
      M.create_norg_file_and_open_do { M.get_dir(M.norg_create_in_dirs[1]), fname, }
    else
      M.sel_create_in_other_dirs(fname)
    end
  else
    if open_default == 'default' then
      if first_exist then
        B.jump_or_edit(files[1])
      else
        M.create_norg_file_and_open_do { M.get_dir(M.norg_create_in_dirs[1]), fname, }
      end
    else
      if first_exist then
        table.remove(files, 1)
      end
      if #files == 0 then
        M.sel_create_in_other_dirs(fname)
      elseif #files == 1 then
        B.jump_or_edit(files[1])
      else
        B.ui_sel(files, 'open which norg', function(file)
          if file then
            B.jump_or_edit(file)
          end
        end)
      end
    end
  end
end

function M.norg2md(open_preview)
  if not B.is_file_in_filetypes(nil, 'norg') then
    return
  end
  local dst = vim.fn.fnamemodify(vim.fn.expand '%', ':~:.:r') .. '.md'
  vim.cmd(string.format('Neorg export to-file %s', string.gsub(dst, ' ', [[\ ]])))
  vim.schedule(function()
    vim.cmd.edit(dst)
    if open_preview then
      vim.cmd 'MarkdownPreview'
    end
  end)
end

function M.norg_toc_split()
  vim.cmd 'Neorg toc right'
  vim.cmd 'set winfixwidth'
end

function M.create_same_dir_as_norg()
  local file = B.rep(B.buf_get_name())
  if not M.is_in_norg_fts(file) then
    return
  end
  local dirname = vim.fn.fnamemodify(file, ':p:r')
  B.getcreate_dir(dirname)
  local test = B.getcreate_dir({dirname, 'test'})
  local a_norg = B.getcreate_file(test, 'a.norg')
  B.jump_or_edit(a_norg)
  require 'dp_nvimtree'.open(test)
  local _git = B.get_dir({test, '.git'})
  if not B.is_dir(_git) then
    require 'dp_git.push'.just_init_do(test)
  end
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
  ['<leader>nh'] = { name = 'neorg more', },
  ['<leader>nhq'] = { function() M.quicklook_toggle() end, 'quicklook_toggle', mode = { 'n', 'v', }, silent = true, },
  ['<leader>nhe'] = { function() M.norg2md() end, 'norg2md', mode = { 'n', 'v', }, silent = true, },
  -- ['<leader>n<cr>'] = { function() M.create_norg_file_and_open() end, 'create_norg_file_and_open', mode = { 'n', 'v', }, silent = true, },
  -- ['<leader>n<c-cr>'] = { function() M.create_norg_file_and_open(1) end, 'create_norg_file_and_open journal', mode = { 'n', 'v', }, silent = true, },
  ['<leader>n<del>'] = { function() M.de_norg_link() end, 'de_norg_link', mode = { 'n', 'v', }, silent = true, },
  ['<leader>n<tab>'] = { function() M.yank_rb_to_wxwork() end, 'yank_rb_to_wxwork', mode = { 'n', 'v', }, silent = true, },
  ['<leader>n<c-o>'] = { function() M.norg_toc_split() end, 'norg_toc_split', mode = { 'n', 'v', }, silent = true, },
  ['<leader>n<c-cr>'] = { function() M.create_same_dir_as_norg() end, 'create_same_dir_as_norg', mode = { 'n', 'v', }, silent = true, },
}

return M
