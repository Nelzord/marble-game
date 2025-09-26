# Badges System

The Badges System has been added to the Marble Game to track player progress through levels. Players can view their badges by clicking the "Badges" button in the UI.

## Features

- **16 Level Badges**: One badge for each level across two worlds
  - **World 1**: Levels 1-8 (8 badges)
  - **World 2**: Levels 9-16 (8 badges)
- **World Separation**: Toggle between World 1 and World 2 with dedicated tabs
- **Progressive Unlock**: World 2 is locked until all World 1 badges are collected
- **Visual Status**: Each badge shows whether it's locked or unlocked
- **Progress Tracking**: Players can see their completion progress at a glance
- **Clean UI**: Badges are displayed in a 4-column grid layout with world selection

## How It Works

### Badge States
- **Locked**: Shows a lock icon (🔒) and dark gray background
- **Unlocked**: Shows a checkmark (✓) and green background

### Badge Information
Each badge displays:
- Level name (e.g., "Level 1", "Level 2")
- Current status ("Locked" or "Unlocked")
- Visual icon indicating locked/unlocked state

## UI Integration

### Badges Button
- Located below the Inventory button
- Opens the Badges window when clicked
- Closes the Inventory window when opened (and vice versa)

### Badges Window
- Similar layout to the Inventory window
- Header shows "BADGES"
- Close button (X) in top-right corner
- World selection tabs (World 1 / World 2)
- Scrollable grid of badges for the selected world

## Technical Implementation

### Files Added
- `BadgeSystem.luau` - Core badge functionality
- `BadgeTestScript.luau` - Testing script for development

### Files Modified
- `UIComponents.luau` - Added badges button and frame creation
- `MarbleUIController.luau` - Integrated badges system into main UI

### Badge System Functions
- `getAllBadges()` - Returns all 16 badges
- `getBadgesByWorld(worldNumber)` - Returns badges for a specific world
- `getWorld1Badges()` - Returns World 1 badges (levels 1-8)
- `getWorld2Badges()` - Returns World 2 badges (levels 9-16)
- `isWorld1Completed()` - Checks if all World 1 badges are unlocked
- `isWorld2Unlocked()` - Checks if World 2 is unlocked (requires World 1 completion)
- `unlockBadge(levelNumber)` - Unlocks a specific level badge
- `isBadgeUnlocked(badgeId)` - Checks if a badge is unlocked
- `getUnlockedCount()` - Returns count of unlocked badges
- `resetAllBadges()` - Resets all badges to locked state
- `createBadgeTile()` - Creates UI tile for a badge
- `rebuildBadgesUI(list, grid, worldNumber?)` - Rebuilds badges display for specific world

## Testing

The `BadgeTestScript.luau` provides keyboard controls for testing:

- **1-16**: Unlock badges for levels 1-16
- **R**: Reset all badges to locked
- **I**: Show badge information in console

The `BadgeWorldTest.luau` provides additional testing for world separation:

- Tests world filtering functionality
- Verifies correct badge counts per world
- Validates world-specific badge retrieval

## Future Enhancements

- **Persistence**: Save badge progress to player data
- **Animations**: Add unlock animations when badges are earned
- **Sound Effects**: Audio feedback for badge unlocking
- **Achievement System**: Expand beyond just level completion
- **Custom Badges**: Special badges for unique accomplishments

## Usage in Game

To unlock badges in actual gameplay, call:
```lua
local BadgeSystem = require(path.to.BadgeSystem)
BadgeSystem.unlockBadge(levelNumber) -- levelNumber 1-16
```

This should be called when a player completes a level, typically from the server-side level completion logic.

## World Separation

The badges are now organized into two worlds:

- **World 1**: Contains levels 1-8 (8 badges total) - Always accessible
- **World 2**: Contains levels 9-16 (8 badges total) - Locked until all World 1 badges are collected

### World Unlock System

- **World 1**: Always accessible to players
- **World 2**: Locked by default, shows "World 2 (Locked)" in the tab
- **Unlock Condition**: Complete all 8 badges in World 1
- **Visual Feedback**: World 2 tab changes from "World 2 (Locked)" to "World 2" when unlocked
- **Click Prevention**: Players cannot click on World 2 tab when locked

Players can switch between worlds using the tab buttons in the badges UI. The active world is highlighted in green, while the inactive world appears in gray. When World 2 is locked, it appears darker and shows a "Locked" indicator.
