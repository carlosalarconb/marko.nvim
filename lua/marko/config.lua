local M = {}

local default_config = {
  width = 90,   -- Wider for new layout with icons
  height = 25,  -- More reasonable default height
  border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },  -- Custom rounded border
  title = " Marko ",
  -- Default keymap to open popup (set to false to disable)
  default_keymap = "'",
  -- Navigation mode: "popup" (current) or "direct" (jump directly to marks)
  navigation_mode = "popup",
  keymaps = {
    delete = "d",
    goto = "<CR>",
    close = "<Esc>",
  },
  -- Direct mode configuration
  direct_mode = {
    -- Key to toggle between popup and direct modes
    mode_toggle_key = "<leader>mm",
  },
  exclude_marks = { "'", "`", "^", ".", "[", "]", "<", ">" },
  -- Show buffer marks from all buffers or just current buffer
  show_all_buffers = true,

  -- Visual styling options
  transparency = 0,  -- 0-100, window background transparency
  shadow = false,    -- Drop shadow effect

  -- Separator character
  separator = "│",   -- Column separator

  -- Virtual text marks configuration
  virtual_text = {
    enabled = true,        -- Show virtual text marks in buffers
    icon = "●",           -- Icon to show next to mark
    position = "eol",     -- "eol" (end of line) or "overlay"
    format = function(mark, icon)
      return icon .. " " .. mark
    end
  },

  -- Column widths for better alignment
  columns = {
    icon = 3,
    mark = 4,
    line = 6,
    filename = 25,
    separator = 2
  },

  -- Custom highlight groups (users can override these)
  highlights = {
    -- Window highlights
    normal = { bg = "NONE" },                       -- Transparent background
    border = { fg = "#5C6370", bg = "NONE" },       -- Gray border with transparent bg
    title = { fg = "#E5C07B", bold = true },        -- Yellow/gold for title
    cursor_line = { bg = "#3E4451" },

    -- Header and structure highlights
    stats = { fg = "#56B6C2", italic = true },      -- Cyan for stats
    separator = { fg = "#5C6370" },                 -- Dark gray for separators
    column_header = { fg = "#C678DD", bold = true }, -- Purple for column headers
    status_bar = { fg = "#98C379", italic = true }, -- Green for status bar

    -- Content highlights
    buffer_mark = { fg = "#61AFEF", bold = true },  -- Blue for buffer marks
    global_mark = { fg = "#E06C75", bold = true },  -- Red for global marks
    line_number = { fg = "#ABB2BF" },               -- Gray for line numbers
    filename = { fg = "#98C379", italic = true },   -- Green for filenames
    content = { fg = "#ABB2BF" },                   -- Gray for content

    -- Icon highlights
    icon_buffer = { fg = "#61AFEF" },               -- Blue for buffer icons
    icon_global = { fg = "#E06C75" },               -- Red for global icons
    icon_file = { fg = "#D19A66" },                 -- Orange for file icons

    -- Mode-specific highlights
    popup_mode_border = { fg = "#61AFEF", bg = "NONE" },                   -- Blue border in popup mode
    popup_mode_title = { fg = "#61AFEF", bold = true },                    -- Blue title in popup mode  
    popup_mode_status = { fg = "#61AFEF", italic = true },                 -- Blue status in popup mode

    direct_mode_title = { fg = "#E06C75", bold = true },                   -- Red for direct mode title
    direct_mode_border = { fg = "#E06C75", bg = "NONE" },                  -- Red border in direct mode
    direct_mode_status = { fg = "#E06C75", italic = true },                -- Red status in direct mode
  }
}

local config = default_config

-- Setup highlight groups
local function setup_highlights()
  local highlights = config.highlights

  -- Define all custom highlight groups
  local hl_groups = {
    -- Window highlights
    MarkoNormal = highlights.normal,
    MarkoBorder = highlights.border,
    MarkoTitle = highlights.title,
    MarkoCursorLine = highlights.cursor_line,

    -- Header and structure highlights
    MarkoStats = highlights.stats,
    MarkoSeparator = highlights.separator,
    MarkoColumnHeader = highlights.column_header,
    MarkoStatusBar = highlights.status_bar,

    -- Content highlights
    MarkoBufferMark = highlights.buffer_mark,
    MarkoGlobalMark = highlights.global_mark,
    MarkoLineNumber = highlights.line_number,
    MarkoFilename = highlights.filename,
    MarkoContent = highlights.content,

    -- Icon highlights
    MarkoIconBuffer = highlights.icon_buffer,
    MarkoIconGlobal = highlights.icon_global,
    MarkoIconFile = highlights.icon_file,

    -- Mode-specific highlights
    MarkoPopupModeBorder = highlights.popup_mode_border,
    MarkoPopupModeTitle = highlights.popup_mode_title,
    MarkoPopupModeStatus = highlights.popup_mode_status,

    MarkoDirectModeTitle = highlights.direct_mode_title,
    MarkoDirectModeBorder = highlights.direct_mode_border,
    MarkoDirectModeStatus = highlights.direct_mode_status,
  }

  -- Apply highlight groups
  for group, opts in pairs(hl_groups) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

-- Create namespace for extmarks
local ns_id = vim.api.nvim_create_namespace("marko_highlights")

function M.setup(opts)
  config = vim.tbl_deep_extend("force", default_config, opts or {})

  -- Setup highlights after config is merged
  setup_highlights()
end

function M.get()
  return config
end

function M.get_namespace()
  return ns_id
end

-- Function to refresh highlights (useful for theme changes)
function M.refresh_highlights()
  setup_highlights()
end

return M
