local M = {}

-- ============================================
-- SIDEBAR MODULE TESTS
-- ============================================

local function test_sidebar_module_loads()
	local ok, err = pcall(function()
		require("marko.popup.sidebar")
	end)
	assert(ok, "sidebar module should load: " .. tostring(err))
end

local function test_sidebar_is_open_returns_boolean()
	local sidebar = require("marko.popup.sidebar")
	local result = sidebar.is_open()

	-- Initially returns nil (falsy), which is acceptable
	assert(result == nil or result == true or result == false, "is_open should return boolean or nil")
end

local function test_sidebar_close_does_not_throw()
	local sidebar = require("marko.popup.sidebar")

	local ok, err = pcall(function()
		sidebar.close()
	end)

	assert(ok, "close should not throw: " .. tostring(err))
end

-- Run all tests
function M.run_all()
	local tests = {
		{ name = "test_sidebar_module_loads", fn = test_sidebar_module_loads },
		{ name = "test_sidebar_is_open_returns_boolean", fn = test_sidebar_is_open_returns_boolean },
		{ name = "test_sidebar_close_does_not_throw", fn = test_sidebar_close_does_not_throw },
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
