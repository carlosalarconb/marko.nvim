local M = {}

-- ============================================
-- STATE
-- ============================================
local sidebar_buf = nil
local sidebar_win = nil
local preview_buf = nil
local preview_win = nil

-- ============================================
-- STATE CHECK
-- ============================================
function M.is_open()
	return sidebar_win and vim.api.nvim_win_is_valid(sidebar_win)
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
local function update_preview(mark)
	local config = require("marko.config").get()
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

	-- Set filetype for syntax highlighting
	local filetype = vim.filetype.match({ filename = file_path })
	if filetype then
		vim.bo[preview_buf].filetype = filetype
	end

	vim.bo[preview_buf].modifiable = true
	local lines = {}
	for _, item in ipairs(content) do
		table.insert(lines, item.text)
	end

	vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
	vim.bo[preview_buf].modifiable = false

	-- Add virtual line numbers with actual file line numbers
	for i, item in ipairs(content) do
		vim.api.nvim_buf_set_extmark(preview_buf, ns_id, i - 1, 0, {
			virt_text = { { string.format("%6d ", item.num), "LineNr" } },
			virt_text_pos = "inline",
		})
	end

	-- Highlight the bookmarked line
	if highlight_index then
		vim.api.nvim_buf_add_highlight(preview_buf, ns_id, "Visual", highlight_index - 1, 0, -1)
	end

	-- Scroll preview window to show the bookmarked line
	if preview_win and vim.api.nvim_win_is_valid(preview_win) and highlight_index then
		vim.api.nvim_win_set_cursor(preview_win, { highlight_index, 0 })
	end

	-- Update preview window title to show filename and line range
	if preview_win and vim.api.nvim_win_is_valid(preview_win) and file_path and #content > 0 then
		local filename = vim.fn.fnamemodify(file_path, ":t")
		vim.api.nvim_win_set_config(preview_win, { title = " " .. filename .. " " })
	end
end

-- ============================================
-- GENERATE SIDEBAR CONTENT
-- ============================================
local function generate_content(marks)
	local config = require("marko.config").get()
	local icons = require("marko.icons")
	local lines = {}

	-- Header
	table.insert(lines, " " .. config.title)
	table.insert(lines, string.rep("─", config.sidebar.width - 2))

	-- Marks
	if #marks == 0 then
		table.insert(lines, " No marks found")
	else
		for _, mark in ipairs(marks) do
			local filename = ""
			if mark.filename then
				filename = vim.fn.fnamemodify(mark.filename, ":~:.")
				if #filename > config.sidebar.width - 10 then
					filename = "..." .. filename:sub(-(config.sidebar.width - 13))
				end
			end

			local line = string.format(" %s %s %s", mark.mark, icons.icons.separator, filename)
			table.insert(lines, line)
		end
	end

	-- Footer
	table.insert(lines, string.rep("─", config.sidebar.width - 2))
	table.insert(lines, " q/Esc to close")

	return lines
end

-- ============================================
-- CREATE SIDEBAR
-- ============================================
function M.create()
	local config = require("marko.config").get()
	local marks = require("marko.marks").get_all_marks()

	if not config.sidebar.enabled then
		return
	end

	-- Close existing sidebar
	if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
		M.close()
	end

	-- Create sidebar buffer
	sidebar_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[sidebar_buf].bufhidden = "wipe"
	vim.bo[sidebar_buf].filetype = "marko-sidebar"

	-- Calculate position
	local sidebar_width = config.sidebar.width
	local preview_enabled = config.preview.enabled
	local total_width = sidebar_width + (preview_enabled and config.preview.width + 2 or 0)

	local height = config.height
	local row = math.ceil((vim.o.lines - height) / 2)

	local col
	if config.sidebar.position == "left" then
		col = 0
	else
		col = vim.o.columns - total_width
	end

	-- Create sidebar window
	sidebar_win = vim.api.nvim_open_win(sidebar_buf, true, {
		relative = "editor",
		width = sidebar_width,
		height = height,
		row = row,
		col = col,
		border = config.border,
		style = "minimal",
		focusable = true,
		zindex = 2,
	})

	-- Set window options
	local border_hl = config.navigation_mode == "direct" and "MarkoDirectModeBorder" or "MarkoPopupModeBorder"
	vim.wo[sidebar_win].winhl = string.format("Normal:MarkoNormal,FloatBorder:%s", border_hl)
	vim.wo[sidebar_win].cursorline = true

	-- Create preview window if enabled
	if preview_enabled then
		-- preview_col: skip sidebar border(2) + gap(2), then +1 for preview's own left border to get content area
		local preview_col = col + sidebar_width + 2 + 2 + 1

		preview_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[preview_buf].bufhidden = "wipe"

		preview_win = vim.api.nvim_open_win(preview_buf, false, {
			relative = "editor",
			width = config.preview.width,
			height = height,
			row = row,
			col = preview_col,
			border = config.border,
			title = " Preview ",
			title_pos = "center",
			style = "minimal",
			focusable = false,
			zindex = 2,
		})

		vim.wo[preview_win].winhl = string.format("Normal:MarkoNormal,FloatBorder:%s", border_hl)
		vim.wo[preview_win].wrap = false
		vim.wo[preview_win].linebreak = false
	end

	-- Populate buffer
	local lines = generate_content(marks)
	vim.api.nvim_buf_set_lines(sidebar_buf, 0, -1, false, lines)
	vim.bo[sidebar_buf].modifiable = false

	-- Store marks data
	vim.b[sidebar_buf].marks_data = marks
	vim.b[sidebar_buf].marks_start_line = 2

	-- Apply highlighting
	M.apply_highlighting(marks)

	-- Setup keymaps
	M.setup_keymaps()

	-- Setup CursorMoved autocmd for preview
	if preview_enabled then
		vim.api.nvim_create_autocmd("CursorMoved", {
			buffer = sidebar_buf,
			callback = function()
				local cursor_line = vim.api.nvim_win_get_cursor(sidebar_win)[1]
				local marks_data = vim.b[sidebar_buf].marks_data
				local marks_start_line = vim.b[sidebar_buf].marks_start_line

				local mark_index = cursor_line - marks_start_line
				if marks_data and mark_index >= 1 and mark_index <= #marks_data then
					update_preview(marks_data[mark_index])
				end
			end,
		})
	end

	-- Position cursor
	if #marks > 0 then
		vim.api.nvim_win_set_cursor(sidebar_win, { 3, 0 })
		-- Trigger initial preview
		vim.defer_fn(function()
			update_preview(marks[1])
		end, 10)
	end
end

-- ============================================
-- APPLY HIGHLIGHTING
-- ============================================
function M.apply_highlighting(marks)
	local config = require("marko.config").get()
	local ns_id = require("marko.config").get_namespace()

	vim.api.nvim_buf_clear_namespace(sidebar_buf, ns_id, 0, -1)

	local all_lines = vim.api.nvim_buf_get_lines(sidebar_buf, 0, -1, false)

	for i, line in ipairs(all_lines) do
		local line_idx = i - 1

		-- Highlight separator lines
		if line:match("^─+$") then
			vim.api.nvim_buf_set_extmark(sidebar_buf, ns_id, line_idx, 0, {
				end_col = #line,
				hl_group = "MarkoSeparator",
			})
		end

		-- Highlight marks
		if line:match("^ [%a]$") then
			local mark_char = line:match("^ (%a) ")
			if mark_char then
				local is_global = mark_char:match("[A-Z]") ~= nil
				local hl = is_global and "MarkoGlobalMark" or "MarkoBufferMark"
				vim.api.nvim_buf_set_extmark(sidebar_buf, ns_id, line_idx, 1, {
					end_col = 2,
					hl_group = hl,
				})
			end
		end
	end
end

-- ============================================
-- SETUP KEYMAPS
-- ============================================
function M.setup_keymaps()
	local config = require("marko.config").get()
	local marks_module = require("marko.marks")

	-- Close
	vim.keymap.set("n", "q", function()
		M.close()
	end, { buffer = sidebar_buf, silent = true })

	vim.keymap.set("n", "<Esc>", function()
		M.close()
	end, { buffer = sidebar_buf, silent = true })

	if config.default_keymap then
		vim.keymap.set("n", config.default_keymap, function()
			M.close()
		end, { buffer = sidebar_buf, silent = true })
	end

	-- Jump to mark
	local function jump_to_mark()
		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		local marks_data = vim.b[sidebar_buf].marks_data
		local marks_start_line = vim.b[sidebar_buf].marks_start_line

		local mark_index = cursor_line - marks_start_line

		if marks_data and mark_index >= 1 and mark_index <= #marks_data then
			M.close()
			marks_module.goto_mark(marks_data[mark_index])
		end
	end

	vim.keymap.set("n", "<CR>", jump_to_mark, { buffer = sidebar_buf, silent = true })
	vim.keymap.set("n", config.keymaps.jump, jump_to_mark, { buffer = sidebar_buf, silent = true })

	-- Delete mark
	local function delete_mark()
		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		local marks_data = vim.b[sidebar_buf].marks_data
		local marks_start_line = vim.b[sidebar_buf].marks_start_line

		local mark_index = cursor_line - marks_start_line

		if marks_data and mark_index >= 1 and mark_index <= #marks_data then
			marks_module.delete_mark(marks_data[mark_index])
			vim.defer_fn(function()
				M.create()
			end, 50)
		end
	end

	vim.keymap.set("n", config.keymaps.delete, delete_mark, { buffer = sidebar_buf, silent = true })

	-- Constrain cursor
	local function constrain_cursor()
		local marks_data = vim.b[sidebar_buf].marks_data
		local marks_start_line = vim.b[sidebar_buf].marks_start_line

		if not marks_data or #marks_data == 0 then
			return
		end

		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		local marks_end_line = marks_start_line + #marks_data

		if cursor_line < marks_start_line + 1 then
			vim.api.nvim_win_set_cursor(0, { marks_start_line + 1, 0 })
		elseif cursor_line > marks_end_line then
			vim.api.nvim_win_set_cursor(0, { marks_end_line, 0 })
		end
	end

	vim.keymap.set("n", "j", function()
		vim.cmd("normal! j")
		constrain_cursor()
	end, { buffer = sidebar_buf, silent = true })

	vim.keymap.set("n", "k", function()
		vim.cmd("normal! k")
		constrain_cursor()
	end, { buffer = sidebar_buf, silent = true })
end

-- ============================================
-- CLOSE SIDEBAR
-- ============================================
function M.close()
	if preview_win and vim.api.nvim_win_is_valid(preview_win) then
		vim.api.nvim_win_close(preview_win, true)
	end
	if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
		vim.api.nvim_win_close(sidebar_win, true)
	end
	sidebar_win = nil
	sidebar_buf = nil
	preview_win = nil
	preview_buf = nil
end

return M
