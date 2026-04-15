local M = {}

-- ============================================
-- SETUP
-- ============================================
function M.setup(opts)
	require("marko.config").setup(opts)
	require("marko.syntax").setup_filetype()

	local config = require("marko.config").get()
	if config.virtual_text then
		require("marko.virtual").setup(config.virtual_text)
		require("marko.virtual").setup_autocmds()
	end

	if config.navigation_mode == "direct" then
		require("marko.direct").setup_keymaps()
	end

	if config.default_keymap then
		vim.keymap.set("n", config.default_keymap, function()
			M.toggle_marks()
		end, { desc = "Toggle marks popup" })
	end

	-- Setup sidebar keymap if enabled
	local config = require("marko.config").get()
	if config.sidebar and config.sidebar.enabled then
		local sidebar_key = config.sidebar.keymap or "<leader>m"
		vim.keymap.set("n", sidebar_key, function()
			M.toggle_sidebar()
		end, { desc = "Toggle marks sidebar" })
	end

	if config.direct_mode.mode_toggle_key then
		vim.keymap.set("n", config.direct_mode.mode_toggle_key, function()
			M.toggle_navigation_mode()
		end, { desc = "Toggle navigation mode (popup/direct)" })
	end

	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = function()
			require("marko.config").refresh_highlights()
		end,
		group = vim.api.nvim_create_augroup("MarkoColorScheme", { clear = true }),
	})
end

-- ============================================
-- CORE API
-- ============================================
function M.toggle_marks()
	local popup = require("marko.popup")
	if popup.is_open() then
		popup.close_popup()
	else
		popup.create_popup()
	end
end

function M.show_marks()
	local popup = require("marko.popup")
	popup.create_popup()
end

-- ============================================
-- SIDEBAR
-- ============================================
function M.toggle_sidebar()
	local sidebar = require("marko.popup.sidebar")
	if sidebar.is_open() then
		sidebar.close()
	else
		sidebar.create()
	end
end

function M.open_sidebar()
	local sidebar = require("marko.popup.sidebar")
	sidebar.create()
end

function M.close_sidebar()
	local sidebar = require("marko.popup.sidebar")
	sidebar.close()
end

-- ============================================
-- NAVIGATION MODE
-- ============================================
function M.toggle_navigation_mode()
	local config = require("marko.config").get()
	local direct = require("marko.direct")

	if config.navigation_mode == "popup" then
		config.navigation_mode = "direct"
		direct.remove_keymaps()
		vim.defer_fn(function()
			direct.setup_keymaps()
		end, 10)
		vim.notify("Switched to direct navigation mode", vim.log.levels.INFO, {
			title = "Marko",
			timeout = 2000,
		})
	else
		config.navigation_mode = "popup"
		direct.remove_keymaps()
		vim.notify("Switched to popup navigation mode", vim.log.levels.INFO, {
			title = "Marko",
			timeout = 2000,
		})
	end
end

function M.enable_direct_mode()
	local config = require("marko.config").get()
	local direct = require("marko.direct")

	if config.navigation_mode ~= "direct" then
		config.navigation_mode = "direct"
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

function M.enable_popup_mode()
	local config = require("marko.config").get()
	local direct = require("marko.direct")

	if config.navigation_mode ~= "popup" then
		config.navigation_mode = "popup"
		direct.remove_keymaps()
		vim.notify("Popup navigation mode enabled", vim.log.levels.INFO, {
			title = "Marko",
			timeout = 2000,
		})
	end
end

function M.get_navigation_mode()
	local config = require("marko.config").get()
	return config.navigation_mode
end

-- ============================================
-- VIRTUAL TEXT
-- ============================================
function M.toggle_virtual_marks()
	require("marko.virtual").toggle()
end

function M.refresh_virtual_marks()
	require("marko.virtual").refresh_buffer_marks()
end

-- ============================================
-- UTILITIES
-- ============================================
function M.debug_marks()
	local marks_module = require("marko.marks")
	marks_module.debug_marks()
end

function M.refresh_highlights()
	require("marko.config").refresh_highlights()
end

return M
