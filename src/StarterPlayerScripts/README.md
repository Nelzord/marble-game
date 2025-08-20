# MarbleUI System - Modular Architecture

The MarbleUI system has been refactored from a single massive script (2000+ lines) into a clean, modular architecture for better maintainability and code organization.

## File Structure

### Main Entry Point
- **`MarbleUI.client.luau`** - Simple entry point that initializes the controller

### Core Modules
- **`MarbleUIController.luau`** - Main orchestrator that manages all other modules
- **`UIComponents.luau`** - Handles creation and management of individual UI elements
- **`CooldownSystem.luau`** - Manages all cooldown-related functionality for the power button
- **`InventorySystem.luau`** - Handles inventory UI and marble management
- **`RollAnimation.luau`** - Manages the rolling animation and result display

## Module Responsibilities

### MarbleUIController
- Orchestrates the initialization of all modules
- Manages the main event flow and communication between modules
- Handles UI readiness checks and health monitoring
- Sets up all event handlers and connections

### UIComponents
- Creates and configures individual UI elements (buttons, frames, labels)
- Provides reusable UI creation functions
- Handles styling and positioning of UI elements
- Manages UI element parenting and hierarchy

### CooldownSystem
- Manages power button cooldown state
- Handles cooldown timing and UI updates
- Provides cooldown validation and safety checks
- Manages pending cooldowns when UI isn't ready

### InventorySystem
- Manages player's marble collection and equipped marble
- Handles inventory UI updates and rebuilding
- Manages marble tile creation and display
- Handles texture application and rarity display

### RollAnimation
- Manages the rolling animation sequence
- Handles particle effects and visual feedback
- Manages roll result display and celebration
- Coordinates with server roll events

## Benefits of Refactoring

1. **Maintainability** - Each module has a single, clear responsibility
2. **Readability** - Code is much easier to understand and navigate
3. **Debugging** - Issues can be isolated to specific modules
4. **Reusability** - Modules can be reused in other parts of the system
5. **Testing** - Individual modules can be tested in isolation
6. **Collaboration** - Multiple developers can work on different modules simultaneously

## Usage

The system automatically initializes when the `MarbleUI.client.luau` script runs. The controller will:

1. Wait for all dependencies to be ready
2. Create the UI components
3. Set up event handlers
4. Initialize all subsystems
5. Begin monitoring and health checks

## Adding New Features

To add new features:

1. **UI Elements** - Add creation functions to `UIComponents.luau`
2. **New Systems** - Create new modules following the existing pattern
3. **Event Handling** - Add handlers in `MarbleUIController.luau`
4. **State Management** - Use the appropriate module for the feature type

## Module Communication

Modules communicate through well-defined interfaces:
- **Controller → Modules** - Direct function calls
- **Modules → Controller** - Return values and state queries
- **Modules → Modules** - Through the controller (avoid direct coupling)

This architecture ensures clean separation of concerns while maintaining efficient communication between components.
