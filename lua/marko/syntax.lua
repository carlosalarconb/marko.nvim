local M = {}

-- ============================================
-- SYNTAX DEFINITION
-- ============================================
function M.setup_syntax()
	vim.cmd("syntax clear")

	vim.cmd([[
    syntax match MarkoIcon /^[󰓹󰊄]/
    syntax match MarkoSeparator /│/
    syntax match MarkoBufferMark /\s[a-z]\s/ contained
    syntax match MarkoGlobalMark /\s[A-Z]\s/ contained
    syntax match MarkoLineNumber /\s\+\d\+\s/
    syntax match MarkoFileIcon /󰈔/
    syntax match MarkoLineIcon /󰘕/
    syntax match MarkoFilename /󰈔\s\+\zs[^│]\+\ze\s*│/
    syntax match MarkoContent /│\s*\zs.*$/
    syntax match MarkoNoMarks /^No marks found$/
  ]])

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

-- ============================================
-- FILETYPE
-- ============================================
function M.setup_filetype()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "marko-popup",
		callback = function()
			M.setup_syntax()

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
