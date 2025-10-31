local M = {}

-- Setup function for user configuration
function M.setup(opts)
	-- Setup configuration and highlights
	require("marko.config").setup(opts)

	-- Setup syntax highlighting for the popup filetype
	require("marko.syntax").setup_filetype()

	-- Setup virtual text marks
	local config = require("marko.config").get()
	if config.virtual_text then
		require("marko.virtual").setup(config.virtual_text)
		require("marko.virtual").setup_autocmds()
	end

	-- Setup navigation mode
	if config.navigation_mode == "direct" then
		require("marko.direct").setup_keymaps()
	end

	-- Setup default keymap if enabled (always opens popup for mode selection)
	if config.default_keymap then
		vim.keymap.set("n", config.default_keymap, function()
			M.toggle_marks()
		end, { desc = "Toggle marks popup" })
	end

	-- Setup mode toggle keymap
	if config.direct_mode.mode_toggle_key then
		vim.keymap.set("n", config.direct_mode.mode_toggle_key, function()
			M.toggle_navigation_mode()
		end, { desc = "Toggle navigation mode (popup/direct)" })
	end

	-- Setup autocommands for theme changes
	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = function()
			require("marko.config").refresh_highlights()
		end,
		group = vim.api.nvim_create_augroup("MarkoColorScheme", { clear = true }),
	})
end

-- Main function to toggle marks popup
function M.toggle_marks()
	local popup = require("marko.popup")
	if popup.is_open() then
		popup.close_popup()
	else
		popup.create_popup()
	end
end

-- Main function to show marks popup (kept for compatibility)
function M.show_marks()
	local popup = require("marko.popup")
	popup.create_popup()
end

-- Debug function to check marks
function M.debug_marks()
	local marks_module = require("marko.marks")
	marks_module.debug_marks()
end

-- Function to refresh highlights (useful for theme changes)
function M.refresh_highlights()
	require("marko.config").refresh_highlights()
end

-- Toggle virtual text marks on/off
function M.toggle_virtual_marks()
	require("marko.virtual").toggle()
end

-- Refresh virtual marks in current buffer
function M.refresh_virtual_marks()
	require("marko.virtual").refresh_buffer_marks()
end

-- Toggle between popup and direct navigation modes
function M.toggle_navigation_mode()
	local config = require("marko.config").get()
	local direct = require("marko.direct")

	if config.navigation_mode == "popup" then
		-- Switch to direct mode
		config.navigation_mode = "direct"
		-- Force cleanup first, then setup
		direct.remove_keymaps()
		vim.defer_fn(function()
			direct.setup_keymaps()
		end, 10)
		vim.notify("Switched to direct navigation mode", vim.log.levels.INFO, {
			title = "Marko",
			timeout = 2000,
		})
	else
		-- Switch to popup mode
		config.navigation_mode = "popup"
		-- Force cleanup of direct mode keymaps
		direct.remove_keymaps()
		vim.notify("Switched to popup navigation mode", vim.log.levels.INFO, {
			title = "Marko",
			timeout = 2000,
		})
	end
end

-- Force enable direct mode
function M.enable_direct_mode()
	local config = require("marko.config").get()
	local direct = require("marko.direct")

	if config.navigation_mode ~= "direct" then
		config.navigation_mode = "direct"
		-- Force cleanup first, then setup
		direct.remove_keymaps()
		vim.defer_fn(function()
			direct.setup_keymaps()
		end, 10)
		vim.notify("Direct navigation mode enabled", vim.log.levels.INFO, {
			title = "Marko",
			timeout = 2000,
		})
	end
end

-- Force enable popup mode
function M.enable_popup_mode()
	local config = require("marko.config").get()
	local direct = require("marko.direct")

	if config.navigation_mode ~= "popup" then
		config.navigation_mode = "popup"
		-- Force cleanup of direct mode keymaps
		direct.remove_keymaps()
		vim.notify("Popup navigation mode enabled", vim.log.levels.INFO, {
			title = "Marko",
			timeout = 2000,
		})
	end
end

-- Get current navigation mode
function M.get_navigation_mode()
	local config = require("marko.config").get()
	return config.navigation_mode
end

return M
