local M = {}

local function tmux(args, input)
  local result = vim.system(vim.list_extend({ 'tmux' }, args), { text = true, stdin = input }):wait()
  if result.code ~= 0 then
    return nil
  end
  return result.stdout or ''
end

local function in_tmux()
  return vim.env.TMUX ~= nil and vim.env.TMUX ~= ''
end

local function realpath(path)
  if not path or path == '' then
    return nil
  end

  local uv = vim.uv or vim.loop
  return uv.fs_realpath(path) or vim.fn.fnamemodify(path, ':p'):gsub('/$', '')
end

local function is_parent_or_same_path(parent, child)
  parent = realpath(parent)
  child = realpath(child)
  if not parent or not child then
    return false
  end

  if parent == child then
    return true
  end

  return child:sub(1, #parent + 1) == parent .. '/'
end

local function find_nearest_claude_pane()
  if not in_tmux() then
    return nil
  end

  local current = tmux({ 'display-message', '-p', '#{pane_id}\t#{pane_index}' })
  if not current then
    return nil
  end

  local current_id, current_index = current:match('([^\t\n]+)\t([^\t\n]+)')
  current_index = tonumber(current_index)
  if not current_id or not current_index then
    return nil
  end

  local nvim_cwd = vim.fn.getcwd()
  local panes = tmux({ 'list-panes', '-F', '#{pane_id}\t#{pane_index}\t#{pane_current_command}\t#{pane_title}\t#{pane_current_path}' })
  if not panes then
    return nil
  end

  local target
  for line in panes:gmatch('[^\n]+') do
    local pane_id, pane_index, command, title, pane_path = line:match('([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)')
    pane_index = tonumber(pane_index)
    command = command or ''
    title = title or ''

    if pane_id ~= current_id
        and pane_index
        and (command == 'claude' or title:lower():find('claude', 1, true))
        and is_parent_or_same_path(pane_path, nvim_cwd) then
      local distance = math.abs(pane_index - current_index)
      if not target
          or distance < target.distance
          or (distance == target.distance and pane_index > target.index) then
        target = {
          id = pane_id,
          index = pane_index,
          distance = distance,
        }
      end
    end
  end

  return target and target.id or nil
end

local function paste_to_tmux_pane(pane_id, content)
  if not pane_id or not content or content == '' then
    return
  end

  local buffer_name = 'nvim-claude-ref'
  local loaded = tmux({ 'load-buffer', '-b', buffer_name, '-' }, content)
  if not loaded then
    return
  end

  local pasted = tmux({ 'paste-buffer', '-d', '-b', buffer_name, '-t', pane_id })
  if pasted then
    tmux({ 'select-pane', '-t', pane_id })
  end
end

local function send_to_nearest_claude_pane(content)
  local pane_id = find_nearest_claude_pane()
  if pane_id then
    paste_to_tmux_pane(pane_id, content)
  end
end

function M.copy_visual_file_reference()
  -- 1. 强制退出 Visual 模式以更新选区标记 '< 和 '>
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', true)
  vim.schedule(function()
    -- 2. 获取路径
    -- %:p 代表绝对路径 (Absolute Path: /Users/name/project/file.cc)
    -- %   代表相对路径 (Relative Path: sql/tdsql/file.cc)
    local full_path = vim.fn.expand('%:p')
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")
    -- 3. 构造行号部分
    local line_part = (start_line == end_line) and ('#L' .. start_line) or ('#L' .. start_line .. '-' .. end_line)
    -- 4. 组合成最终格式: @/absolute/path/to/file#L236-283
    local content = '@' .. full_path .. line_part
    -- 5. 写入系统剪切板
    vim.fn.setreg('+', content)
    send_to_nearest_claude_pane(content)
    -- 6. 简短提示，避免多行 echo 触发确认
    vim.api.nvim_echo({ { 'Copied', 'Identifier' } }, false, {})
  end)
end

return M
