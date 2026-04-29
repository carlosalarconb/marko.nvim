local M = {}

-- ============================================
-- DEFAULT CONFIG
-- ============================================
local default_config = {
  width = 400,
  height = 40,
  border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
  title = " Marko ",
  default_keymap = "'",
  navigation_mode = "popup",
  keymaps = {
    delete = "d",
    jump = "<CR>",
    close = "<Esc>",
  },
  preview = {
    enabled = true,
    width = 340,
    position = "right",
    lines = 40,
    show_line_numbers = true,
  },
  direct_mode = {
		mode_toggle_key = "<leader>mm",
	},
	exclude_marks = { "'", "`", "^", ".", "[", "]", "<", ">" },
	show_all_buffers = true,
	transparency = 0,
	shadow = false,
	separator = "│",
	sidebar = {
		enabled = false,
		width = 220,
		position = "right",
		keymap = "<leader>m",
	},
	virtual_text = {
		enabled = true,
		icon = "●",
		position = "eol",
		format = function(mark, icon)
			return icon .. " " .. mark
		end,
	},
	columns = {
		icon = 3,
		mark = 4,
		line = 6,
		filename = 25,
		separator = 2,
	},
	highlights = {
		normal = { bg = "NONE" },
		border = { fg = "#5C6370", bg = "NONE" },
		title = { fg = "#E5C07B", bold = true },
		cursor_line = { bg = "#3E4451" },
		stats = { fg = "#56B6C2", italic = true },
		separator = { fg = "#5C6370" },
		column_header = { fg = "#C678DD", bold = true },
		status_bar = { fg = "#98C379", italic = true },
		buffer_mark = { fg = "#61AFEF", bold = true },
		global_mark = { fg = "#E06C75", bold = true },
		line_number = { fg = "#ABB2BF" },
		filename = { fg = "#98C379", italic = true },
		content = { fg = "#ABB2BF" },
		icon_buffer = { fg = "#61AFEF" },
		icon_global = { fg = "#E06C75" },
		icon_file = { fg = "#D19A66" },
		popup_mode_border = { fg = "#61AFEF", bg = "NONE" },
		popup_mode_title = { fg = "#61AFEF", bold = true },
		popup_mode_status = { fg = "#61AFEF", italic = true },
		direct_mode_title = { fg = "#E06C75", bold = true },
		direct_mode_border = { fg = "#E06C75", bg = "NONE" },
		direct_mode_status = { fg = "#E06C75", italic = true },
	},
}

-- ============================================
-- STATE
-- ============================================
local config = default_config

-- ============================================
-- HIGHLIGHT GROUPS
-- ============================================
local function setup_highlights()
	local highlights = config.highlights

	local hl_groups = {
		MarkoNormal = highlights.normal,
		MarkoBorder = highlights.border,
		MarkoTitle = highlights.title,
		MarkoCursorLine = highlights.cursor_line,
		MarkoStats = highlights.stats,
		MarkoSeparator = highlights.separator,
		MarkoColumnHeader = highlights.column_header,
		MarkoStatusBar = highlights.status_bar,
		MarkoBufferMark = highlights.buffer_mark,
		MarkoGlobalMark = highlights.global_mark,
		MarkoLineNumber = highlights.line_number,
		MarkoFilename = highlights.filename,
		MarkoContent = highlights.content,
		MarkoIconBuffer = highlights.icon_buffer,
		MarkoIconGlobal = highlights.icon_global,
		MarkoIconFile = highlights.icon_file,
		MarkoPopupModeBorder = highlights.popup_mode_border,
		MarkoPopupModeTitle = highlights.popup_mode_title,
		MarkoPopupModeStatus = highlights.popup_mode_status,
		MarkoDirectModeTitle = highlights.direct_mode_title,
		MarkoDirectModeBorder = highlights.direct_mode_border,
		MarkoDirectModeStatus = highlights.direct_mode_status,
	}

	for group, opts in pairs(hl_groups) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end

-- ============================================
-- NAMESPACE
-- ============================================
local ns_id = vim.api.nvim_create_namespace("marko_highlights")

-- ============================================
-- API
-- ============================================
function M.setup(opts)
	config = vim.tbl_deep_extend("force", default_config, opts or {})
	setup_highlights()
end

function M.get()
	return config
end

function M.get_namespace()
	return ns_id
end

function M.refresh_highlights()
	setup_highlights()
end

return M
