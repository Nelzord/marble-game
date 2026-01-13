-- BadgeSystem.luau
-- Handles all badge-related functionality for levels beaten
-- Now works with server-side persistence

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BadgeSystem = {}

-- Wait for remote events
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local BadgeUnlocked = RemotesFolder:WaitForChild("BadgeUnlocked")
local BadgeUpdate = RemotesFolder:WaitForChild("BadgeUpdate")
local RequestBadges = RemotesFolder:WaitForChild("RequestBadges")

-- Badge data structure (will be updated from server)
local BADGES = {
	-- World 1 (Levels 1-8)
	{ id = "level1", name = "Level 1", description = "Complete the first level", unlocked = false, world = 1 },
	{ id = "level2", name = "Level 2", description = "Complete the second level", unlocked = false, world = 1 },
	{ id = "level3", name = "Level 3", description = "Complete the third level", unlocked = false, world = 1 },
	{ id = "level4", name = "Level 4", description = "Complete the fourth level", unlocked = false, world = 1 },
	{ id = "level5", name = "Level 5", description = "Complete the fifth level", unlocked = false, world = 1 },
	{ id = "level6", name = "Level 6", description = "Complete the sixth level", unlocked = false, world = 1 },
	{ id = "level7", name = "Level 7", description = "Complete the seventh level", unlocked = false, world = 1 },
	{ id = "level8", name = "Level 8", description = "Complete the eighth level", unlocked = false, world = 1 },
	-- World 2 (Levels 9-16)
	{ id = "level9", name = "Level 9", description = "Complete the ninth level", unlocked = false, world = 2 },
	{ id = "level10", name = "Level 10", description = "Complete the tenth level", unlocked = false, world = 2 },
	{ id = "level11", name = "Level 11", description = "Complete the eleventh level", unlocked = false, world = 2 },
	{ id = "level12", name = "Level 12", description = "Complete the twelfth level", unlocked = false, world = 2 },
	{ id = "level13", name = "Level 13", description = "Complete the thirteenth level", unlocked = false, world = 2 },
	{ id = "level14", name = "Level 14", description = "Complete the fourteenth level", unlocked = false, world = 2 },
	{ id = "level15", name = "Level 15", description = "Complete the fifteenth level", unlocked = false, world = 2 },
	{ id = "level16", name = "Level 16", description = "Complete the sixteenth level", unlocked = false, world = 2 },
}

-- Function to update badges from server data
local function updateBadgesFromServer(badgeData: { [string]: boolean })
	for _, badge in ipairs(BADGES) do
		badge.unlocked = badgeData[badge.id] == true
	end
end

-- Set up event handlers
BadgeUpdate.OnClientEvent:Connect(function(badgeData)
	print("BadgeUpdate received from server:", badgeData)
	updateBadgesFromServer(badgeData)
end)

BadgeUnlocked.OnClientEvent:Connect(function(badgeId)
	print("Badge unlocked:", badgeId)
	-- The badge data will be updated via BadgeUpdate event
end)

-- Request initial badge data from server
RequestBadges:FireServer()

-- Function to get all badges
function BadgeSystem.getAllBadges()
	return BADGES
end

-- Function to get badges by world
function BadgeSystem.getBadgesByWorld(worldNumber: number)
	local worldBadges = {}
	for _, badge in ipairs(BADGES) do
		if badge.world == worldNumber then
			table.insert(worldBadges, badge)
		end
	end
	return worldBadges
end

-- Function to get World 1 badges (levels 1-8)
function BadgeSystem.getWorld1Badges()
	return BadgeSystem.getBadgesByWorld(1)
end

-- Function to get World 2 badges (levels 9-16)
function BadgeSystem.getWorld2Badges()
	return BadgeSystem.getBadgesByWorld(2)
end

-- Function to check if World 1 is fully completed
function BadgeSystem.isWorld1Completed()
	local world1Badges = BadgeSystem.getWorld1Badges()
	for _, badge in ipairs(world1Badges) do
		if not badge.unlocked then
			return false
		end
	end
	return true
end

-- Function to check if World 2 is unlocked (requires World 1 completion)
function BadgeSystem.isWorld2Unlocked()
	return BadgeSystem.isWorld1Completed()
end

-- Function to unlock a badge by level number (now handled server-side)
-- This function is kept for compatibility but does nothing
-- Supports level numbers 1-16
function BadgeSystem.unlockBadge(levelNumber)
	print("BadgeSystem.unlockBadge called - badges are now unlocked server-side when touching Badge objects")
	return false
end

-- Function to check if a badge is unlocked
function BadgeSystem.isBadgeUnlocked(badgeId)
	for _, badge in ipairs(BADGES) do
		if badge.id == badgeId then
			return badge.unlocked
		end
	end
	return false
end

-- Function to get unlocked badges count
function BadgeSystem.getUnlockedCount()
	local count = 0
	for _, badge in ipairs(BADGES) do
		if badge.unlocked then
			count = count + 1
		end
	end
	return count
end

-- Function to reset all badges to locked (now handled server-side)
-- This function is kept for compatibility but does nothing
function BadgeSystem.resetAllBadges()
	print("BadgeSystem.resetAllBadges called - badges are now persistent and managed server-side")
	return false
end

-- Function to create a badge tile
function BadgeSystem.createBadgeTile(badge, list, grid)
	local tile = Instance.new("Frame")
	tile.Size = UDim2.fromOffset(150, 150)
	tile.BackgroundColor3 = badge.unlocked and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(60, 60, 60)
	tile.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = tile

	-- Badge icon container
	local iconContainer = Instance.new("Frame")
	iconContainer.Size = UDim2.new(1, -16, 0.6, -8)
	iconContainer.Position = UDim2.new(0, 8, 0, 8)
	iconContainer.BackgroundColor3 = badge.unlocked and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(80, 80, 80)
	iconContainer.BorderSizePixel = 0
	iconContainer.Parent = tile

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 6)
	iconCorner.Parent = iconContainer

	-- Badge icon (checkmark for unlocked, lock for locked)
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = badge.unlocked and "✓" or "🔒"
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.Parent = iconContainer

	-- Badge name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, -8, 0, 20)
	nameLabel.Position = UDim2.new(0, 4, 0.6, 4)
	nameLabel.Text = badge.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Parent = tile

	-- Badge status
	local statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundTransparency = 1
	statusLabel.Size = UDim2.new(1, -8, 0, 16)
	statusLabel.Position = UDim2.new(0, 4, 0.8, 4)
	statusLabel.Text = badge.unlocked and "Unlocked" or "Locked"
	statusLabel.TextColor3 = badge.unlocked and Color3.fromRGB(180, 255, 180) or Color3.fromRGB(220, 180, 180)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Parent = tile

	return tile
end

-- Function to refresh badges canvas size
function BadgeSystem.refreshCanvasSize(list, grid)
	if not list or not grid then
		print("refreshCanvasSize: Required UI elements (list or grid) not available, skipping")
		return
	end
	
	local abs = grid.AbsoluteContentSize
	list.CanvasSize = UDim2.new(0, 0, 0, abs.Y + 12)
end

-- Function to rebuild badges UI
function BadgeSystem.rebuildBadgesUI(list, grid, worldNumber: number?)
	if not list or not grid then
		print("rebuildBadgesUI: Required UI elements (list or grid) not available, skipping")
		return
	end
	
	-- Clear existing tiles but keep grid
	for _, child in ipairs(list:GetChildren()) do
		if child ~= grid then
			child:Destroy()
		end
	end
	
	-- If World 2 is selected, show "Coming Soon" instead of badges
	if worldNumber == 2 then
		-- Get list height to center the message
		local listHeight = list.AbsoluteSize.Y
		local messageHeight = 200
		local topOffset = (listHeight - messageHeight) / 2
		
		-- Create "Coming Soon" message
		local comingSoonFrame = Instance.new("Frame")
		comingSoonFrame.Size = UDim2.new(1, -24, 0, messageHeight)
		comingSoonFrame.Position = UDim2.new(0, 12, 0, math.max(0, topOffset))
		comingSoonFrame.BackgroundTransparency = 1
		comingSoonFrame.Parent = list
		
		local comingSoonLabel = Instance.new("TextLabel")
		comingSoonLabel.Size = UDim2.new(1, 0, 1, 0)
		comingSoonLabel.Position = UDim2.new(0, 0, 0, 0)
		comingSoonLabel.BackgroundTransparency = 1
		comingSoonLabel.Text = "Coming Soon"
		comingSoonLabel.TextColor3 = Color3.new(1, 1, 1)
		comingSoonLabel.TextScaled = true
		comingSoonLabel.Font = Enum.Font.GothamBold
		comingSoonLabel.Parent = comingSoonFrame
		
		-- Set canvas size to show the message
		list.CanvasSize = UDim2.new(0, 0, 0, listHeight)
		return
	end
	
	-- Get badges to display
	local badgesToShow
	if worldNumber then
		badgesToShow = BadgeSystem.getBadgesByWorld(worldNumber)
	else
		badgesToShow = BadgeSystem.getAllBadges()
	end
	
	for _, badge in ipairs(badgesToShow) do
		local tile = BadgeSystem.createBadgeTile(badge, list, grid)
		tile.Parent = list
	end
	
	BadgeSystem.refreshCanvasSize(list, grid)
end

return BadgeSystem
