# Plugin Manager Refactoring TODO

This document outlines the step-by-step plan to refactor `plugin_manager.py` into multiple files for better maintainability and code organization.

## Overview

**Current State**: `plugin_manager.py` (~1,542 lines)
**Target Structure**:
```
act_aio/
├── plugin_models.py          # ~50 lines - Data classes
├── plugin_utils.py            # ~100 lines - Utility functions
├── plugin_io.py               # ~500 lines - Import/Export + Workers
├── plugin_executor.py         # ~400 lines - Execution & Environment
└── plugin_manager.py          # ~400 lines - Main orchestrator
```

---

## Phase 1: Prepare and Backup

### Step 1: Create Backup and Setup
- [ ] Create a backup branch: `git checkout -b refactor-plugin-manager`
- [ ] Create backup of current `plugin_manager.py`
- [ ] Run existing tests (if any) to establish baseline
- [ ] Document current line count: `wc -l plugin_manager.py`
- [ ] Commit checkpoint: "Backup before refactoring"

**Estimated Time**: 10 minutes
**Risk Level**: 🟢 Low

---

## Phase 2: Extract Utility Functions

### Step 2: Create plugin_utils.py
- [x] Create new file: `act_aio/plugin_utils.py`
- [x] Add file header and imports
- [x] Move `remove_readonly()` function (lines ~33-45)
- [x] Move `safe_rmtree()` function (lines ~48-62)
- [x] Add docstrings if missing
- [x] Test utilities independently

### Step 3: Update plugin_manager.py imports
- [x] Add import: `from .plugin_utils import remove_readonly, safe_rmtree`
- [x] Remove old utility function definitions
- [x] Search and verify all usages still work
- [x] Run application and test basic operations
- [x] Commit: "Extract utility functions to plugin_utils.py"

**Estimated Time**: 20 minutes
**Risk Level**: 🟢 Low

---

## Phase 3: Extract Data Models

### Step 4: Create plugin_models.py
- [x] Create new file: `act_aio/plugin_models.py`
- [x] Add necessary imports (Path, Dict, Any, Optional)
- [x] Move `Plugin` class (lines ~65-90)
- [x] Verify all properties and methods are included
- [x] Add type hints if missing
- [x] Test model independently

### Step 5: Update plugin_manager.py imports
- [x] Add import: `from .plugin_models import Plugin`
- [x] Remove old Plugin class definition
- [x] Verify no circular dependencies
- [x] Run application and test plugin scanning
- [x] Commit: "Extract Plugin model to plugin_models.py"

**Estimated Time**: 15 minutes
**Risk Level**: 🟢 Low

---

## Phase 4: Extract Import/Export Logic

### Step 6: Create plugin_io.py - Part 1 (Workers)
- [x] Create new file: `act_aio/plugin_io.py`
- [x] Add all necessary imports
- [x] Move `PluginImportWorker` class (lines ~116-309)
- [x] Import utilities: `from .plugin_utils import safe_rmtree`
- [x] Verify worker signal definitions
- [x] Test worker independently (if possible)

### Step 7: Create plugin_io.py - Part 2 (PluginIOManager)
- [x] Create `PluginIOManager` class
- [x] Move `importPlugin()` method (lines ~919-1031)
- [x] Move `importPluginFromUrl()` method (lines ~1033-1050)
- [x] Move `_on_import_finished()` method (lines ~1052-1089)
- [x] Move `cancel_import()` method (lines ~1091-1095)
- [x] Move `exportPlugin()` method (lines ~1097-1170)
- [x] Move `_complete_import()` method (lines ~1194-1219)
- [x] Move `handleConfirmationResponse()` method (lines ~1221-1265)
- [x] Move `_cleanup_old_temp_dirs()` method (lines ~470-487)

### Step 8: Integrate PluginIOManager
- [x] Add `__init__` to PluginIOManager accepting manager reference
- [x] Store manager reference: `self.manager = manager`
- [x] Update all signal emissions to use `self.manager.signalName.emit()`
- [x] Update all `self._show_error()` to `self.manager._show_error()`
- [x] Update all `self._show_info()` to `self.manager._show_info()`
- [x] Update access to `self._plugins_dir` → `self.manager._plugins_dir`
- [x] In plugin_manager.py, create instance: `self.io_manager = PluginIOManager(self)`
- [x] Delegate calls from plugin_manager to io_manager
- [x] Test import from disk functionality
- [x] Test import from URL functionality
- [x] Test export functionality
- [x] Test overwrite confirmation dialog
- [x] Commit: "Extract I/O operations to plugin_io.py"

**Estimated Time**: 60 minutes
**Risk Level**: 🟡 Medium

---

## Phase 5: Extract Execution Logic

### Step 9: Create plugin_executor.py - Part 1 (Worker)
- [ ] Create new file: `act_aio/plugin_executor.py`
- [ ] Add all necessary imports
- [ ] Move `PluginSetupWorker` class (lines ~93-113)
- [ ] Verify worker signal definitions
- [ ] Test worker independently (if possible)

### Step 10: Create plugin_executor.py - Part 2 (PluginExecutor)
- [ ] Create `PluginExecutor` class
- [ ] Move `launch_plugin()` method (lines ~571-608)
- [ ] Move `_on_setup_finished()` method (lines ~610-622)
- [ ] Move `_launch_plugin_process()` method (lines ~624-780)
- [ ] Move `_launch_with_default_command()` method (lines ~782-803)
- [ ] Move `_setup_plugin_environment_impl()` method (lines ~805-880)
- [ ] Move `_check_uv_command()` method (lines ~882-898)
- [ ] Move `_check_python_command()` method (lines ~907-916)
- [ ] Move `executeCommand()` method (lines ~1455-1490)
- [ ] Move `_substitute_command_macros()` method (lines ~1515-1542)
- [ ] Move `_get_environment_with_proxy()` method (lines ~1267-1325)
- [ ] Move `_generate_env_echo_commands()` method (lines ~1327-1344)

### Step 11: Integrate PluginExecutor
- [ ] Add `__init__` to PluginExecutor accepting manager reference
- [ ] Store manager reference: `self.manager = manager`
- [ ] Update all signal emissions to use `self.manager.signalName.emit()`
- [ ] Update all `self._show_error()` to `self.manager._show_error()`
- [ ] Update access to shared state (_plugins_dir, _proxy_url, etc.)
- [ ] In plugin_manager.py, create instance: `self.executor = PluginExecutor(self)`
- [ ] Delegate calls from plugin_manager to executor
- [ ] Test plugin launch functionality
- [ ] Test environment setup
- [ ] Test command execution
- [ ] Test custom exec commands
- [ ] Commit: "Extract execution logic to plugin_executor.py"

**Estimated Time**: 60 minutes
**Risk Level**: 🟡 Medium

---

## Phase 6: Cleanup and Finalization

### Step 12: Organize plugin_manager.py
- [ ] Verify only orchestration logic remains
- [ ] Organize remaining methods by category:
  - `__init__` and initialization
  - Qt Properties and Slots (QML interface)
  - Settings management (_load_settings, _save_settings)
  - Plugin scanning and discovery
  - Helper methods (_show_error, _show_info, _find_plugin_by_name)
  - Environment variable management
  - Manual and command management
- [ ] Add section comments for clarity
- [ ] Verify all imports are correct
- [ ] Remove unused imports

### Step 13: Add Type Hints and Documentation
- [ ] Add type hints to all method signatures in plugin_utils.py
- [ ] Add type hints to all method signatures in plugin_models.py
- [ ] Add type hints to all method signatures in plugin_io.py
- [ ] Add type hints to all method signatures in plugin_executor.py
- [ ] Add/improve docstrings in all new files
- [ ] Add module-level docstrings to each file
- [ ] Update any existing documentation

### Step 14: Final Testing and Validation
- [ ] Test plugin scanning
- [ ] Test plugin launching (new plugin)
- [ ] Test plugin launching (existing plugin with venv)
- [ ] Test plugin import from disk (new)
- [ ] Test plugin import from disk (overwrite)
- [ ] Test plugin import from URL
- [ ] Test plugin export
- [ ] Test settings management (proxy, env vars, font size)
- [ ] Test manual opening
- [ ] Test command execution
- [ ] Test plugin directory opening
- [ ] Check for any Python errors or warnings
- [ ] Verify no circular imports
- [ ] Run with debug logging to check for issues
- [ ] Commit: "Finalize refactoring with documentation and testing"

**Estimated Time**: 45 minutes
**Risk Level**: 🟢 Low

---

## Phase 7: Post-Refactoring

### Step 15: Code Review and Optimization
- [ ] Review all new files for consistency
- [ ] Check for duplicate code
- [ ] Look for further optimization opportunities
- [ ] Verify error handling in all modules
- [ ] Check resource cleanup (temp files, workers)
- [ ] Measure improvement (lines per file, readability)
- [ ] Document any known issues or TODOs
- [ ] Update MESSAGE.md with refactoring summary
- [ ] Final commit: "Complete plugin_manager refactoring"
- [ ] Merge to main branch (if all tests pass)

**Estimated Time**: 30 minutes
**Risk Level**: 🟢 Low

---

## Summary Statistics

**Total Steps**: 15
**Estimated Total Time**: ~4 hours
**Files Created**: 4 new files
**Original File**: Reduced from ~1,542 to ~400 lines

## Risk Management

- 🟢 **Low Risk Steps** (1-5, 12-15): Safe operations, easy to rollback
- 🟡 **Medium Risk Steps** (6-11): Core functionality changes, test thoroughly

## Rollback Plan

If issues occur at any phase:
1. Commit all changes before each phase
2. Use `git revert` or `git reset --hard` to previous checkpoint
3. Each commit message clearly indicates the phase
4. Can rollback to any previous step

## Notes

- Each phase should be committed separately
- Test after each major change
- Keep the application runnable after each step
- Use `git stash` if needed to temporarily save work
- Run the application frequently during refactoring to catch issues early

---

## Progress Tracking

- **Started**: [Date]
- **Current Phase**: Not started
- **Completed Phases**: None
- **Estimated Completion**: [Date + 4 hours]

---

## Additional Considerations

### Future Enhancements (Post-Refactoring)
- [ ] Add unit tests for each module
- [ ] Consider adding a plugin_config.py for configuration constants
- [ ] Consider using a dependency injection framework
- [ ] Add logging decorators for better debugging
- [ ] Consider async/await patterns for I/O operations

### Documentation Updates Needed
- [ ] Update README.md with new architecture
- [ ] Create ARCHITECTURE.md documenting the new structure
- [ ] Add inline comments for complex logic
- [ ] Update any existing developer documentation
