# Extract Plugin model to plugin_models.py

## Changes
- Created new file `act_aio/plugin_models.py` containing the `Plugin` data class
- Moved `Plugin` class from `plugin_manager.py` to `plugin_models.py`
- Added proper imports (`Path`, `Dict`, `Any`) to the new module
- Updated `plugin_manager.py` to import `Plugin` from `plugin_models`
- Removed old `Plugin` class definition from `plugin_manager.py`

## Testing
- Verified no circular dependencies
- Tested application launch successfully
- Confirmed plugin scanning functionality works correctly

## Impact
- Reduces `plugin_manager.py` by ~27 lines
- Improves code organization by separating data models
- No functional changes, pure refactoring

## Phase
Phase 3: Extract Data Models (Step 4-5) - **COMPLETED**
