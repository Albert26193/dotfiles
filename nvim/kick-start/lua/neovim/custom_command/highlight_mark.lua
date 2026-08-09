-- init.lua
vim.cmd("highlight MyMarkHighlight ctermbg=cyan guibg=cyan")
vim.cmd("highlight MyMarkLetter ctermfg=white ctermbg=red guifg=white guibg=red")

local api = vim.api
local ns = api.nvim_create_namespace("highlight_marks")

local old_marks = {}  -- store previous marks
function highlight_marks()
  -- clear previous highlights
  api.nvim_buf_clear_namespace(0, ns, 0, -1)

  -- clear old mark chars
  for mark, mark_line in pairs(old_marks) do
    local mark_text = api.nvim_buf_get_lines(0, mark_line, mark_line + 1, false)[1]
    local mark_index = string.find(mark_text, "    " .. mark)
    if mark_index then
      local new_mark_text = string.sub(mark_text, 1, mark_index - 1) .. string.sub(mark_text, mark_index + 5)
      api.nvim_buf_set_lines(0, mark_line, mark_line + 1, false, {new_mark_text})
    end
  end

  -- get all marks
  -- local marks = api.nvim_exec("marks", true)
  -- print("all marks: " .. vim.inspect(marks))

  -- init current buffer marks list
  local current_buf_marks = {}

  -- get current buffer number
  local current_bufnr = api.nvim_get_current_buf()

  -- iterate marks a-z
  for i = 97, 122 do -- ASCII values for 'a' to 'z'
    local mark = api.nvim_buf_get_mark(current_bufnr, string.char(i))
    if mark[1] >= 1 then
      current_buf_marks[string.char(i)] = mark[1] - 1
    end
  end

  -- clear previously added letters
for _, mark_line in pairs(current_buf_marks) do
    local mark_text = api.nvim_buf_get_lines(0, mark_line, mark_line + 1, false)[1]
    api.nvim_buf_set_lines(0, mark_line, mark_line + 1, false, {string.sub(mark_text, 3)})
  end

  -- print current_buf_marks
  print("Current buffer marks: " .. vim.inspect(current_buf_marks))

  -- iterate current buffer marks
  for mark, mark_line in pairs(current_buf_marks) do
    -- highlight mark line
    api.nvim_buf_add_highlight(0, ns, "MyMarkHighlight", mark_line, 0, -1)

    -- add letter at end of mark line
  local mark_text = api.nvim_buf_get_lines(0, mark_line, mark_line + 1, false)[1]
    local mark_index = string.find(mark_text, "    " .. mark)
    if mark_index then
      mark_text = string.sub(mark_text, 1, mark_index - 1) .. string.sub(mark_text, mark_index + 4)
    end
  local new_mark_text = mark_text .. "    " .. mark
    api.nvim_buf_set_lines(0, mark_line, mark_line + 1, false, {new_mark_text})
    api.nvim_buf_add_highlight(0, ns, "MyMarkLetter", mark_line, #mark_text + 1, #new_mark_text)
  end

  -- update old_marks to store current marks
  old_marks = current_buf_marks

end

-- create HighlightMarks command
vim.cmd("command! HighlightMarks lua highlight_marks()")
