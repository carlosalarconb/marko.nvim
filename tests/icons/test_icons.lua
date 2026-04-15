local M = {}

-- ============================================
-- ICONS MODULE TESTS
-- ============================================

local function test_get_file_icon_returns_string()
	local icons = require("marko.icons")
	local icon = icons.get_file_icon("test.lua")

	assert(type(icon) == "string", "Should return a string")
end

local function test_get_file_icon_unknown_extension()
	local icons = require("marko.icons")
	local icon = icons.get_file_icon("test.unknown")

	assert(type(icon) == "string", "Should return a string for unknown extension")
end

local function test_get_file_icon_empty_filename()
	local icons = require("marko.icons")
	local icon = icons.get_file_icon("")

	assert(type(icon) == "string", "Should return a string for empty filename")
end

local function test_get_file_icon_nil()
	local icons = require("marko.icons")
	local icon = icons.get_file_icon(nil)

	assert(type(icon) == "string", "Should return a string for nil")
end

local function test_get_mark_icon_buffer()
	local icons = require("marko.icons")
	local icon = icons.get_mark_icon("buffer")

	assert(type(icon) == "string", "Should return a string")
	assert(icon == icons.icons.buffer_mark, "Should return buffer mark icon")
end

local function test_get_mark_icon_global()
	local icons = require("marko.icons")
	local icon = icons.get_mark_icon("global")

	assert(type(icon) == "string", "Should return a string")
	assert(icon == icons.icons.global_mark, "Should return global mark icon")
end

local function test_format_mark_line_returns_string()
	local icons = require("marko.icons")
	local config = require("marko.config").get()

	local test_mark = {
		mark = "a",
		line = 10,
		col = 5,
		text = "test line content",
		type = "buffer",
		filename = "test.lua",
	}

	local result = icons.format_mark_line(test_mark, config)

	assert(type(result) == "string", "Should return a string")
	assert(#result > 0, "Should not be empty")
end

local function test_icons_table_exists()
	local icons = require("marko.icons")

	assert(type(icons.icons) == "table", "Should have icons table")
	assert(type(icons.icons.separator) == "string", "Should have separator")
end

-- Run all tests
function M.run_all()
	local tests = {
		{ name = "test_get_file_icon_returns_string", fn = test_get_file_icon_returns_string },
		{ name = "test_get_file_icon_unknown_extension", fn = test_get_file_icon_unknown_extension },
		{ name = "test_get_file_icon_empty_filename", fn = test_get_file_icon_empty_filename },
		{ name = "test_get_file_icon_nil", fn = test_get_file_icon_nil },
		{ name = "test_get_mark_icon_buffer", fn = test_get_mark_icon_buffer },
		{ name = "test_get_mark_icon_global", fn = test_get_mark_icon_global },
		{ name = "test_format_mark_line_returns_string", fn = test_format_mark_line_returns_string },
		{ name = "test_icons_table_exists", fn = test_icons_table_exists },
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
