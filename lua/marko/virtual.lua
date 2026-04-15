local M = {}

-- ============================================
-- STATE
-- ============================================
local state = {
	ns_id = vim.api.nvim_create_namespace("marko_virtual_marks"),
	buffers = {},
	timer = nil,
	config = {
		enabled = true,
		icon = "●",
		hl_group = "Comment",
		position = "eol",
		refresh_interval = 250,
		format = function(mark, icon)
			return icon .. " " .. mark
		end,
	},
}

-- ============================================
-- SETUP
-- ============================================
function M.setup(opts)
	if opts then
		state.config = vim.tbl_deep_extend("force", state.config, opts)
	end
end

-- ============================================
-- INTERNAL
-- ============================================
local function get_mark_highlight(mark)
	if mark:match("[a-z]") then
		return "MarkoBufferMark"
	else
		return "MarkoGlobalMark"
	end
end

local function show_mark_internal(bufnr, mark, line, col)
	if not state.config.enabled then
		return
	end

	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	if not line or line <= 0 then
		return
	end

	local virt_text = state.config.format(mark, state.config.icon)
	local mark_hl = get_mark_highlight(mark)

	local success, _ = pcall(vim.api.nvim_buf_set_extmark, bufnr, state.ns_id, line - 1, 0, {
		virt_text = { { virt_text, mark_hl } },
		virt_text_pos = state.config.position,
		priority = 100,
	})
end

-- ============================================
-- SHOW/HIDE
-- ============================================
function M.show_mark(bufnr, mark, line, col)
	M.refresh_buffer_marks(bufnr)
end

function M.hide_mark(bufnr, mark)
	vim.api.nvim_buf_clear_namespace(bufnr, state.ns_id, 0, -1)
end

function M.hide_all_marks(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, state.ns_id, 0, -1)
end

-- ============================================
-- REFRESH
-- ============================================
function M.refresh_buffer_marks(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	M.hide_all_marks(bufnr)

	if not state.config.enabled then
		return
	end

	for _, data in ipairs(vim.fn.getmarklist("%")) do
		local mark = data.mark:sub(2, 3)
		local pos = data.pos

		if mark:match("[a-z]") and pos[2] > 0 then
			show_mark_internal(bufnr, mark, pos[2], pos[3])
		end
	end

	for _, data in ipairs(vim.fn.getmarklist()) do
		local mark = data.mark:sub(2, 3)
		local pos = data.pos

		if mark:match("[A-Z]") and pos[1] == bufnr then
			show_mark_internal(bufnr, mark, pos[2], pos[3])
		end
	end
end

-- ============================================
-- TOGGLE
-- ============================================
function M.toggle()
	state.config.enabled = not state.config.enabled

	if state.config.enabled then
		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(bufnr) then
				M.refresh_buffer_marks(bufnr)
			end
		end
		vim.notify("Virtual marks enabled", vim.log.levels.INFO)
	else
		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(bufnr) then
				M.hide_all_marks(bufnr)
			end
		end
		vim.notify("Virtual marks disabled", vim.log.levels.INFO)
	end
end

-- ============================================
-- CLEANUP
-- ============================================
function M.cleanup()
	M.stop_timer()

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			M.hide_all_marks(bufnr)
		end
	end
end

-- ============================================
-- TIMER
-- ============================================
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

			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local bufnr = vim.api.nvim_win_get_buf(win)
				if vim.api.nvim_buf_is_loaded(bufnr) then
					M.refresh_buffer_marks(bufnr)
				end
			end
		end)
	)
end

function M.stop_timer()
	if state.timer then
		state.timer:stop()
		state.timer:close()
		state.timer = nil
	end
end

-- ============================================
-- AUTOCMDS
-- ============================================
function M.setup_autocmds()
	local group = vim.api.nvim_create_augroup("MarkoVirtualMarks", { clear = true })

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = function(args)
			if args.buf and vim.api.nvim_buf_is_valid(args.buf) then
				M.refresh_buffer_marks(args.buf)
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = group,
		callback = function(args)
			if args.buf then
				M.hide_all_marks(args.buf)
			end
		end,
	})

	M.start_timer()
end

return M
