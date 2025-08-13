# UI Refactoring Documentation

## Overview
The MarbleUI client script has been refactored from a single 2008-line file into a modular structure with separate modules for different UI components. This significantly improves code organization, maintainability, and readability.

## New Structure

### 1. UIManager.luau
- **Purpose**: Main UI coordination and state management
- **Responsibilities**:
  - Creates the main ScreenGui
  - Coordinates between all UI modules
  - Handles main event wiring
  - Manages global UI state (owned marbles, equipped marble)
  - Provides utility functions for other modules

### 2. PowerButton.luau
- **Purpose**: Power button with cooldown functionality
- **Responsibilities**:
  - Creates and manages the power button UI
  - Handles cooldown logic and display
  - Manages ability activation
  - Provides cooldown state validation and safety checks

### 3. RollAnimation.luau
- **Purpose**: Rolling animation UI and logic
- **Responsibilities**:
  - Creates the rolling animation overlay
  - Manages particle effects and animations
  - Handles roll result display
  - Coordinates with server roll events

### 4. InventoryUI.luau
- **Purpose**: Inventory display and management
- **Responsibilities**:
  - Creates the inventory grid interface
  - Manages marble tile creation and display
  - Handles equip/unequip functionality
  - Manages inventory visibility toggle

## Benefits of Refactoring

### Code Organization
- **Before**: 2008 lines in a single file with mixed responsibilities
- **After**: ~30 lines in main file + 4 focused modules (~200-400 lines each)

### Maintainability
- Each module has a single, clear responsibility
- Easier to locate and fix specific functionality
- Reduced risk of breaking unrelated features when making changes

### Reusability
- Modules can be easily reused in other parts of the game
- Clear interfaces between modules
- Easier to test individual components

### Debugging
- Issues can be isolated to specific modules
- Clearer error messages and stack traces
- Easier to add logging and debugging to specific features

## Module Dependencies

```
MarbleUI.client.luau (Main Entry Point)
├── UIManager.luau
│   ├── PowerButton.luau
│   ├── RollAnimation.luau
│   └── InventoryUI.luau
└── MarblesModule.luau (Shared dependency)
```

## Usage

The main client script now simply:
1. Requires all UI modules
2. Sets up module references in UIManager
3. Initializes the UI system

All complex UI logic is handled by the respective modules.

## Migration Notes

- All existing functionality has been preserved
- Event handling is now centralized in UIManager
- State management is cleaner and more organized
- Debug logging has been maintained for troubleshooting

## Future Improvements

With this modular structure, future enhancements can be made more easily:
- Add new UI components by creating new modules
- Modify existing functionality without affecting other parts
- Implement unit tests for individual modules
- Add configuration options per module
- Create UI themes or skins by modifying individual modules
