# CRUSH.md for marko.nvim

## Build/Lint/Test Commands
- **No build system**: Pure Lua Neovim plugin with no compilation
- **No test suite**: No automated tests found in codebase
- **Single test execution**: N/A (no tests)
- **Linting**: No linters configured
- **Formatting**: No formatters configured

## Code Style Guidelines

### Namespace and Imports
- Use `local` declarations for all module functions and variables
- Import modules using `require()` at top of file
- Functions are prefixed with module name when returned (e.g., `M.function_name`)
- Use consistent naming: `M` for main module table, `config` for configuration

### Core Lua Patterns Observed
- Functions follow `function M.name()` pattern for exported functions
- Local functions use `local function name()`
- Configuration merging uses `vim.tbl_deep_extend("force", defaults, opts)`
- Error handling through vim.notify with INFO level for user feedback
- Use deferred execution (`vim.defer_fn`) for keymap setup after cleanup

### Types and Validation
- Configuration objects use table-based structures with defaults
- Boolean flags (enabled/disabled) use true/false
- No explicit type checking beyond basic value presence
- Color configurations use hex color strings (#RRGGBB) or "NONE"

### Error Handling
- Use `vim.notify()` with `vim.log.levels.INFO` for user-facing messages
- Notify messages include timeout (2000ms) and title ("Marko")
- Graceful handling of missing optional fields with `or` defaults
- No explicit try/catch, relies on Lua's error propagation

### Event Handling
- Autocommands use `vim.api.nvim_create_autocmd` with anonymous groups
- Groups cleared on recreation with `{ clear = true }`
- Keymaps use `vim.keymap.set` with description for discoverability

Generated with Crush
Co-Authored-By: Crush &lt;crush@charm.land&gt;