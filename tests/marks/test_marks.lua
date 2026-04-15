local M = {}

-- ============================================
-- MARKS MODULE TESTS
-- ============================================

local function test_deduplicate_marks()
	local marks_module = require("marko.marks")

	local test_marks = {
		{ mark = "a", line = 10, col = 1, filename = "file.lua", type = "buffer" },
		{ mark = "b", line = 10, col = 1, filename = "file.lua", type = "global" },
		{ mark = "c", line = 20, col = 1, filename = "other.lua", type = "buffer" },
	}

	local result = marks_module.deduplicate_marks(test_marks)

	assert(#result == 2, "Should have 2 marks after deduplication")
	assert(result[1].mark == "a", "Buffer mark should take priority")
end

local function test_get_buffer_marks_returns_table()
	local marks_module = require("marko.marks")
	local marks = marks_module.get_buffer_marks()

	assert(type(marks) == "table", "Should return a table")
end

local function test_get_all_marks_returns_table()
	local marks_module = require("marko.marks")
	local marks = marks_module.get_all_marks()

	assert(type(marks) == "table", "Should return a table")
end

local function test_delete_mark()
	local marks_module = require("marko.marks")

	-- Just test that the function can be called without error
	-- Don't actually try to delete a mark that might not exist
	local success = pcall(function()
		marks_module.delete_mark({ mark = "z", type = "nonexistent" })
	end)

	assert(success, "delete_mark should not throw")
end

local function test_goto_mark_validation()
	local marks_module = require("marko.marks")

	local test_mark = {
		mark = "a",
		line = 1,
		col = 1,
		type = "buffer",
	}

	local success = pcall(function()
		marks_module.goto_mark(test_mark)
	end)

	assert(success, "goto_mark should not throw")
end

-- Run all tests
function M.run_all()
	local tests = {
		{ name = "test_deduplicate_marks", fn = test_deduplicate_marks },
		{ name = "test_get_buffer_marks_returns_table", fn = test_get_buffer_marks_returns_table },
		{ name = "test_get_all_marks_returns_table", fn = test_get_all_marks_returns_table },
		{ name = "test_delete_mark", fn = test_delete_mark },
		{ name = "test_goto_mark_validation", fn = test_goto_mark_validation },
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
