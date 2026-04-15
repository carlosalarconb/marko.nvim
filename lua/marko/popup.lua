local M = {}

-- ============================================
-- SUBMODULES
-- ============================================
local window = require("marko.popup.window")
local buffer = require("marko.popup.buffer")
local highlighting = require("marko.popup.highlighting")
local keymaps = require("marko.popup.keymaps")

-- ============================================
-- STATE CHECK
-- ============================================
function M.is_open()
	return window.is_valid()
end

-- ============================================
-- CREATE POPUP
-- ============================================
function M.create_popup()
	local marks = require("marko.marks").get_all_marks()

	-- Create window and get buffer/window handles
	local bufnr, win = window.create(marks)

	-- Populate buffer with marks
	local marks_start_line = buffer.populate(bufnr, marks)

	-- Apply highlighting
	highlighting.apply(bufnr, marks, marks_start_line)

	-- Position cursor on first mark line
	if #marks > 0 then
		vim.api.nvim_win_set_cursor(win, { marks_start_line + 1, 0 })
	end

	-- Set up keymaps
	keymaps.setup(bufnr, function()
		M.close_popup()
	end, function()
		M.create_popup()
	end)
end

-- ============================================
-- CLOSE POPUP
-- ============================================
function M.close_popup()
	window.close()
end

return M
