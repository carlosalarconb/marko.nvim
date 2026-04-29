local M = {}

-- ============================================
-- APPLY HIGHLIGHTING
-- ============================================
function M.apply(bufnr, marks, marks_start_line)
	local config = require("marko.config").get()
	local ns_id = require("marko.config").get_namespace()

	-- Clear existing highlights
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	-- Highlight header sections
	local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	-- Highlight title and stats in header
	for i, line in ipairs(all_lines) do
		local line_idx = i - 1

		-- Highlight mode indicator line with border color
		if line:match("^%s*Popup%s*$") or line:match("^%s*Direct%s*$") then
			local mode_hl = config.navigation_mode == "direct" and "MarkoDirectModeBorder" or "MarkoPopupModeBorder"
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_idx, 0, {
				end_col = #line,
				hl_group = mode_hl,
			})
		end

		-- Highlight stats line
		if line:match("󰝰") then
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_idx, 0, {
				end_col = #line,
				hl_group = "MarkoStats",
			})
		end

		-- Highlight separator lines
		if line:match("^─+$") then
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_idx, 0, {
				end_col = #line,
				hl_group = "MarkoSeparator",
			})
		end

		-- Highlight column headers
		if line:match("Mark") then
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_idx, 0, {
				end_col = #line,
				hl_group = "MarkoColumnHeader",
			})
		end

		-- Highlight status bar with mode-specific colors
		if line:match("J/K") or line:match("Press mark key") then
			local status_hl = config.navigation_mode == "direct" and "MarkoDirectModeStatus" or "MarkoPopupModeStatus"
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_idx, 0, {
				end_col = #line,
				hl_group = status_hl,
			})
		end
	end

	if #marks == 0 then
		return
	end

	-- Highlight mark content lines
	for i, mark in ipairs(marks) do
		local line_idx = marks_start_line + i - 1
		local line_content = vim.api.nvim_buf_get_lines(bufnr, line_idx, line_idx + 1, false)[1]

		if not line_content or #line_content == 0 then
			goto continue
		end

		-- Handle mark character highlighting
		local mark_pattern = "^  ([a-zA-Z]) " .. vim.pesc(config.separator)
		local mark_start, mark_end, captured_mark = line_content:find(mark_pattern)
		if mark_start and captured_mark then
			local mark_hl_group = mark.type == "global" and "MarkoGlobalMark" or "MarkoBufferMark"
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_idx, 2, {
				end_col = 3,
				hl_group = mark_hl_group,
			})
		end

		-- Highlight line numbers
		local start_pos = 1
		while start_pos <= #line_content do
			local match_start, match_end = line_content:find("(%d+)", start_pos)
			if not match_start then
				break
			end

			vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_idx, match_start - 1, {
				end_col = match_end,
				hl_group = "MarkoLineNumber",
			})

			start_pos = match_end + 1
		end

		-- Highlight filename section (after second separator to end of line)
		local separators = {}
		local sep_start = 1
		while true do
			local sep_pos = line_content:find(config.separator, sep_start)
			if not sep_pos then
				break
			end
			table.insert(separators, sep_pos)
			sep_start = sep_pos + 1
		end

		if #separators >= 2 then
			local filename_start = separators[2] + 1
			local filename_end = #line_content
			if filename_start <= filename_end then
				-- skip leading spaces
				while filename_start <= filename_end and line_content:sub(filename_start, filename_start) == " " do
					filename_start = filename_start + 1
				end
				vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_idx, filename_start - 1, {
					end_col = filename_end,
					hl_group = "MarkoFilename",
				})
			end
		end

		::continue::
	end
end

return M
