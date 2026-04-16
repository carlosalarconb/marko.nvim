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
local function read_file_content(file_path, center_line, max_lines)
  local all_content = vim.fn.readfile(file_path)
  if not all_content then
    return {}, center_line
  end
  
  local total_lines = #all_content
  local half_range = math.floor(max_lines / 2)
  
  local start_line = math.max(1, center_line - half_range)
  local end_line = math.min(total_lines, center_line + half_range)
  
  local lines = {}
  for i = start_line, end_line do
    table.insert(lines, {
      num = i,
      text = all_content[i]
    })
  end
  
  return lines, center_line - start_line + 1
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
  
  -- Read file content centered on the mark line
  local content, highlight_index = read_file_content(file_path, bookmarked_line, config.preview.lines)
  
  if #content == 0 then
    return
  end
  
  -- Create buffer
  preview_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[preview_buf].bufhidden = "wipe"
  vim.bo[preview_buf].filetype = "marko-preview"
  
  -- Format lines with line numbers
  local lines = {}
  for _, item in ipairs(content) do
    table.insert(lines, string.format("%5d │ %s", item.num, item.text))
  end
  
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
  vim.bo[preview_buf].modifiable = false
  
  -- Calculate window position - centered
  local width = config.preview.width
  local height = math.min(#lines + 2, config.preview.lines)
  local row = math.ceil((vim.o.lines - height) / 2)
  local col = math.ceil((vim.o.columns - width) / 2)
  
  -- Create window with higher zindex to appear in front
  preview_win = vim.api.nvim_open_win(preview_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = config.border,
    style = "minimal",
    focusable = true,
    zindex = 100,
  })
  
  -- Set window options
  vim.wo[preview_win].winhl = "Normal:MarkoNormal,FloatBorder:MarkoBorder"
  vim.wo[preview_win].cursorline = true
  
  -- Highlight the bookmarked line
  if highlight_index then
    vim.api.nvim_buf_add_highlight(preview_buf, -1, "Visual", highlight_index - 1, 0, -1)
    
    -- Highlight exact position if available
    if mark.col then
      local col_start = string.find(lines[highlight_index], tostring(mark.col))
      if col_start then
        vim.api.nvim_buf_add_highlight(preview_buf, -1, "Error", highlight_index - 1, col_start - 1, col_start)
      end
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