local M = {}

-- ============================================
-- SETUP KEYMAPS
-- ============================================
function M.setup(bufnr, close_callback, refresh_callback)
	local config = require("marko.config").get()
	local marks_module = require("marko.marks")
	local window = require("marko.popup.window")

	-- Helper to set single or multiple keymaps
	local function set_keymaps(keys, func)
		if type(keys) == "table" then
			for _, key in ipairs(keys) do
				vim.keymap.set("n", key, func, { buffer = bufnr, silent = true })
			end
		elseif type(keys) == "string" then
			vim.keymap.set("n", keys, func, { buffer = bufnr, silent = true })
		end
	end

	-- Update live preview based on current cursor position
	local function update_live_preview()
		if not config.preview.enabled then
			return
		end

		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		local marks_data = vim.b[bufnr].marks_data
		local marks_start_line = vim.b[bufnr].marks_start_line

		local mark_index = cursor_line - marks_start_line

		if marks_data and mark_index >= 1 and mark_index <= #marks_data then
			window.update_preview(marks_data[mark_index])
		end
	end

	-- Close popup
	set_keymaps(config.keymaps.close, function()
		close_callback()
	end)

	vim.keymap.set("n", "q", function()
		close_callback()
	end, { buffer = bufnr, silent = true })

	-- Also close with the same key that opens it
	if config.default_keymap then
		vim.keymap.set("n", config.default_keymap, function()
			close_callback()
		end, { buffer = bufnr, silent = true })
	end

	-- Go to mark
	local jump_to_mark = function()
		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		local marks_data = vim.b[bufnr].marks_data
		local marks_start_line = vim.b[bufnr].marks_start_line

		local mark_index = cursor_line - marks_start_line

		if marks_data and mark_index >= 1 and mark_index <= #marks_data then
			close_callback()
			marks_module.goto_mark(marks_data[mark_index])
		end
	end
	set_keymaps(config.keymaps.jump, jump_to_mark)

	-- Delete mark
	local delete_mark = function()
		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		local marks_data = vim.b[bufnr].marks_data
		local marks_start_line = vim.b[bufnr].marks_start_line

		local mark_index = cursor_line - marks_start_line

		if marks_data and mark_index >= 1 and mark_index <= #marks_data then
			marks_module.delete_mark(marks_data[mark_index])
			vim.defer_fn(function()
				refresh_callback()
			end, 50)
		end
	end
	set_keymaps(config.keymaps.delete, delete_mark)

	-- Constrain cursor movement to marks section only
	local function constrain_cursor()
		local marks_data = vim.b[bufnr].marks_data
		local marks_start_line = vim.b[bufnr].marks_start_line

		if not marks_data or #marks_data == 0 then
			return
		end

		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		local marks_end_line = marks_start_line + #marks_data

		local first_mark_line = marks_start_line + 1
		if cursor_line < first_mark_line then
			vim.api.nvim_win_set_cursor(0, { first_mark_line, 0 })
		elseif cursor_line > marks_end_line then
			vim.api.nvim_win_set_cursor(0, { marks_end_line, 0 })
		end
	end

	-- Override j/k movement to constrain cursor and update preview
	vim.keymap.set("n", "j", function()
		vim.cmd("normal! j")
		constrain_cursor()
	end, { buffer = bufnr, silent = true })

	vim.keymap.set("n", "k", function()
		vim.cmd("normal! k")
		constrain_cursor()
	end, { buffer = bufnr, silent = true })

	-- Override down/up arrow keys as well
	vim.keymap.set("n", "<Down>", function()
		vim.cmd("normal! j")
		constrain_cursor()
	end, { buffer = bufnr, silent = true })

	vim.keymap.set("n", "<Up>", function()
		vim.cmd("normal! k")
		constrain_cursor()
	end, { buffer = bufnr, silent = true })

	-- Set up CursorMoved autocmd for live preview updates
	if config.preview.enabled then
		local augroup = vim.api.nvim_create_augroup("MarkoPopupPreview", { clear = true })
		vim.api.nvim_create_autocmd("CursorMoved", {
			group = augroup,
			buffer = bufnr,
			callback = function()
				update_live_preview()
			end,
		})
	end

	-- Add mode toggle keymap in popup
	vim.keymap.set("n", ";", function()
		require("marko").toggle_navigation_mode()
		vim.defer_fn(function()
			if require("marko.popup").is_open() then
				close_callback()
				vim.defer_fn(function()
					require("marko.popup").create_popup()
				end, 20)
			end
		end, 50)
	end, { buffer = bufnr, silent = true, desc = "Toggle navigation mode" })

	-- Set up direct mode mark jumping
	if config.navigation_mode == "direct" then
		for i = string.byte("a"), string.byte("z") do
			local mark = string.char(i)
			vim.keymap.set("n", mark, function()
				local marks_data = vim.b[bufnr].marks_data

				if marks_data then
					for _, mark_info in ipairs(marks_data) do
						if mark_info.mark == mark then
							close_callback()
							marks_module.goto_mark(mark_info)
							return
						end
					end
				end

				vim.notify("Mark '" .. mark .. "' does not exist", vim.log.levels.WARN, {
					title = "Marko",
					timeout = 1500,
				})
			end, { buffer = bufnr, silent = true, desc = "Jump to mark " .. mark })
		end

		for i = string.byte("A"), string.byte("Z") do
			local mark = string.char(i)
			vim.keymap.set("n", mark, function()
				local marks_data = vim.b[bufnr].marks_data

				if marks_data then
					for _, mark_info in ipairs(marks_data) do
						if mark_info.mark == mark then
							close_callback()
							marks_module.goto_mark(mark_info)
							return
						end
					end
				end

				vim.notify("Mark '" .. mark .. "' does not exist", vim.log.levels.WARN, {
					title = "Marko",
					timeout = 1500,
				})
			end, { buffer = bufnr, silent = true, desc = "Jump to mark " .. mark })
		end
	end
end

return M
