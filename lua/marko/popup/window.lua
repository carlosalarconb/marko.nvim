local M = {}

-- ============================================
-- STATE
-- ============================================
local popup_buf = nil
local popup_win = nil
local shadow_win = nil
local preview_buf = nil
local preview_win = nil

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

function M.get_preview_win()
	return preview_win
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

	local shadow_buffer = vim.api.nvim_create_buf(false, true)
	vim.bo[shadow_buffer].bufhidden = "wipe"

	local s_win = vim.api.nvim_open_win(shadow_buffer, false, {
		relative = "editor",
		width = width,
		height = height,
		row = row + 1,
		col = col + 2,
		style = "minimal",
		focusable = false,
		zindex = 1,
	})

	vim.wo[s_win].winhl = "Normal:Normal"
	vim.wo[s_win].winblend = 80

	return s_win
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

	-- Calculate ideal range centered on the bookmarked line
	local half_range = math.floor(max_lines / 2)
	local ideal_start = center_line - half_range
	local ideal_end = center_line + half_range

	-- Adjust if near the beginning or end of file
	local start_line = math.max(1, ideal_start)
	local end_line = math.min(total_lines, ideal_end)

	-- If we hit the beginning, try to show more lines at the end
	if start_line == 1 and ideal_start < 1 then
		end_line = math.min(total_lines, end_line + (1 - ideal_start))
	end

	-- If we hit the end, try to show more lines at the beginning
	if end_line == total_lines and ideal_end > total_lines then
		start_line = math.max(1, start_line - (ideal_end - total_lines))
	end

	-- Recalculate to ensure we don't exceed bounds
	start_line = math.max(1, start_line)
	end_line = math.min(total_lines, end_line)

	local lines = {}
	for i = start_line, end_line do
		table.insert(lines, {
			num = i,
			text = all_content[i],
		})
	end

	return lines, center_line - start_line + 1
end

-- ============================================
-- UPDATE PREVIEW
-- ============================================
function M.update_preview(mark)
	local config = require("marko.config").get()
	if not config.preview.enabled then
		return
	end

	if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
		return
	end
	if not mark or not mark.filename then
		return
	end

	local file_path = mark.filename
	if vim.fn.filereadable(file_path) ~= 1 then
		return
	end

	local bookmarked_line = mark.line or 1
	local win_config = vim.api.nvim_win_get_config(preview_win)
	local height = (win_config and win_config.height) or config.height
	local lines_to_show = math.max(height - 2, 5)

	local content, highlight_index = read_file_content(file_path, bookmarked_line, lines_to_show)

	if #content == 0 then
		return
	end

	local ns_id = require("marko.config").get_namespace()
	vim.api.nvim_buf_clear_namespace(preview_buf, ns_id, 0, -1)

	vim.bo[preview_buf].modifiable = true
	local lines = {}
	for _, item in ipairs(content) do
		table.insert(lines, string.format("%5d │ %s", item.num, item.text))
	end

	vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
	vim.bo[preview_buf].modifiable = false

	-- Highlight the bookmarked line
	if highlight_index then
		vim.api.nvim_buf_add_highlight(preview_buf, ns_id, "Visual", highlight_index - 1, 0, -1)
	end

	-- Scroll preview window to show the bookmarked line
	if preview_win and vim.api.nvim_win_is_valid(preview_win) and highlight_index then
		vim.api.nvim_win_set_cursor(preview_win, { highlight_index, 0 })
	end
end

-- ============================================
-- CREATE POPUP
-- ============================================
function M.create(marks)
	local config = require("marko.config").get()
	local preview_enabled = config.preview.enabled

	-- Close existing popup if open
	M.close()

	-- Create buffer for left pane
	popup_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[popup_buf].bufhidden = "wipe"
	vim.bo[popup_buf].filetype = "marko-popup"

	-- Calculate window size and position
	local left_width
	local total_width

	if preview_enabled then
		left_width = config.preview.width
		local right_width = config.preview.width
		total_width = left_width + 2 + right_width
	else
		total_width = math.max(config.width, 80)
		left_width = total_width
	end

	local header_lines = 4
	local column_header_lines = 2
	local status_lines = 3
	local marks_lines = math.max(#marks, 1)
	local total_height = header_lines + column_header_lines + marks_lines + status_lines

	local height = config.height
	local row = math.ceil((vim.o.lines - height) / 2)
	local left_col = math.ceil((vim.o.columns - total_width) / 2)

	-- Create shadow window only when preview is disabled
	if not preview_enabled then
		shadow_win = create_shadow(total_width, height, row, left_col)
	end

	-- Create window title
	local mode_text = config.navigation_mode == "direct" and "Direct" or "Popup"
	local window_title = config.title .. "- " .. mode_text .. " "

	-- Create main window (left pane)
	popup_win = vim.api.nvim_open_win(popup_buf, true, {
		relative = "editor",
		width = left_width,
		height = height,
		row = row,
		col = left_col,
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

	-- Create preview window if enabled
	if preview_enabled then
		local right_width = config.preview.width
		local right_col = left_col + left_width + 2

		preview_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[preview_buf].bufhidden = "wipe"
		vim.bo[preview_buf].filetype = "marko-preview"

		preview_win = vim.api.nvim_open_win(preview_buf, false, {
			relative = "editor",
			width = right_width,
			height = height,
			row = row,
			col = right_col,
			border = config.border,
			title = " Preview ",
			title_pos = "center",
			style = "minimal",
			focusable = false,
			zindex = 2,
		})

		vim.wo[preview_win].winhl = winhl
		vim.wo[preview_win].cursorline = true
	end

	return popup_buf, popup_win
end

-- ============================================
-- CLOSE POPUP
-- ============================================
function M.close()
	if preview_win and vim.api.nvim_win_is_valid(preview_win) then
		vim.api.nvim_win_close(preview_win, true)
	end
	if popup_win and vim.api.nvim_win_is_valid(popup_win) then
		vim.api.nvim_win_close(popup_win, true)
	end
	if shadow_win and vim.api.nvim_win_is_valid(shadow_win) then
		vim.api.nvim_win_close(shadow_win, true)
	end
	popup_win = nil
	popup_buf = nil
	shadow_win = nil
	preview_win = nil
	preview_buf = nil
end

return M
