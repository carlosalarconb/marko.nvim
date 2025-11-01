# marko.nvim

**** IMPORTANT ****: THIS IS A FORK 

A modern Neovim plugin for enhanced mark management with a beautiful popup interface and dual navigation modes.

## Demo
This is the original version video. So, you can see some differences. A new video will be uploaded.

https://github.com/user-attachments/assets/ed8e6942-fbd0-44d0-8f35-fcb1c9cdb6fb

## Features

- **Beautiful popup interface** with clean, modern UI for browsing marks
- **Dual navigation modes**: Traditional popup navigation or direct mark jumping
- **Visual mode indicators** with color-coded borders (blue for popup mode, red for direct mode)
- **Mark type support** for both buffer marks (a-z) and global marks (A-Z)
- **Line preview** showing the actual content at each mark location
- **Easy mark deletion** with single key press in popup mode
- **Virtual text indicators** showing marks directly in your code
- **Highly configurable** appearance and keybindings
- **Responsive design** that adapts to your terminal size

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'carlosalarconb/marko.nvim',
  config = function()
    require('marko').setup({
      width = 100,
      height = 100,
      border = "rounded",
      title = " Marks ",
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'carlosalarconb/marko.nvim',
  config = function()
    require('marko').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'carlosalarconb/marko.nvim'
```

## Usage

### Basic Usage

1. **Set marks** in your files:
   ```vim
   ma    " Set buffer mark 'a'
   mA    " Set global mark 'A'
   ```

2. **Open the marks popup**:
   ```vim
   :Marko
   ```
   Or use the default keymap: `"`

3. **Navigate in the popup**:
   - `j/k` - Navigate marks
   - `Enter` - Jump to mark
   - `d` - Delete mark
   - `;` - Switch to direct mode
   - `q` or `Esc` - Close popup

### Direct Navigation Mode

Direct mode allows instant mark jumping without cursor navigation. The popup displays with a red border to indicate direct mode is active.

1. **Enable direct mode**:
   - Press `;` in the popup, or
   - Use command: `:MarkoDirectMode`, or 
   - Use the configured toggle keymap

2. **Navigate directly** (popup must remain open):
   - Press any mark letter (`a`, `b`, `c`, etc.) to jump instantly to that mark
   - `;` - Switch back to popup mode (blue border)
   - `'` - Close popup and return to normal file navigation
   - Note: Mark deletion is only available in popup mode

### Mark Types

- **Buffer marks (a-z)**: Local to the current buffer, lost when buffer is closed
- **Global marks (A-Z)**: Persist across files and vim sessions

### Virtual Text

When enabled, marks are displayed as virtual text in your code:
- Set a mark with `ma`, `mB`, etc. and see the indicator appear immediately
- Virtual text shows both buffer marks (blue) and global marks (red)
- Toggle virtual text on/off with `:MarkoToggleVirtual`

## Configuration

```lua
require('marko').setup({
  -- Popup window dimensions
  width = 100,
  height = 100,
  
  -- Border style: 'rounded', 'single', 'double', 'solid', 'shadow'
  border = "rounded",
  
  -- Popup title
  title = " Marks ",
  
  -- Default keymap to open popup (set to false to disable)
  default_keymap = '"',
  
  -- Navigation mode: "popup" (default) or "direct" (jump directly to marks)
  navigation_mode = "popup",
  
  -- Key mappings within popup
  -- Can be a single key (string) or multiple keys (table of strings)
  keymaps = {
    delete = "d",
    goto = { "<CR>", "o" }, -- Example of multiple keys
    close = { "<Esc>", "q" },
  },
  
  -- Direct mode configuration
  direct_mode = {
    mode_toggle_key = "<leader>mm", -- Key to toggle modes
  },
  
  -- Show marks from all buffers or just current buffer
  show_all_buffers = false,
  
  -- Exclude certain marks from display
  exclude_marks = { "'", "`", "^", ".", "[", "]", "<", ">" },
  
  -- Virtual text configuration
  virtual_text = {
    enabled = true,        -- Enable virtual text marks
    icon = "●",           -- Icon to display
    hl_group = "Comment", -- Highlight group
    position = "eol",     -- Position: "eol" or "overlay"
  },
})
```

## Customization

### Custom Keymaps

```lua
-- Disable default keymap and set your own
require('marko').setup({
  default_keymap = false,  -- Disable default ""
})

-- Set custom keymap
vim.keymap.set('n', '"', function()
  require('marko').show_marks()
end, { desc = 'Show marks popup' })

-- Or use leader key
vim.keymap.set('n', '<leader>mm', function()
  require('marko').show_marks()
end, { desc = 'Show marks popup' })
```

### Styling

The plugin respects your colorscheme. You can customize the appearance using highlight groups:

```lua
-- Example customization
vim.cmd([[
  highlight link MarksPopupBorder FloatBorder
  highlight link MarksPopupTitle Title
]])
```

## Commands

| Command | Description |
|---------|-------------|
| `:Marko` | Open the marks popup |
| `:MarkoToggleVirtual` | Toggle virtual text marks on/off |
| `:MarkoToggleMode` | Toggle between popup and direct navigation modes |
| `:MarkoDirectMode` | Enable direct navigation mode |
| `:MarkoPopupMode` | Enable popup navigation mode |

## Mark Quick Reference

| Mark | Type | Scope | Persistence |
|------|------|-------|-------------|
| `a-z` | Buffer | Current buffer only | Lost when buffer closes |
| `A-Z` | Global | Across all files | Saved in shada file |

## Contributing

Contributions are welcome! Please feel free to:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Related Projects

- [vim-signature](https://github.com/kshenoy/vim-signature) - Mark visualization
- [marks.nvim](https://github.com/chentoast/marks.nvim) - Alternative marks plugin

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built for the Neovim community
- Inspired by vim's built-in marks system  
- Uses Neovim's modern Lua API
