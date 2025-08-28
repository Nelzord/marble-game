# Badges System

The Badges System has been added to the Marble Game to track player progress through levels. Players can view their badges by clicking the "Badges" button in the UI.

## Features

- **12 Level Badges**: One badge for each level (Level 1 through Level 12)
- **Visual Status**: Each badge shows whether it's locked or unlocked
- **Progress Tracking**: Players can see their completion progress at a glance
- **Clean UI**: Badges are displayed in a 4-column grid layout

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
- Scrollable grid of 12 badges

## Technical Implementation

### Files Added
- `BadgeSystem.luau` - Core badge functionality
- `BadgeTestScript.luau` - Testing script for development

### Files Modified
- `UIComponents.luau` - Added badges button and frame creation
- `MarbleUIController.luau` - Integrated badges system into main UI

### Badge System Functions
- `getAllBadges()` - Returns all 12 badges
- `unlockBadge(levelNumber)` - Unlocks a specific level badge
- `isBadgeUnlocked(badgeId)` - Checks if a badge is unlocked
- `getUnlockedCount()` - Returns count of unlocked badges
- `resetAllBadges()` - Resets all badges to locked state
- `createBadgeTile()` - Creates UI tile for a badge
- `rebuildBadgesUI()` - Rebuilds the entire badges display

## Testing

The `BadgeTestScript.luau` provides keyboard controls for testing:

- **1-9**: Unlock badges for levels 1-9
- **0**: Unlock badge for level 10
- **-**: Unlock badge for level 11
- **=**: Unlock badge for level 12
- **R**: Reset all badges to locked
- **I**: Show badge information in console

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
BadgeSystem.unlockBadge(levelNumber) -- levelNumber 1-12
```

This should be called when a player completes a level, typically from the server-side level completion logic.
