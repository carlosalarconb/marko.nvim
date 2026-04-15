local M = {}

-- ============================================
-- DIRECT MODULE TESTS
-- ============================================

local function test_direct_module_loads()
	local ok, err = pcall(function()
		require("marko.direct")
	end)
	assert(ok, "direct module should load: " .. tostring(err))
end

local function test_direct_setup_keymaps_does_not_throw()
	local direct = require("marko.direct")

	local ok, err = pcall(function()
		direct.setup_keymaps()
	end)

	assert(ok, "setup_keymaps() should not throw: " .. tostring(err))
end

local function test_direct_remove_keymaps_does_not_throw()
	local direct = require("marko.direct")

	local ok, err = pcall(function()
		direct.remove_keymaps()
	end)

	assert(ok, "remove_keymaps() should not throw: " .. tostring(err))
end

local function test_direct_is_active_returns_boolean()
	local direct = require("marko.direct")
	local result = direct.is_active()

	assert(type(result) == "boolean", "is_active() should return boolean")
end

-- Run all tests
function M.run_all()
	local tests = {
		{ name = "test_direct_module_loads", fn = test_direct_module_loads },
		{ name = "test_direct_setup_keymaps_does_not_throw", fn = test_direct_setup_keymaps_does_not_throw },
		{ name = "test_direct_remove_keymaps_does_not_throw", fn = test_direct_remove_keymaps_does_not_throw },
		{ name = "test_direct_is_active_returns_boolean", fn = test_direct_is_active_returns_boolean },
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

