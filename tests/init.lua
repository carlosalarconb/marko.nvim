-- ============================================
-- TEST RUNNER
-- ============================================
-- Run with: nvim --headless -c "luafile tests/init.lua" -c "lua tests.run_all()" -c "qa!"

-- Add current directory to path
package.path = package.path .. ";./tests/?.lua;./tests/?/init.lua"
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load modules
require("marko.config").setup({})
require("marko.icons")
require("marko.marks")

print("=== Running Marko.nvim Tests ===\n")

local all_passed = true

-- Run marks tests
print("--- Marks Module ---")
local marks_ok, marks_err = pcall(function()
  require("tests.marks.test_marks").run_all()
end)
if not marks_ok then
  print("Marks tests error: " .. tostring(marks_err))
  all_passed = false
end

-- Run icons tests
print("\n--- Icons Module ---")
local icons_ok, icons_err = pcall(function()
  require("tests.icons.test_icons").run_all()
end)
if not icons_ok then
  print("Icons tests error: " .. tostring(icons_err))
  all_passed = false
end

-- Run popup tests
print("\n--- Popup Module ---")
local popup_ok, popup_err = pcall(function()
  require("tests.popup.test_popup").run_all()
end)
if not popup_ok then
  print("Popup tests error: " .. tostring(popup_err))
  all_passed = false
end

-- Run sidebar tests
print("\n--- Sidebar Module ---")
local sidebar_ok, sidebar_err = pcall(function()
  require("tests.popup.test_sidebar").run_all()
end)
if not sidebar_ok then
  print("Sidebar tests error: " .. tostring(sidebar_err))
  all_passed = false
end

-- Run preview tests
print("\n--- Preview Module ---")
local preview_ok, preview_err = pcall(function()
  require("tests.popup.test_preview").run_all()
end)
if not preview_ok then
  print("Preview tests error: " .. tostring(preview_err))
  all_passed = false
end

-- Run config tests
print("\n--- Config Module ---")
local config_ok, config_err = pcall(function()
  require("tests.config.test_config").run_all()
end)
if not config_ok then
  print("Config tests error: " .. tostring(config_err))
  all_passed = false
end

-- Run syntax tests
print("\n--- Syntax Module ---")
local syntax_ok, syntax_err = pcall(function()
  require("tests.syntax.test_syntax").run_all()
end)
if not syntax_ok then
  print("Syntax tests error: " .. tostring(syntax_err))
  all_passed = false
end

-- Run direct tests
print("\n--- Direct Module ---")
local direct_ok, direct_err = pcall(function()
  require("tests.direct.test_direct").run_all()
end)
if not direct_ok then
  print("Direct tests error: " .. tostring(direct_err))
  all_passed = false
end

-- Run virtual tests
print("\n--- Virtual Module ---")
local virtual_ok, virtual_err = pcall(function()
  require("tests.virtual.test_virtual").run_all()
end)
if not virtual_ok then
  print("Virtual tests error: " .. tostring(virtual_err))
  all_passed = false
end

if all_passed then
  print("\n=== All tests passed ===")
else
  print("\n=== Some tests failed ===")
end