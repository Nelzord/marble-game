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
	{ id = "level1", name = "Level 1", description = "Complete the first level", unlocked = false },
	{ id = "level2", name = "Level 2", description = "Complete the second level", unlocked = false },
	{ id = "level3", name = "Level 3", description = "Complete the third level", unlocked = false },
	{ id = "level4", name = "Level 4", description = "Complete the fourth level", unlocked = false },
	{ id = "level5", name = "Level 5", description = "Complete the fifth level", unlocked = false },
	{ id = "level6", name = "Level 6", description = "Complete the sixth level", unlocked = false },
	{ id = "level7", name = "Level 7", description = "Complete the seventh level", unlocked = false },
	{ id = "level8", name = "Level 8", description = "Complete the eighth level", unlocked = false },
	{ id = "level9", name = "Level 9 (World 2)", description = "Complete the ninth level", unlocked = false },
	{ id = "level10", name = "Level 10 (World 2)", description = "Complete the tenth level", unlocked = false },
	{ id = "level11", name = "Level 11 (World 2)", description = "Complete the eleventh level", unlocked = false },
	{ id = "level12", name = "Level 12 (World 2)", description = "Complete the twelfth level", unlocked = false },
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

-- Function to unlock a badge by level number (now handled server-side)
-- This function is kept for compatibility but does nothing
-- Supports level numbers 1-12
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
function BadgeSystem.rebuildBadgesUI(list, grid)
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
	
	for _, badge in ipairs(BadgeSystem.getAllBadges()) do
		local tile = BadgeSystem.createBadgeTile(badge, list, grid)
		tile.Parent = list
	end
	
	BadgeSystem.refreshCanvasSize(list, grid)
end

return BadgeSystem
