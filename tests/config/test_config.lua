local M = {}

-- ============================================
-- CONFIG MODULE TESTS
-- ============================================

local function test_config_module_loads()
	local ok, err = pcall(function()
		require("marko.config")
	end)
	assert(ok, "config module should load: " .. tostring(err))
end

local function test_config_get_returns_table()
	local config = require("marko.config")
	local result = config.get()

	assert(type(result) == "table", "get() should return table")
end

local function test_config_get_namespace_returns_number()
	local config = require("marko.config")
	local ns = config.get_namespace()

	assert(type(ns) == "number", "get_namespace() should return number")
end

local function test_config_setup_does_not_throw()
	local config = require("marko.config")

	local ok, err = pcall(function()
		config.setup({})
	end)

	assert(ok, "setup() should not throw: " .. tostring(err))
end

local function test_config_refresh_highlights_does_not_throw()
	local config = require("marko.config")

	local ok, err = pcall(function()
		config.refresh_highlights()
	end)

	assert(ok, "refresh_highlights() should not throw: " .. tostring(err))
end

local function test_config_default_values_exist()
	local config = require("marko.config").get()

	assert(type(config.width) == "number", "width should exist")
	assert(type(config.height) == "number", "height should exist")
	assert(type(config.navigation_mode) == "string", "navigation_mode should exist")
	assert(type(config.keymaps) == "table", "keymaps should exist")
end

local function test_config_sidebar_defaults()
	local config = require("marko.config").get()

	assert(type(config.sidebar) == "table", "sidebar config should exist")
	assert(config.sidebar.enabled == false, "sidebar should default to disabled")
	assert(type(config.sidebar.width) == "number", "sidebar width should exist")
	assert(type(config.sidebar.position) == "string", "sidebar position should exist")
end

-- Run all tests
function M.run_all()
	local tests = {
		{ name = "test_config_module_loads", fn = test_config_module_loads },
		{ name = "test_config_get_returns_table", fn = test_config_get_returns_table },
		{ name = "test_config_get_namespace_returns_number", fn = test_config_get_namespace_returns_number },
		{ name = "test_config_setup_does_not_throw", fn = test_config_setup_does_not_throw },
		{ name = "test_config_refresh_highlights_does_not_throw", fn = test_config_refresh_highlights_does_not_throw },
		{ name = "test_config_default_values_exist", fn = test_config_default_values_exist },
		{ name = "test_config_sidebar_defaults", fn = test_config_sidebar_defaults },
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

