local M = {}

-- ============================================
-- SYNTAX MODULE TESTS
-- ============================================

local function test_syntax_module_loads()
	local ok, err = pcall(function()
		require("marko.syntax")
	end)
	assert(ok, "syntax module should load: " .. tostring(err))
end

local function test_syntax_setup_filetype_does_not_throw()
	local syntax = require("marko.syntax")

	local ok, err = pcall(function()
		syntax.setup_filetype()
	end)

	assert(ok, "setup_filetype() should not throw: " .. tostring(err))
end

local function test_syntax_setup_syntax_does_not_throw()
	local syntax = require("marko.syntax")

	local ok, err = pcall(function()
		syntax.setup_syntax()
	end)

	assert(ok, "setup_syntax() should not throw: " .. tostring(err))
end

-- Run all tests
function M.run_all()
	local tests = {
		{ name = "test_syntax_module_loads", fn = test_syntax_module_loads },
		{ name = "test_syntax_setup_filetype_does_not_throw", fn = test_syntax_setup_filetype_does_not_throw },
		{ name = "test_syntax_setup_syntax_does_not_throw", fn = test_syntax_setup_syntax_does_not_throw },
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

