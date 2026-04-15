local M = {}

-- ============================================
-- ICONS
-- ============================================
M.icons = {
	buffer_mark = "󰃉",
	global_mark = "󰞕",
	title = "󰃀",
	stats = "󰝰",
	file = "󰈔",
	lua = "",
	python = "",
	javascript = "",
	typescript = "",
	json = "",
	markdown = "",
	text = "󰈙",
	separator = "│",
	arrow_right = "",
	bullet = "●",
	enter = "󰌑",
	delete = "󰆴",
	escape = "󱊷",
	help = "󰋖",
}

-- ============================================
-- FILE ICONS
-- ============================================
function M.get_file_icon(filename)
	if not filename or filename == "" then
		return M.icons.file
	end

	local extension = filename:match("%.([^%.]+)$")
	if not extension then
		return M.icons.file
	end

	local ext_lower = extension:lower()

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

-- ============================================
-- MARK ICONS
-- ============================================
function M.get_mark_icon(mark_type)
	if mark_type == "global" then
		return M.icons.global_mark
	else
		return M.icons.buffer_mark
	end
end

-- ============================================
-- FORMATTING
-- ============================================
function M.format_mark_line(mark, config)
	local file_icon = M.get_file_icon(mark.filename)

	local filename = ""
	if mark.filename then
		filename = vim.fn.fnamemodify(mark.filename, ":~:.")
	elseif mark.type == "buffer" then
		filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
	end

	if #filename > config.columns.filename then
		local max_length = config.columns.filename - 3
		local start_pos = #filename - max_length + 1
		local truncated = filename:sub(start_pos)

		local first_slash = truncated:find("/")
		if first_slash then
			truncated = truncated:sub(first_slash + 1)
		end

		filename = "..." .. truncated
	end

	local trimmed_text = mark.text:gsub("^%s+", "")
	local preview = trimmed_text:sub(1, 150)

	return string.format(
		"%s %s %4d %s %s %s",
		mark.mark,
		M.icons.separator,
		mark.line,
		M.icons.separator,
		filename,
		"| " .. preview
	)
end

return M
