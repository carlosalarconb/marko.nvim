local M = {}

-- ============================================
-- PATH NORMALIZATION
-- ============================================
local function normalize_path(path)
	if path == "" then
		return path
	end
	-- Use fnamemodify to get absolute path with correct separators
	return vim.fn.fnamemodify(path, ":p")
end

-- ============================================
-- BUFFER MARKS
-- ============================================
function M.get_buffer_marks()
	local marks = {}
	local buf = vim.api.nvim_get_current_buf()

	for _, data in ipairs(vim.fn.getmarklist("%")) do
		local mark = data.mark:sub(2, 3)
		local pos = data.pos

		if mark:match("[a-z]") and pos[2] > 0 then
			local line = vim.api.nvim_buf_get_lines(buf, pos[2] - 1, pos[2], false)[1] or ""
			table.insert(marks, {
				mark = mark,
				line = pos[2],
				col = pos[3],
				text = line:sub(1, 50),
				type = "buffer",
			})
		end
	end

	return marks
end

-- ============================================
-- ALL BUFFER MARKS
-- ============================================
function M.get_all_buffer_marks()
	local marks = {}

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) then
			local filename = normalize_path(vim.api.nvim_buf_get_name(buf))

			for _, data in ipairs(vim.fn.getmarklist(buf)) do
				local mark = data.mark:sub(2, 3)
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

-- ============================================
-- GLOBAL MARKS
-- ============================================
function M.get_global_marks()
	local marks = {}

	for _, data in ipairs(vim.fn.getmarklist()) do
		local mark = data.mark:sub(2, 3)
		local pos = data.pos

		if mark:match("[A-Z]") and pos[2] > 0 then
			local filename = normalize_path(data.file or "")
			local line_text = ""

			local loaded_buf = nil

			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(buf) then
					local buf_name = vim.api.nvim_buf_get_name(buf)

					if buf_name == filename then
						loaded_buf = buf
						break
					end

					if filename ~= "" and buf_name ~= "" then
						local resolved_filename = vim.fn.resolve(vim.fn.fnamemodify(filename, ":p"))
						local resolved_buf_name = vim.fn.resolve(vim.fn.fnamemodify(buf_name, ":p"))
						if resolved_filename == resolved_buf_name then
							loaded_buf = buf
							break
						end
					end

					if filename ~= "" and buf_name ~= "" then
						if vim.fn.fnamemodify(filename, ":t") == vim.fn.fnamemodify(buf_name, ":t") then
							loaded_buf = buf
							break
						end
					end
				end
			end

			if loaded_buf then
				local lines = vim.api.nvim_buf_get_lines(loaded_buf, pos[2] - 1, pos[2], false)
				if lines and lines[1] then
					line_text = lines[1]
				end
			elseif filename ~= "" and vim.fn.filereadable(filename) == 1 then
				local lines = vim.fn.readfile(filename, "", pos[2])
				if lines and #lines >= pos[2] and pos[2] > 0 then
					line_text = lines[pos[2]]
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

-- ============================================
-- DEDUPLICATION
-- ============================================
function M.deduplicate_marks(marks)
	local seen = {}
	local deduplicated = {}

	local priority = { buffer = 1, global = 2 }

	for _, mark in ipairs(marks) do
		local key = (mark.filename or "") .. ":" .. mark.line .. ":" .. mark.col

		if not seen[key] then
			seen[key] = mark
			table.insert(deduplicated, mark)
		else
			local existing = seen[key]
			if priority[mark.type] < priority[existing.type] then
				seen[key] = mark
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

-- ============================================
-- DEBUG
-- ============================================
function M.debug_marks()
	print("=== Debug Mark Information ===")
	print("Shada setting:", vim.o.shada)
	print("Current buffer:", vim.api.nvim_buf_get_name(0))

	local marks_output = vim.fn.execute("marks")
	print("Vim marks output:")
	print(marks_output)

	print("=== End Debug ===")
end

-- ============================================
-- GET ALL MARKS
-- ============================================
function M.get_all_marks()
	local all_marks = {}
	local config = require("marko.config").get()

	local buffer_marks = config.show_all_buffers and M.get_all_buffer_marks() or M.get_buffer_marks()
	local global_marks = M.get_global_marks()

	for _, mark in ipairs(buffer_marks) do
		table.insert(all_marks, mark)
	end

	for _, mark in ipairs(global_marks) do
		table.insert(all_marks, mark)
	end

	all_marks = M.deduplicate_marks(all_marks)

	table.sort(all_marks, function(a, b)
		return a.mark < b.mark
	end)

	return all_marks
end

-- ============================================
-- DELETE
-- ============================================
function M.delete_mark(mark_info)
	local mark = mark_info.mark

	if mark_info.type == "buffer" and mark_info.filename then
		local buffers = vim.api.nvim_list_bufs()
		for _, buf in ipairs(buffers) do
			if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) == mark_info.filename then
				vim.api.nvim_buf_del_mark(buf, mark)
				break
			end
		end
	else
		vim.cmd("delmarks " .. mark)
	end
end

-- ============================================
-- JUMP
-- ============================================
function M.goto_mark(mark_info)
	if mark_info.type == "global" then
		vim.cmd("normal! '" .. mark_info.mark)
		return
	end

	if mark_info.filename and mark_info.filename ~= "" then
		local current_file = vim.api.nvim_buf_get_name(0)
		if current_file ~= mark_info.filename then
			if vim.fn.filereadable(mark_info.filename) == 1 then
				vim.cmd("edit " .. vim.fn.fnameescape(mark_info.filename))
			else
				vim.notify("File not found: " .. mark_info.filename, vim.log.levels.ERROR)
				return
			end
		end
	end

	local line_count = vim.api.nvim_buf_line_count(0)
	local target_line = math.max(1, math.min(mark_info.line, line_count))

	local lines = vim.api.nvim_buf_get_lines(0, target_line - 1, target_line, false)
	local line_length = lines[1] and #lines[1] or 0
	local target_col = math.max(0, math.min(mark_info.col, line_length))

	vim.api.nvim_win_set_cursor(0, { target_line, target_col })
end

return M
