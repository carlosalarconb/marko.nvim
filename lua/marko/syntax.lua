local M = {}

-- Define syntax patterns for the marko-popup filetype
function M.setup_syntax()
	-- Clear any existing syntax
	vim.cmd("syntax clear")

	-- Define syntax regions and matches
	vim.cmd([[
    " Icons at the beginning of lines
    syntax match MarkoIcon /^[󰓹󰊄]/
    
    " Separators
    syntax match MarkoSeparator /│/
    
    " Mark characters (single letters)
    syntax match MarkoBufferMark /\s[a-z]\s/ contained
    syntax match MarkoGlobalMark /\s[A-Z]\s/ contained
    
    " Line numbers
    syntax match MarkoLineNumber /\s\+\d\+\s/
    
    " File icons and names
    syntax match MarkoFileIcon /󰈔/
    syntax match MarkoLineIcon /󰘕/
    
    " Filenames (after file icon)
    syntax match MarkoFilename /󰈔\s\+\zs[^│]\+\ze\s*│/
    
    " Content (everything after the last separator)
    syntax match MarkoContent /│\s*\zs.*$/
    
    " Special case for "No marks found"
    syntax match MarkoNoMarks /^No marks found$/
  ]])

	-- Link syntax groups to highlight groups
	vim.cmd([[
    highlight default link MarkoIcon MarkoIcon
    highlight default link MarkoSeparator MarkoSeparator
    highlight default link MarkoBufferMark MarkoBufferMark
    highlight default link MarkoGlobalMark MarkoGlobalMark
    highlight default link MarkoLineNumber MarkoLineNumber
    highlight default link MarkoFileIcon MarkoIcon
    highlight default link MarkoLineIcon MarkoIcon
    highlight default link MarkoFilename MarkoFilename
    highlight default link MarkoContent MarkoContent
    highlight default link MarkoNoMarks MarkoContent
  ]])
end

-- Setup filetype detection
function M.setup_filetype()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "marko-popup",
		callback = function()
			M.setup_syntax()

			-- Additional buffer-local settings
			vim.opt_local.wrap = false
			vim.opt_local.cursorline = true
			vim.opt_local.number = false
			vim.opt_local.relativenumber = false
			vim.opt_local.signcolumn = "no"
		end,
		group = vim.api.nvim_create_augroup("MarkoSyntax", { clear = true }),
	})
end

return M

