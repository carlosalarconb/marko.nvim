local M = {}

-- ============================================
-- STATE
-- ============================================
local sidebar_buf = nil
local sidebar_win = nil

-- ============================================
-- STATE CHECK
-- ============================================
function M.is_open()
	return sidebar_win and vim.api.nvim_win_is_valid(sidebar_win)
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
		vim.api.nvim_win_close(sidebar_win, true)
	end

	-- Create buffer
	sidebar_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[sidebar_buf].bufhidden = "wipe"
	vim.bo[sidebar_buf].filetype = "marko-sidebar"

	-- Calculate position
	local width = config.sidebar.width
	local height = math.min(config.height, #marks + 6)
	local row = math.ceil((vim.o.lines - height) / 2)

	local col
	if config.sidebar.position == "left" then
		col = 0
	else
		col = vim.o.columns - width
	end

	-- Create window
	sidebar_win = vim.api.nvim_open_win(sidebar_buf, true, {
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
	local border_hl = config.navigation_mode == "direct" and "MarkoDirectModeBorder" or "MarkoPopupModeBorder"
	vim.wo[sidebar_win].winhl = string.format("Normal:MarkoNormal,FloatBorder:%s", border_hl)
	vim.wo[sidebar_win].cursorline = true

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

	-- Position cursor
	if #marks > 0 then
		vim.api.nvim_win_set_cursor(sidebar_win, { 3, 0 })
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
	if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
		vim.api.nvim_win_close(sidebar_win, true)
	end
	sidebar_win = nil
	sidebar_buf = nil
end

return M
