local M = {}

-- ============================================
-- STATE
-- ============================================
local popup_buf = nil
local popup_win = nil
local shadow_win = nil

-- ============================================
-- WINDOW STATE
-- ============================================
function M.get_buf()
	return popup_buf
end

function M.get_win()
	return popup_win
end

function M.is_valid()
	return popup_win and vim.api.nvim_win_is_valid(popup_win)
end

-- ============================================
-- UTILITIES
-- ============================================
local function generate_repeater_line()
	local config = require("marko.config").get()
	local width = config.width

	if width < 80 then
		width = 80
	end

	return string.rep("─", width)
end

-- ============================================
-- SHADOW WINDOW
-- ============================================
local function create_shadow(width, height, row, col)
	if not require("marko.config").get().shadow then
		return nil
	end

	local shadow_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[shadow_buf].bufhidden = "wipe"

	local shadow_win = vim.api.nvim_open_win(shadow_buf, false, {
		relative = "editor",
		width = width,
		height = height,
		row = row + 1,
		col = col + 2,
		style = "minimal",
		focusable = false,
		zindex = 1,
	})

	vim.wo[shadow_win].winhl = "Normal:Normal"
	vim.wo[shadow_win].winblend = 80

	return shadow_win
end

-- ============================================
-- CREATE POPUP
-- ============================================
function M.create(marks)
	local config = require("marko.config").get()

	-- Close existing popup if open
	if popup_win and vim.api.nvim_win_is_valid(popup_win) then
		vim.api.nvim_win_close(popup_win, true)
	end
	if shadow_win and vim.api.nvim_win_is_valid(shadow_win) then
		vim.api.nvim_win_close(shadow_win, true)
	end

	-- Create buffer
	popup_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[popup_buf].bufhidden = "wipe"
	vim.bo[popup_buf].filetype = "marko-popup"

	-- Calculate window size and position
	local width = math.max(config.width, 80)

	local header_lines = 4
	local column_header_lines = 2
	local status_lines = 3
	local marks_lines = math.max(#marks, 1)
	local total_height = header_lines + column_header_lines + marks_lines + status_lines

	local height = math.min(config.height, total_height)
	local row = math.ceil((vim.o.lines - height) / 2)
	local col = math.ceil((vim.o.columns - width) / 2)

	-- Create shadow window first (if enabled)
	shadow_win = create_shadow(width, height, row, col)

	-- Create window title
	local mode_text = config.navigation_mode == "direct" and "Direct" or "Popup"
	local window_title = config.title .. "- " .. mode_text .. " "

	-- Create main window
	popup_win = vim.api.nvim_open_win(popup_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = config.border,
		title = window_title,
		title_pos = "center",
		style = "minimal",
		zindex = 2,
	})

	-- Set window options with custom highlights based on mode
	local border_hl = config.navigation_mode == "direct" and "MarkoDirectModeBorder" or "MarkoPopupModeBorder"
	local winhl = string.format("Normal:MarkoNormal,FloatBorder:%s,CursorLine:MarkoCursorLine", border_hl)
	vim.wo[popup_win].winhl = winhl
	vim.wo[popup_win].winhighlight = winhl

	-- Set transparency if configured
	if config.transparency > 0 then
		vim.wo[popup_win].winblend = config.transparency
	end

	-- Enable cursor line highlighting
	vim.wo[popup_win].cursorline = true

	return popup_buf, popup_win
end

-- ============================================
-- CLOSE POPUP
-- ============================================
function M.close()
	if popup_win and vim.api.nvim_win_is_valid(popup_win) then
		vim.api.nvim_win_close(popup_win, true)
	end
	if shadow_win and vim.api.nvim_win_is_valid(shadow_win) then
		vim.api.nvim_win_close(shadow_win, true)
	end
	popup_win = nil
	popup_buf = nil
	shadow_win = nil
end

return M
