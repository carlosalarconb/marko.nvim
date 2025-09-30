local M = {}

-- Modern Unicode icons for different elements
M.icons = {
	-- Mark type icons
	buffer_mark = "󰃉", -- File icon for buffer marks
	global_mark = "󰞕", -- Globe icon for global marks

	-- UI elements
	title = "󰃀", -- Target/bookmark icon
	stats = "󰝰", -- Stats/chart icon

	-- File type icons (simplified set)
	file = "󰈔", -- Generic file
	lua = "", -- Lua
	python = "", -- Python
	javascript = "", -- JavaScript
	typescript = "", -- TypeScript
	json = "", -- JSON
	markdown = "", -- Markdown
	text = "󰈙", -- Text file

	-- Status icons
	separator = "│", -- Clean separator
	arrow_right = "", -- Right arrow
	bullet = "●", -- Bullet point

	-- Navigation hints
	enter = "󰌑", -- Enter key
	delete = "󰆴", -- Delete/trash
	escape = "󱊷", -- Escape
	help = "󰋖", -- Help/question
}

-- Get file type icon based on filename
function M.get_file_icon(filename)
	if not filename or filename == "" then
		return M.icons.file
	end

	local extension = filename:match("%.([^%.]+)$")
	if not extension then
		return M.icons.file
	end

	local ext_lower = extension:lower()

	-- Map extensions to icons
	local icon_map = {
		lua = M.icons.lua,
		py = M.icons.python,
		js = M.icons.javascript,
		jsx = M.icons.javascript,
		ts = M.icons.typescript,
		tsx = M.icons.typescript,
		json = M.icons.json,
		md = M.icons.markdown,
		txt = M.icons.text,
	}

	return icon_map[ext_lower] or M.icons.file
end

-- Get mark type icon
function M.get_mark_icon(mark_type)
	if mark_type == "global" then
		return M.icons.global_mark
	else
		return M.icons.buffer_mark
	end
end

-- Format mark line with icons
function M.format_mark_line(mark, config)
	local file_icon = M.get_file_icon(mark.filename)

	local filename = ""
	if mark.filename then
		filename = vim.fn.fnamemodify(mark.filename, ":~:.")
	elseif mark.type == "buffer" then
		filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
	end

	-- Truncate long filenames - show end of path first
	if #filename > config.columns.filename then
		local max_length = config.columns.filename - 3 -- Account for "..."
		local start_pos = #filename - max_length + 1
		local truncated = filename:sub(start_pos)

		-- Find the first directory separator to avoid cutting in the middle of a directory name
		local first_slash = truncated:find("/")
		if first_slash then
			truncated = truncated:sub(first_slash + 1)
		end

		filename = "..." .. truncated
	end

	local trimmed_text = mark.text:gsub("^%s+", "")
	local preview = trimmed_text:sub(1, 150)
	-- Create formatted line without mark type icon
	return string.format(
		"%s %s %4d %s %s %s",
		mark.mark, -- Mark letter
		M.icons.separator, -- Separator
		mark.line, -- Line number
		M.icons.separator, -- Separator
		filename, -- Filename
		"| " .. preview
	)
end

return M

