local M = {}

-- ============================================
-- GENERATE HEADER
-- ============================================
local function generate_header(marks)
	local icons = require("marko.icons")
	local config = require("marko.config").get()
	local buffer_count = 0
	local global_count = 0

	for _, mark in ipairs(marks) do
		if mark.type == "buffer" then
			buffer_count = buffer_count + 1
		else
			global_count = global_count + 1
		end
	end

	local mode_text = config.navigation_mode == "direct" and "Direct" or "Popup"

	local width
	if config.preview.enabled then
		width = math.min(config.preview.width, 200)  -- Left panel capped at 200
	else
		width = config.width
	end

	local mode_line = string.format("%s%s", string.rep(" ", math.floor((width - #mode_text) / 2)), mode_text)

	local stats = string.format("  %d Global %s %d Buffer", global_count, icons.icons.separator, buffer_count)

	return {
		"",
		stats,
		M.generate_separator(),
	}
end

-- ============================================
-- GENERATE COLUMN HEADERS
-- ============================================
local function generate_column_headers()
	local icons = require("marko.icons")
	local config = require("marko.config").get()

	local col_mark = string.rep(" ", config.columns.mark - 1) .. "M"
	local col_line = string.rep(" ", config.columns.line - 4) .. "Line"
	local col_file = "File"

	local header_line = string.format("  %s %s %s %s %s", col_mark, icons.icons.separator, col_line, icons.icons.separator, col_file)

	-- Truncate to panel width (left panel capped at 200)
	local max_width
	if config.preview.enabled then
		max_width = math.min(config.preview.width, 200)
	else
		max_width = config.width
	end

	if #header_line > max_width then
		header_line = header_line:sub(1, max_width)
	end

	return {
		header_line,
		M.generate_separator(),
	}
end

-- ============================================
-- GENERATE STATUS BAR
-- ============================================
local function generate_status_bar()
	local config = require("marko.config").get()
	local icons = require("marko.icons")

	local status_text = ""
	if config.navigation_mode == "popup" then
		status_text = string.format("  j/k ↕  d %s  Esc/' %s  ; Direct Mode", icons.icons.delete, icons.icons.escape)
	else
		status_text = string.format("  Press mark key to jump  Esc/' %s  ; Popup Mode", icons.icons.escape)
	end

	-- Truncate status text to fit panel width (left panel capped at 200)
	local max_width
	if config.preview.enabled then
		max_width = math.min(config.preview.width, 200)
	else
		max_width = config.width
	end

	local stripped = status_text:gsub("[\128-\255]", "") -- rough strip of wide chars for length calc
	if #stripped > max_width then
		status_text = status_text:sub(1, max_width)
	end

	return {
		M.generate_separator(),
		status_text,
	}
end

-- ============================================
-- GENERATE SEPARATOR
-- ============================================
function M.generate_separator()
	local config = require("marko.config").get()
	local width

	if config.preview.enabled then
		width = math.min(config.preview.width, 200)  -- Left panel capped at 200
	else
		width = config.width
		if width < 80 then
			width = 80
		end
	end

	return string.rep("─", width)
end

-- ============================================
-- POPULATE BUFFER
-- ============================================
function M.populate(bufnr, marks)
	local config = require("marko.config").get()
	local icons = require("marko.icons")
	local lines = {}

	-- Add header
	local header_lines = generate_header(marks)
	for _, line in ipairs(header_lines) do
		table.insert(lines, line)
	end

	-- Add column headers
	local column_header_lines = generate_column_headers()
	for _, line in ipairs(column_header_lines) do
		table.insert(lines, line)
	end

	-- Add marks content
	if #marks == 0 then
		table.insert(lines, "  No marks found")
	else
		for i, mark in ipairs(marks) do
			local formatted_line = "  " .. icons.format_mark_line(mark, config)
			-- Truncate to panel width (left panel capped at 200)
			local max_width
			if config.preview.enabled then
				max_width = math.min(config.preview.width, 200)
			else
				max_width = config.width
			end
			if #formatted_line > max_width then
				formatted_line = formatted_line:sub(1, max_width)
			end
			table.insert(lines, formatted_line)
		end
	end

	-- Add status bar
	local status_lines = generate_status_bar()
	for _, line in ipairs(status_lines) do
		table.insert(lines, line)
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.bo[bufnr].modifiable = false

	-- Store marks data in buffer variable
	local marks_start_line = #header_lines + #column_header_lines
	vim.b[bufnr].marks_data = marks
	vim.b[bufnr].marks_start_line = marks_start_line

	return marks_start_line
end

return M
