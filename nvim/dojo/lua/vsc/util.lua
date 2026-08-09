local M = {}

local ok, vscode = pcall(require, 'vscode')
if not ok then
  return M
end

M.vscode = vscode

function M.action(command, opts)
  return function()
    vscode.action(command, opts)
  end
end

function M.call(command, opts, timeout)
  return function()
    vscode.call(command, opts, timeout)
  end
end

function M.run_actions(commands)
  return function()
    for _, item in ipairs(commands) do
      if type(item) == 'string' then
        vscode.action(item)
      else
        vscode.action(item.command, item.opts)
      end
    end
  end
end

function M.current_word()
  return vim.fn.expand('<cword>')
end

function M.find_in_files(query)
  vscode.action('workbench.action.findInFiles', {
    args = {
      query = query,
      triggerSearch = true,
      focusResults = false,
    },
  })
end

function M.find_word_under_cursor()
  M.find_in_files(M.current_word())
end

return M
