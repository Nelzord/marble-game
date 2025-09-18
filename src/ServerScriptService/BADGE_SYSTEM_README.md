# Badge System with Persistence

This badge system allows players to unlock badges by finding them in the workspace and persists their progress across sessions.

## How It Works

### Badge Objects
- Create a folder named "Badges" in the workspace
- Place objects named "Badge1", "Badge2", "Badge3", etc. up to "Badge8" inside the Badges folder
- When a player touches these objects, the corresponding badge is unlocked
- The badge object is automatically destroyed after collection

### Persistence
- Badge progress is saved to DataStore and persists across sessions
- Uses the same pattern as the existing CoinService
- Data is automatically loaded when players join and saved when they leave

### UI Integration
- The existing BadgeSystem UI automatically updates when badges are unlocked
- Badges show as locked/unlocked with visual indicators
- Real-time updates when badges are collected

## Files Added

### Server Scripts
- `BadgeService.server.luau` - Main service handling badge persistence and unlocking
- `BadgeTrigger.server.luau` - Detects when players collide with badge objects
- `BadgeTest.server.luau` - Test script with admin commands

### Client Scripts
- `BadgeSystem.luau` - Updated to work with server-side persistence

## Setup Instructions

1. **Create Badges Folder**: Create a folder named "Badges" in your workspace in Roblox Studio
2. **Create Badge Objects**: Place objects named "Badge1" through "Badge8" inside the Badges folder
3. **Scripts**: The server scripts are already in place and will work automatically


## Badge Object Requirements

1. **Create a folder** named "Badges" in the workspace
2. **Inside the Badges folder**, place objects named exactly:
   - "Badge1" (unlocks Level 1 badge)
   - "Badge2" (unlocks Level 2 badge)
   - "Badge3" (unlocks Level 3 badge)
   - "Badge4" (unlocks Level 4 badge)
   - "Badge5" (unlocks Level 5 badge)
   - "Badge6" (unlocks Level 6 badge)
   - "Badge7" (unlocks Level 7 badge)
   - "Badge8" (unlocks Level 8 badge)

The objects can be:
- Models with a Part or HumanoidRootPart
- Single Parts
- Any object with a BasePart that can be touched

## Data Structure

Badge data is stored in DataStore with the key format: `"badges_" .. player.UserId`

The data structure is:
```lua
{
    ["level1"] = true,  -- if unlocked
    ["level2"] = false, -- if locked
    -- etc.
}
```

## Remote Events

The system uses these RemoteEvents (automatically created):
- `BadgeUnlocked` - Fired when a badge is unlocked (client notification)
- `BadgeUpdate` - Sends current badge status to client
- `RequestBadges` - Client requests current badge status

## Integration with Existing UI

The existing badge UI will automatically work with this system:
- Badges show as locked/unlocked based on server data
- Real-time updates when badges are collected
- Visual indicators (checkmark for unlocked, lock for locked)
- Progress tracking across sessions

## Debugging

Enable debug output by setting `BADGE_DEBUG = true` in the server scripts to see detailed logging of badge operations.

## Future Enhancements

- Badge collection animations
- Sound effects for badge unlocking
- Achievement notifications
- Special effects when all badges are collected
- Badge collection statistics
