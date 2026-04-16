local M = {}

-- ============================================
-- STATE
-- ============================================
local preview_buf = nil
local preview_win = nil

-- ============================================
-- STATE CHECK
-- ============================================
function M.is_open()
  return preview_win and vim.api.nvim_win_is_valid(preview_win)
end

-- ============================================
-- READ FILE CONTENT
-- ============================================
local function read_file_content(file_path, max_lines)
  local content = vim.fn.readfile(file_path)
  if not content then
    return {}
  end
  
  local lines = {}
  local start_line = 1
  
  for i = start_line, math.min(#content, max_lines) do
    table.insert(lines, content[i])
  end
  
  return lines
end

-- ============================================
-- FORMAT LINES WITH LINE NUMBERS
-- ============================================
local function format_lines_with_numbers(lines)
  local formatted = {}
  local max_width = tostring(#lines):len()
  
  for i, line in ipairs(lines) do
    local line_num = string.format("%" .. max_width .. "d │ %s", i, line)
    table.insert(formatted, line_num)
  end
  
  return formatted
end

-- ============================================
-- CREATE PREVIEW WINDOW
-- ============================================
function M.create(mark)
  local config = require("marko.config").get()
  
  if not config.preview.enabled then
    return
  end
  
  -- Close existing preview
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_win_close(preview_win, true)
  end
  
  if not mark or not mark.filename then
    return
  end
  
  local file_path = mark.filename
  local bookmarked_line = mark.line or 1
  
  -- Read file content
  local content = read_file_content(file_path, config.preview.lines)
  
  if #content == 0 then
    return
  end
  
  -- Create buffer
  preview_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[preview_buf].bufhidden = "wipe"
  vim.bo[preview_buf].filetype = "marko-preview"
  
  -- Format lines
  local lines
  if config.preview.show_line_numbers then
    lines = format_lines_with_numbers(content)
  else
    lines = content
  end
  
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
  vim.bo[preview_buf].modifiable = false
  
  -- Calculate window position
  local width = config.preview.width
  local height = math.min(#lines + 2, config.preview.lines + 2)
  local row = math.ceil((vim.o.lines - height) / 2)
  
  local col
  if config.preview.position == "left" then
    col = 0
  else
    col = vim.o.columns - width - 1
  end
  
  -- Create window
  preview_win = vim.api.nvim_open_win(preview_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = config.border,
    style = "minimal",
    focusable = true,
  })
  
  -- Set window options
  vim.wo[preview_win].winhl = "Normal:MarkoNormal,FloatBorder:MarkoBorder"
  vim.wo[preview_win].cursorline = true
  
  -- Highlight the bookmarked line
  if bookmarked_line <= #content then
    vim.api.nvim_buf_add_highlight(preview_buf, -1, "Visual", bookmarked_line - 1, 0, -1)
    
    -- Highlight exact position if available
    if mark.col then
      vim.api.nvim_buf_add_highlight(preview_buf, -1, "Error", bookmarked_line - 1, mark.col - 1, mark.col)
    end
  end
  
  -- Set up keymaps to close preview
  vim.keymap.set("n", "q", function()
    M.close()
  end, { buffer = preview_buf, silent = true })
  
  vim.keymap.set("n", "<Esc>", function()
    M.close()
  end, { buffer = preview_buf, silent = true })
end

-- ============================================
-- CLOSE PREVIEW WINDOW
-- ============================================
function M.close()
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_win_close(preview_win, true)
  end
  preview_win = nil
  preview_buf = nil
end

return M