local M = {}

-- ============================================
-- POPUP MODULE TESTS
-- ============================================

local function test_popup_window_creates()
	local ok, err = pcall(function()
		require("marko.popup.window")
	end)
	assert(ok, "window module should load: " .. tostring(err))
end

local function test_popup_buffer_creates()
	local ok, err = pcall(function()
		require("marko.popup.buffer")
	end)
	assert(ok, "buffer module should load: " .. tostring(err))
end

local function test_popup_highlighting_creates()
	local ok, err = pcall(function()
		require("marko.popup.highlighting")
	end)
	assert(ok, "highlighting module should load: " .. tostring(err))
end

local function test_popup_keymaps_creates()
	local ok, err = pcall(function()
		require("marko.popup.keymaps")
	end)
	assert(ok, "keymaps module should load: " .. tostring(err))
end

local function test_popup_buffer_generate_separator()
	local buffer = require("marko.popup.buffer")
	local sep = buffer.generate_separator()

	assert(type(sep) == "string", "Should return string")
	assert(#sep > 0, "Should not be empty")
end

-- Run all tests
function M.run_all()
	local tests = {
		{ name = "test_popup_window_creates", fn = test_popup_window_creates },
		{ name = "test_popup_buffer_creates", fn = test_popup_buffer_creates },
		{ name = "test_popup_highlighting_creates", fn = test_popup_highlighting_creates },
		{ name = "test_popup_keymaps_creates", fn = test_popup_keymaps_creates },
		{ name = "test_popup_buffer_generate_separator", fn = test_popup_buffer_generate_separator },
	}

	local passed = 0
	local failed = 0

	for _, test in ipairs(tests) do
		local success, err = pcall(test.fn)
		if success then
			passed = passed + 1
			print("PASS: " .. test.name)
		else
			failed = failed + 1
			print("FAIL: " .. test.name .. " - " .. tostring(err))
		end
	end

	print(string.format("\n=== Results: %d passed, %d failed ===", passed, failed))

	return failed == 0
end

return M
