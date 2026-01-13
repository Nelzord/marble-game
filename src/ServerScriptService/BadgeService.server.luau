-- BadgeService: Handles badge unlocking and persistence across sessions
-- Similar to CoinService but for badge progress

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RobloxBadgeService = game:GetService("BadgeService")

local BADGE_DEBUG = true
local RESET_BADGES = false -- Set to true to reset all player badges on join

-- Roblox badge ID for first join
local FIRST_JOIN_BADGE_ID = 827475206998729

local function clog(...)
	if BADGE_DEBUG then
		print("[BadgeService]", ...)
	end
end

clog("initializing...")
if RESET_BADGES then
	clog("WARNING: RESET_BADGES is enabled - all player badges will be reset!")
end

-- Create/fetch remotes
local function getOrCreateRemotes()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	local function ensureEvent(name: string)
		local evt = folder:FindFirstChild(name)
		if not evt then
			evt = Instance.new("RemoteEvent")
			evt.Name = name
			evt.Parent = folder
		end
		return evt :: RemoteEvent
	end
	return {
		BadgeUnlocked = ensureEvent("BadgeUnlocked"),
		BadgeUpdate = ensureEvent("BadgeUpdate"),
		RequestBadges = ensureEvent("RequestBadges"),
		BadgeTouched = ensureEvent("BadgeTouched"),
	}
end

local Remotes = getOrCreateRemotes()

-- Badge data structure
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

-- Persistence
local badgesStore = DataStoreService:GetDataStore("MarbleBadges")
local playerBadges: { [Player]: { [string]: boolean } } = {}

-- Function to get player's badge data
local function getBadges(player: Player): { [string]: boolean }
	return playerBadges[player] or {}
end

-- Function to send badge update to client
local function sendBadgeUpdate(player: Player)
	local badges = getBadges(player)
	Remotes.BadgeUpdate:FireClient(player, badges)
	clog("Sent badge update to", player.Name, "with", #badges, "unlocked badges")
end

-- Function to unlock a badge for a player
local function unlockBadge(player: Player, badgeId: string): boolean
	if not player or not player.Parent then
		clog("Cannot unlock badge for invalid player")
		return false
	end
	
	-- Validate badge ID
	local validBadge = false
	for _, badge in ipairs(BADGES) do
		if badge.id == badgeId then
			validBadge = true
			break
		end
	end
	
	if not validBadge then
		clog("Invalid badge ID:", badgeId)
		return false
	end
	
	-- Initialize player badges if needed
	if not playerBadges[player] then
		playerBadges[player] = {}
	end
	
	-- Check if already unlocked
	if playerBadges[player][badgeId] then
		clog("Badge", badgeId, "already unlocked for", player.Name)
		return false
	end
	
	-- Unlock the badge
	playerBadges[player][badgeId] = true
	clog("Unlocked badge", badgeId, "for", player.Name)
	
	-- Send update to client
	sendBadgeUpdate(player)
	
	-- Fire badge unlocked event for UI feedback
	Remotes.BadgeUnlocked:FireClient(player, badgeId)
	
	-- Save to DataStore
	task.spawn(function()
		pcall(function()
			badgesStore:SetAsync("badges_" .. player.UserId, playerBadges[player])
			clog("Saved badge data to DataStore for", player.Name)
		end)
	end)
	
	return true
end

-- Function to check if a badge is unlocked
local function isBadgeUnlocked(player: Player, badgeId: string): boolean
	local badges = getBadges(player)
	return badges[badgeId] == true
end

-- Function to get all badges for a player
local function getAllBadges(player: Player)
	local badges = getBadges(player)
	local result = {}
	
	for _, badge in ipairs(BADGES) do
		table.insert(result, {
			id = badge.id,
			name = badge.name,
			description = badge.description,
			unlocked = badges[badge.id] == true
		})
	end
	
	return result
end

-- Function to get unlocked count
local function getUnlockedCount(player: Player): number
	local badges = getBadges(player)
	local count = 0
	for _, _ in pairs(badges) do
		count = count + 1
	end
	return count
end

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	clog("Player joined:", player.Name)
	
	local badges = {}
	
	-- Check if we should reset badges
	if RESET_BADGES then
		clog("RESET_BADGES enabled - starting fresh for", player.Name)
		badges = {} -- Start with no badges unlocked
	else
		-- Load badge data from DataStore
		local success, result = pcall(function()
			return badgesStore:GetAsync("badges_" .. player.UserId)
		end)
		
		if success and result then
			badges = result
			clog("Loaded badge data for", player.Name, ":", badges)
		else
			clog("Failed to load badge data for", player.Name, "or no data found")
		end
	end
	
	playerBadges[player] = badges
	
	-- Award first join Roblox badge
	task.spawn(function()
		local success, hasBadge = pcall(function()
			return RobloxBadgeService:UserHasBadgeAsync(player.UserId, FIRST_JOIN_BADGE_ID)
		end)
		
		if success and not hasBadge then
			-- Player doesn't have the badge yet, award it
			local awardSuccess, result = pcall(function()
				RobloxBadgeService:AwardBadge(player.UserId, FIRST_JOIN_BADGE_ID)
				return true
			end)
			
			if awardSuccess then
				clog("Awarded first join badge", FIRST_JOIN_BADGE_ID, "to", player.Name)
			else
				clog("Failed to award first join badge to", player.Name, ":", result)
			end
		elseif success and hasBadge then
			clog("Player", player.Name, "already has first join badge")
		else
			clog("Failed to check first join badge status for", player.Name)
		end
	end)
	
	-- Send initial badge update
	sendBadgeUpdate(player)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	local badges = getBadges(player)
	
	-- Save to DataStore
	pcall(function()
		badgesStore:SetAsync("badges_" .. player.UserId, badges)
		clog("Saved badge data on player leave for", player.Name)
	end)
	
	playerBadges[player] = nil
end)

-- Handle badge unlock requests
Remotes.RequestBadges.OnServerEvent:Connect(function(player)
	clog("Badge request from", player.Name)
	sendBadgeUpdate(player)
end)

-- Public API
local BadgeService = {}

function BadgeService.unlockBadge(player: Player, badgeId: string): boolean
	return unlockBadge(player, badgeId)
end

function BadgeService.isBadgeUnlocked(player: Player, badgeId: string): boolean
	return isBadgeUnlocked(player, badgeId)
end

function BadgeService.getAllBadges(player: Player)
	return getAllBadges(player)
end

function BadgeService.getUnlockedCount(player: Player): number
	return getUnlockedCount(player)
end

function BadgeService.getBadgeIdByNumber(badgeNumber: number): string?
	if badgeNumber >= 1 and badgeNumber <= 16 then
		return "level" .. badgeNumber
	end
	return nil
end

function BadgeService.getBadgeNameByNumber(badgeNumber: number): string?
	if badgeNumber >= 1 and badgeNumber <= 16 then
		for _, badge in ipairs(BADGES) do
			if badge.id == "level" .. badgeNumber then
				return badge.name
			end
		end
	end
	return nil
end

-- Expose Remotes for other scripts
function BadgeService.getRemotes()
	return Remotes
end

-- Function to reset all badges for a player
function BadgeService.resetPlayerBadges(player: Player): boolean
	if not player or not player.Parent then
		clog("Cannot reset badges for invalid player")
		return false
	end
	
	playerBadges[player] = {}
	sendBadgeUpdate(player)
	
	-- Save empty badge data to DataStore
	task.spawn(function()
		pcall(function()
			badgesStore:SetAsync("badges_" .. player.UserId, {})
			clog("Reset and saved empty badge data for", player.Name)
		end)
	end)
	
	return true
end

-- Export for other scripts
_G.BadgeService = BadgeService

clog("BadgeService initialized")
