local M = {}

-- Centralized state management
local state = {
	ns_id = vim.api.nvim_create_namespace("marko_virtual_marks"),
	buffers = {}, -- bufnr -> { ... }
	timer = nil,
	config = {
		enabled = true,
		icon = "●",
		hl_group = "Comment",
		position = "eol", -- "eol" or "overlay"
		refresh_interval = 250, -- milliseconds
		format = function(mark, icon)
			return icon .. " " .. mark
		end,
	},
}

-- Setup virtual text configuration
function M.setup(opts)
	if opts then
		state.config = vim.tbl_deep_extend("force", state.config, opts)
	end
end

-- Get theme-aware highlight group for marks
local function get_mark_highlight(mark)
	-- Use the same highlight groups as the popup for consistency
	if mark:match("[a-z]") then
		return "MarkoBufferMark" -- Blue for buffer marks
	else
		return "MarkoGlobalMark" -- Red for global marks
	end
end

-- Show virtual text for a mark (internal function, used by refresh)
local function show_mark_internal(bufnr, mark, line, col)
	if not state.config.enabled then
		return
	end
	-- Validate inputs
	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	if not line or line <= 0 then
		return
	end
	-- Create virtual text
	local virt_text = state.config.format(mark, state.config.icon)
	local mark_hl = get_mark_highlight(mark)
	-- Set extmark (no need to track ID)
	local success, _ = pcall(vim.api.nvim_buf_set_extmark, bufnr, state.ns_id, line - 1, 0, {
		virt_text = { { virt_text, mark_hl } },
		virt_text_pos = state.config.position,
		priority = 100,
	})
end

-- Show virtual text for a mark (public function, triggers full refresh)
function M.show_mark(bufnr, mark, line, col)
	M.refresh_buffer_marks(bufnr)
end

-- Hide virtual text for a mark (now just clears all marks in buffer)
function M.hide_mark(bufnr, mark)
	vim.api.nvim_buf_clear_namespace(bufnr, state.ns_id, 0, -1)
end

-- Hide all virtual marks in a buffer
function M.hide_all_marks(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, state.ns_id, 0, -1)
end

-- Refresh virtual marks for current buffer
function M.refresh_buffer_marks(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	-- Validate buffer
	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	-- Clear existing virtual marks
	M.hide_all_marks(bufnr)
	if not state.config.enabled then
		return
	end
	-- Get buffer marks using getmarklist - more reliable
	for _, data in ipairs(vim.fn.getmarklist("%")) do
		local mark = data.mark:sub(2, 3) -- Remove ' prefix
		local pos = data.pos
		if mark:match("[a-z]") and pos[2] > 0 then
			show_mark_internal(bufnr, mark, pos[2], pos[3])
		end
	end
	-- Get global marks using getmarklist - proper approach
	for _, data in ipairs(vim.fn.getmarklist()) do
		local mark = data.mark:sub(2, 3) -- Remove ' prefix
		local pos = data.pos
		if mark:match("[A-Z]") and pos[1] == bufnr then
			show_mark_internal(bufnr, mark, pos[2], pos[3])
		end
	end
end

-- Toggle virtual marks on/off
function M.toggle()
	state.config.enabled = not state.config.enabled
	if state.config.enabled then
		-- Refresh all buffers
		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(bufnr) then
				M.refresh_buffer_marks(bufnr)
			end
		end
		vim.notify("Virtual marks enabled", vim.log.levels.INFO)
	else
		-- Hide all virtual marks
		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(bufnr) then
				M.hide_all_marks(bufnr)
			end
		end
		vim.notify("Virtual marks disabled", vim.log.levels.INFO)
	end
end

-- Cleanup function to stop timer and clear marks
function M.cleanup()
	M.stop_timer()
	-- Clear all virtual marks
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			M.hide_all_marks(bufnr)
		end
	end
end

-- Start the timer-based refresh system
function M.start_timer()
	if state.timer then
		state.timer:stop()
		state.timer:close()
	end
	state.timer = vim.loop.new_timer()
	state.timer:start(
		0,
		state.config.refresh_interval,
		vim.schedule_wrap(function()
			if not state.config.enabled then
				return
			end
			-- Refresh all visible buffers
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local bufnr = vim.api.nvim_win_get_buf(win)
				if vim.api.nvim_buf_is_loaded(bufnr) then
					M.refresh_buffer_marks(bufnr)
				end
			end
		end)
	)
end

-- Stop the timer
function M.stop_timer()
	if state.timer then
		state.timer:stop()
		state.timer:close()
		state.timer = nil
	end
end

-- Setup autocommands to automatically show/hide marks
function M.setup_autocmds()
	local group = vim.api.nvim_create_augroup("MarkoVirtualMarks", { clear = true })
	-- Immediate refresh when buffer is entered
	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = function(args)
			if args.buf and vim.api.nvim_buf_is_valid(args.buf) then
				M.refresh_buffer_marks(args.buf)
			end
		end,
	})
	-- Clean up when buffer is deleted
	vim.api.nvim_create_autocmd("BufDelete", {
		group = group,
		callback = function(args)
			if args.buf then
				M.hide_all_marks(args.buf)
			end
		end,
	})
	-- Start the timer system
	M.start_timer()
end

return M

