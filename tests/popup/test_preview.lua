local M = {}

-- ============================================
-- PREVIEW MODULE TESTS
-- ============================================

local function test_preview_module_loads()
  local ok, err = pcall(function()
    require("marko.popup.preview")
  end)
  assert(ok, "preview module should load: " .. tostring(err))
end

local function test_preview_is_open_returns_boolean()
  local preview = require("marko.popup.preview")
  local result = preview.is_open()
  
  -- Initially returns nil (falsy), which is acceptable
  assert(result == nil or result == true or result == false, "is_open should return boolean or nil")
end

local function test_preview_close_does_not_throw()
  local preview = require("marko.popup.preview")
  
  local ok, err = pcall(function()
    preview.close()
  end)
  
  assert(ok, "close should not throw: " .. tostring(err))
end

-- Run all tests
function M.run_all()
  local tests = {
    { name = "test_preview_module_loads", fn = test_preview_module_loads },
    { name = "test_preview_is_open_returns_boolean", fn = test_preview_is_open_returns_boolean },
    { name = "test_preview_close_does_not_throw", fn = test_preview_close_does_not_throw },
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