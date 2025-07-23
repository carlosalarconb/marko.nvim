local M = {}

local keymaps_active = false

-- Get all possible mark characters
local function get_mark_chars()
  local marks = {}
  -- Buffer marks a-z
  for i = string.byte('a'), string.byte('z') do
    table.insert(marks, string.char(i))
  end
  -- Global marks A-Z
  for i = string.byte('A'), string.byte('Z') do
    table.insert(marks, string.char(i))
  end
  return marks
end

-- Check if a mark exists and get mark info
local function get_mark_info(mark)
  local marks_module = require("marko.marks")
  local all_marks = marks_module.get_all_marks()
  
  for _, mark_info in ipairs(all_marks) do
    if mark_info.mark == mark then
      return mark_info
    end
  end
  return nil
end

-- Handle direct mark jump
local function handle_mark_jump(mark)
  local mark_info = get_mark_info(mark)
  
  if mark_info then
    local marks_module = require("marko.marks")
    marks_module.goto_mark(mark_info)
  else
    vim.notify("Mark '" .. mark .. "' does not exist", vim.log.levels.WARN, {
      title = "Marko",
      timeout = 1500,
    })
  end
end

-- Setup direct navigation keymaps (no global mappings)
function M.setup_keymaps()
  if keymaps_active then
    return
  end
  
  -- Direct mode doesn't set up global keymaps anymore
  -- All mark jumping happens within the popup buffer
  keymaps_active = true
end

-- Remove direct navigation keymaps
function M.remove_keymaps()
  if not keymaps_active then
    return
  end
  
  -- No global keymaps to remove in the new approach
  keymaps_active = false
end

-- Check if direct mode is active
function M.is_active()
  return keymaps_active
end

return M