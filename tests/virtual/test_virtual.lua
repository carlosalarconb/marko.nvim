local M = {}

-- ============================================
-- VIRTUAL MODULE TESTS
-- ============================================

local function test_virtual_module_loads()
	local ok, err = pcall(function()
		require("marko.virtual")
	end)
	assert(ok, "virtual module should load: " .. tostring(err))
end

local function test_virtual_setup_does_not_throw()
	local virtual = require("marko.virtual")

	local ok, err = pcall(function()
		virtual.setup({})
	end)

	assert(ok, "setup() should not throw: " .. tostring(err))
end

local function test_virtual_toggle_does_not_throw()
	local virtual = require("marko.virtual")

	local ok, err = pcall(function()
		virtual.toggle()
	end)

	assert(ok, "toggle() should not throw: " .. tostring(err))
end

local function test_virtual_refresh_buffer_marks_does_not_throw()
	local virtual = require("marko.virtual")

	local ok, err = pcall(function()
		virtual.refresh_buffer_marks()
	end)

	assert(ok, "refresh_buffer_marks() should not throw: " .. tostring(err))
end

local function test_virtual_stop_timer_does_not_throw()
	local virtual = require("marko.virtual")

	local ok, err = pcall(function()
		virtual.stop_timer()
	end)

	assert(ok, "stop_timer() should not throw: " .. tostring(err))
end

local function test_virtual_cleanup_does_not_throw()
	local virtual = require("marko.virtual")

	local ok, err = pcall(function()
		virtual.cleanup()
	end)

	assert(ok, "cleanup() should not throw: " .. tostring(err))
end

-- Run all tests
function M.run_all()
	local tests = {
		{ name = "test_virtual_module_loads", fn = test_virtual_module_loads },
		{ name = "test_virtual_setup_does_not_throw", fn = test_virtual_setup_does_not_throw },
		{ name = "test_virtual_toggle_does_not_throw", fn = test_virtual_toggle_does_not_throw },
		{
			name = "test_virtual_refresh_buffer_marks_does_not_throw",
			fn = test_virtual_refresh_buffer_marks_does_not_throw,
		},
		{ name = "test_virtual_stop_timer_does_not_throw", fn = test_virtual_stop_timer_does_not_throw },
		{ name = "test_virtual_cleanup_does_not_throw", fn = test_virtual_cleanup_does_not_throw },
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

