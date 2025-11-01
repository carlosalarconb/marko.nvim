local M = {}

-- Get all marks in the current buffer
function M.get_buffer_marks()
	local marks = {}
	local buf = vim.api.nvim_get_current_buf()

	-- Use getmarklist for buffer marks - more consistent
	for _, data in ipairs(vim.fn.getmarklist("%")) do
		local mark = data.mark:sub(2, 3) -- Remove ' prefix
		local pos = data.pos

		if mark:match("[a-z]") and pos[2] > 0 then
			local line = vim.api.nvim_buf_get_lines(buf, pos[2] - 1, pos[2], false)[1] or ""
			table.insert(marks, {
				mark = mark,
				line = pos[2],
				col = pos[3],
				text = line:sub(1, 50), -- Truncate long lines
				type = "buffer",
			})
		end
	end

	return marks
end

-- Get buffer marks from all loaded buffers
function M.get_all_buffer_marks()
	local marks = {}

	-- Get all loaded buffers
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) then
			local filename = vim.api.nvim_buf_get_name(buf)

			-- Use getmarklist for buffer marks - more consistent
			for _, data in ipairs(vim.fn.getmarklist(buf)) do
				local mark = data.mark:sub(2, 3) -- Remove ' prefix
				local pos = data.pos

				if mark:match("[a-z]") and pos[2] > 0 then
					local line = vim.api.nvim_buf_get_lines(buf, pos[2] - 1, pos[2], false)[1] or ""
					table.insert(marks, {
						mark = mark,
						line = pos[2],
						col = pos[3],
						text = line:sub(1, 50),
						filename = filename,
						type = "buffer",
					})
				end
			end
		end
	end

	return marks
end

-- Get all global marks
function M.get_global_marks()
	local marks = {}

	-- Use getmarklist for global marks - much cleaner and more reliable
	for _, data in ipairs(vim.fn.getmarklist()) do
		local mark = data.mark:sub(2, 3) -- Remove ' prefix
		local pos = data.pos

		if mark:match("[A-Z]") and pos[2] > 0 then
			local filename = data.file or ""
			local line_text = ""

			-- Get line text if file is loaded in a buffer
			local loaded_buf = nil

			-- Try multiple matching strategies for better path matching
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(buf) then
					local buf_name = vim.api.nvim_buf_get_name(buf)

					-- Strategy 1: Exact match
					if buf_name == filename then
						loaded_buf = buf
						break
					end

					-- Strategy 2: Resolve paths and compare (handles relative vs absolute)
					if filename ~= "" and buf_name ~= "" then
						local resolved_filename = vim.fn.resolve(vim.fn.fnamemodify(filename, ":p"))
						local resolved_buf_name = vim.fn.resolve(vim.fn.fnamemodify(buf_name, ":p"))
						if resolved_filename == resolved_buf_name then
							loaded_buf = buf
							break
						end
					end

					-- Strategy 3: Compare just the filename (last resort)
					if filename ~= "" and buf_name ~= "" then
						if vim.fn.fnamemodify(filename, ":t") == vim.fn.fnamemodify(buf_name, ":t") then
							loaded_buf = buf
							break
						end
					end
				end
			end

			if loaded_buf then
				-- Get line from loaded buffer
				local lines = vim.api.nvim_buf_get_lines(loaded_buf, pos[2] - 1, pos[2], false)
				if lines and lines[1] then
					line_text = lines[1]
				end
			elseif filename ~= "" and vim.fn.filereadable(filename) == 1 then
				-- Read from file if not loaded - FIX: correct indexing
				local lines = vim.fn.readfile(filename, "", pos[2])
				if lines and #lines >= pos[2] and pos[2] > 0 then
					line_text = lines[pos[2]] -- This is correct: readfile returns 1-indexed array
				end
			end

			table.insert(marks, {
				mark = mark,
				line = pos[2],
				col = pos[3],
				text = line_text:sub(1, 50),
				filename = filename,
				type = "global",
			})
		end
	end

	return marks
end

-- Deduplicate marks at the same location, prioritizing buffer marks over global marks
function M.deduplicate_marks(marks)
	local seen = {}
	local deduplicated = {}

	-- Define priority: buffer > global
	local priority = { buffer = 1, global = 2 }

	for _, mark in ipairs(marks) do
		local key = (mark.filename or "") .. ":" .. mark.line .. ":" .. mark.col

		if not seen[key] then
			-- First mark at this location
			seen[key] = mark
			table.insert(deduplicated, mark)
		else
			-- Duplicate location - keep the higher priority mark
			local existing = seen[key]
			if priority[mark.type] < priority[existing.type] then
				-- Replace with higher priority mark
				seen[key] = mark
				-- Replace in deduplicated array
				for i, existing_mark in ipairs(deduplicated) do
					if existing_mark == existing then
						deduplicated[i] = mark
						break
					end
				end
			end
		end
	end

	return deduplicated
end

-- Debug function to check what vim thinks about marks
function M.debug_marks()
	print("=== Debug Mark Information ===")
	print("Shada setting:", vim.o.shada)
	print("Current buffer:", vim.api.nvim_buf_get_name(0))

	-- Test what vim's :marks command shows
	local marks_output = vim.fn.execute("marks")
	print("Vim marks output:")
	print(marks_output)

	print("=== End Debug ===")
end

-- Get all marks (buffer and global)
function M.get_all_marks()
	local all_marks = {}
	local config = require("marko.config").get()

	-- Get buffer marks - either from current buffer or all buffers based on config
	local buffer_marks = config.show_all_buffers and M.get_all_buffer_marks() or M.get_buffer_marks()
	local global_marks = M.get_global_marks()

	-- Combine all marks
	for _, mark in ipairs(buffer_marks) do
		table.insert(all_marks, mark)
	end

	for _, mark in ipairs(global_marks) do
		table.insert(all_marks, mark)
	end

	-- Deduplicate marks at the same location
	all_marks = M.deduplicate_marks(all_marks)

	-- Sort by mark name
	table.sort(all_marks, function(a, b)
		return a.mark < b.mark
	end)

	return all_marks
end

-- Delete a mark
function M.delete_mark(mark_info)
	local mark = mark_info.mark

	if mark_info.type == "buffer" and mark_info.filename then
		-- For buffer marks, we need to delete from the specific buffer
		local buffers = vim.api.nvim_list_bufs()
		for _, buf in ipairs(buffers) do
			if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) == mark_info.filename then
				-- Use nvim_buf_del_mark API to avoid buffer switching
				vim.api.nvim_buf_del_mark(buf, mark)
				break
			end
		end
	else
		-- For global marks, delete normally
		vim.cmd("delmarks " .. mark)
	end
end

-- Go to a mark
function M.goto_mark(mark_info)
	-- For global marks, use vim's native mark jumping which handles file switching
	if mark_info.type == "global" then
		vim.cmd("normal! '" .. mark_info.mark)
		return
	end

	-- For buffer marks, switch to the correct file if needed
	if mark_info.filename and mark_info.filename ~= "" then
		local current_file = vim.api.nvim_buf_get_name(0)
		-- Only switch files if we're not already in the target file
		if current_file ~= mark_info.filename then
			-- Check if file exists before trying to open it
			if vim.fn.filereadable(mark_info.filename) == 1 then
				vim.cmd("edit " .. vim.fn.fnameescape(mark_info.filename))
			else
				vim.notify("File not found: " .. mark_info.filename, vim.log.levels.ERROR)
				return
			end
		end
	end

	-- Validate cursor position before setting
	local line_count = vim.api.nvim_buf_line_count(0)
	local target_line = math.max(1, math.min(mark_info.line, line_count))

	-- Get the actual line to validate column
	local lines = vim.api.nvim_buf_get_lines(0, target_line - 1, target_line, false)
	local line_length = lines[1] and #lines[1] or 0
	local target_col = math.max(0, math.min(mark_info.col, line_length))

	vim.api.nvim_win_set_cursor(0, { target_line, target_col })
end

return M
