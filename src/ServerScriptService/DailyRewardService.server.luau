-- DailyRewardService: Handles daily reward claims

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local DEBUG = true
local function dlog(...)
	if DEBUG then
		print("[DailyRewardService]", ...)
	end
end

-- Debug flag: Reset daily rewards for Nelzord
local RESET_NELZORD_DAILY_REWARDS = false -- Set to true to reset Nelzord's daily rewards on join

-- Debug flag: Simulate daily reward day (for testing)
-- Set to a number 1-7 to simulate being on that day, or nil to use normal progression
local SIMULATE_DAILY_REWARD_DAY = nil -- Example: 3 to simulate being on day 3

-- Debug: Log if the reset flag is enabled
if RESET_NELZORD_DAILY_REWARDS then
	print("[DailyRewardService] DEBUG MODE: Daily rewards will be reset for Nelzord on join")
end

-- Debug: Log if the simulate flag is enabled
if SIMULATE_DAILY_REWARD_DAY then
	print("[DailyRewardService] DEBUG MODE: Simulating daily reward day", SIMULATE_DAILY_REWARD_DAY)
end

-- DataStore for daily reward data
local dailyRewardStore = DataStoreService:GetDataStore("DailyRewards")

-- Player daily reward data: { [Player] = { currentDay = number, lastPlayDate = string, claimedToday = boolean } }
local playerDailyData: { [Player]: { currentDay: number, lastPlayDate: string, claimedToday: boolean } } = {}

-- Helper function to get date string (YYYY-MM-DD format)
local function getDateString(timestamp: number?): string
	local time = timestamp or os.time()
	local date = os.date("*t", time)
	return string.format("%04d-%02d-%02d", date.year, date.month, date.day)
end

-- Helper function to check if more than 1 day has passed
local function isMoreThanOneDayAgo(dateString: string): boolean
	local year, month, day = dateString:match("(%d+)-(%d+)-(%d+)")
	if not year or not month or not day then
		return true -- Invalid date, treat as expired
	end
	
	local lastDate = os.time({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = 0,
		min = 0,
		sec = 0
	})
	
	local currentDate = os.time({
		year = os.date("*t").year,
		month = os.date("*t").month,
		day = os.date("*t").day,
		hour = 0,
		min = 0,
		sec = 0
	})
	
	local daysDiff = math.floor((currentDate - lastDate) / 86400) -- 86400 seconds in a day
	return daysDiff > 1
end

-- Load player daily reward data
local function loadPlayerDailyData(player: Player)
	task.spawn(function()
		local success, loadedData = pcall(function()
			return dailyRewardStore:GetAsync("daily_" .. player.UserId)
		end)
		
		local data = nil
		
		-- Check if we should reset for Nelzord
		if RESET_NELZORD_DAILY_REWARDS and player.Name == "Nelzord" then
			dlog("RESET_NELZORD_DAILY_REWARDS enabled - resetting daily rewards for", player.Name)
			data = {
				currentDay = 1,
				lastPlayDate = getDateString(),
				claimedToday = false
			}
			-- Clear DataStore entry for Nelzord
			pcall(function()
				dailyRewardStore:SetAsync("daily_" .. player.UserId, data)
				dlog("Cleared DataStore entry for", player.Name)
			end)
		elseif success and loadedData then
			data = loadedData
		else
			-- Default data for new players
			data = {
				currentDay = 1,
				lastPlayDate = getDateString(),
				claimedToday = false
			}
		end
		
		local today = getDateString()
		
		-- Check if we should simulate a specific day
		if SIMULATE_DAILY_REWARD_DAY then
			data.currentDay = SIMULATE_DAILY_REWARD_DAY
			data.claimedToday = false
			dlog("Simulating day", SIMULATE_DAILY_REWARD_DAY, "for", player.Name)
		else
			-- Check if it's a new day (different from last play date)
			if data.lastPlayDate ~= today then
				-- It's a new day
				if isMoreThanOneDayAgo(data.lastPlayDate) then
					-- More than 1 day passed - reset to day 1
					dlog("More than 1 day passed for", player.Name, "- resetting to day 1")
					data.currentDay = 1
				else
					-- Exactly 1 day passed - advance to next day
					if data.currentDay < 7 then
						data.currentDay = data.currentDay + 1
						dlog("New day for", player.Name, "- advanced to day", data.currentDay)
					else
						-- Was on day 7, reset to day 1
						data.currentDay = 1
						dlog("New day for", player.Name, "- completed cycle, reset to day 1")
					end
				end
				-- Reset claimed status for new day
				data.claimedToday = false
			end
		end
		
		-- Update last play date
		data.lastPlayDate = today
		
		playerDailyData[player] = data
		
		-- Save updated data
		savePlayerDailyData(player)
		
		-- Send daily reward state to client
		sendDailyRewardState(player)
		
		dlog("Loaded daily reward data for", player.Name, "- currentDay:", data.currentDay)
	end)
end

-- Save player daily reward data
local function savePlayerDailyData(player: Player)
	local data = playerDailyData[player]
	if not data then return end
	
	task.spawn(function()
		pcall(function()
			dailyRewardStore:SetAsync("daily_" .. player.UserId, data)
			dlog("Saved daily reward data for", player.Name)
		end)
	end)
end

-- Create/fetch remotes (must be defined before use)
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
		ClaimDailyReward = ensureEvent("ClaimDailyReward"),
		DailyRewardState = ensureEvent("DailyRewardState"),
		RequestDailyRewardState = ensureEvent("RequestDailyRewardState"),
		CoinCountUpdate = ensureEvent("CoinCountUpdate"),
		LuckUpdate = ensureEvent("LuckUpdate"),
		MarbleUnlocked = ensureEvent("MarbleUnlocked"),
	}
end

local Remotes = getOrCreateRemotes()

-- Send daily reward state to client
local function sendDailyRewardState(player: Player)
	local data = playerDailyData[player]
	if not data then return end
	
	local dailyRewardState = Remotes.DailyRewardState
	if dailyRewardState then
		dailyRewardState:FireClient(player, data.currentDay, data.claimedToday)
	end
end

-- Get services
local function getCoinService()
	local success, CoinService = pcall(function()
		return require(script.Parent.CoinService)
	end)
	if success and CoinService then
		return CoinService
	end
	return nil
end

local function getMarbleService()
	local MarbleService = _G.MarbleService
	if not MarbleService then
		local success, result = pcall(function()
			return require(script.Parent.MarbleService)
		end)
		if success and result then
			MarbleService = result
		end
	end
	return MarbleService
end

local function getShopService()
	local ShopService = _G.ShopService
	if not ShopService then
		local success, result = pcall(function()
			return require(script.Parent.ShopService)
		end)
		if success and result then
			ShopService = result
		end
	end
	return ShopService
end

-- Lucky potion system (reuse from ShopService)
local playerLuckyPotions = {} -- { [Player] = { multiplier = number, endTime = number } }
local POTION_DURATION = 300 -- 5 minutes in seconds

-- Function to send luck update to client
local function sendLuckUpdate(player)
	local ShopService = getShopService()
	if ShopService and ShopService.sendLuckUpdate then
		ShopService.sendLuckUpdate(player)
	else
		-- Fallback: calculate and send directly
		local potion = playerLuckyPotions[player]
		local potionMultiplier = 1
		local timeLeft = 0
		if potion and os.time() < potion.endTime then
			potionMultiplier = potion.multiplier
			timeLeft = potion.endTime - os.time()
		end
		
		-- Get permanent luck bonus from RobuxService
		local permanentBonus = 1
		local RobuxService = _G.RobuxService
		if RobuxService and RobuxService.GetPlayerTotalLuckMultiplier then
			local success, result = pcall(function()
				return RobuxService:GetPlayerTotalLuckMultiplier(player)
			end)
			if success and result then
				permanentBonus = result
			end
		end
		
		local totalMultiplier = permanentBonus * potionMultiplier
		if Remotes.LuckUpdate then
			Remotes.LuckUpdate:FireClient(player, totalMultiplier, timeLeft)
		end
	end
end

-- Handle daily reward state requests
Remotes.RequestDailyRewardState.OnServerEvent:Connect(function(player: Player)
	sendDailyRewardState(player)
end)

-- Handle daily reward claims
Remotes.ClaimDailyReward.OnServerEvent:Connect(function(player: Player, day: number, rewardType: string, rewardAmount: number?, rewardId: string?)
	dlog("Claim request from", player.Name, "for day", day, "type:", rewardType)
	
	-- Get player's daily reward data
	local data = playerDailyData[player]
	if not data then
		warn("[DailyRewardService] No daily reward data for", player.Name)
		return
	end
	
	-- Verify player is claiming the correct day
	if day ~= data.currentDay then
		warn("[DailyRewardService] Player", player.Name, "tried to claim day", day, "but is on day", data.currentDay)
		return
	end
	
	-- Check if already claimed today
	if data.claimedToday then
		warn("[DailyRewardService] Player", player.Name, "already claimed today")
		return
	end
	
	if rewardType == "coins" then
		-- Add coins to player
		local CoinService = getCoinService()
		if not CoinService then
			warn("[DailyRewardService] CoinService not available")
			return
		end
		
		if rewardAmount and rewardAmount > 0 then
			CoinService:AddCoins(player, rewardAmount)
			dlog("Granted", rewardAmount, "coins to", player.Name)
		else
			warn("[DailyRewardService] Invalid coin amount:", rewardAmount)
		end
		
	elseif rewardType == "marble" then
		-- Grant marble to player
		local MarbleService = getMarbleService()
		if not MarbleService then
			warn("[DailyRewardService] MarbleService not available")
			return
		end
		
		if not rewardId then
			warn("[DailyRewardService] No marble ID provided")
			return
		end
		
		-- Define unlock counts for each marble
		local unlockCounts = {
			Coin = 20000,
			Diamond = 2500,
			Gold = 1000,
		}
		local totalCount = unlockCounts[rewardId] or 200 -- Default to 200 if not specified
		
		-- Check if player already has the marble
		local alreadyHasMarble = false
		if MarbleService.HasMarble and MarbleService.HasMarble(player, rewardId) then
			dlog("Player", player.Name, "already has", rewardId, "marble")
			alreadyHasMarble = true
			-- Still send unlock notification
			if Remotes.MarbleUnlocked then
				Remotes.MarbleUnlocked:FireClient(player, rewardId, 1, totalCount)
			end
		else
			-- Grant the marble
			if MarbleService.GrantMarble then
				local success = MarbleService.GrantMarble(player, rewardId)
				if success then
					dlog("Granted", rewardId, "marble to", player.Name)
					-- Send unlock notification with correct count
					if Remotes.MarbleUnlocked then
						Remotes.MarbleUnlocked:FireClient(player, rewardId, 1, totalCount)
					end
				else
					warn("[DailyRewardService] Failed to grant", rewardId, "marble to", player.Name)
				end
			else
				warn("[DailyRewardService] MarbleService.GrantMarble not available")
			end
		end
		
	elseif rewardType == "luck" then
		-- Activate 2x luck potion
		-- Remove old potion if exists
		playerLuckyPotions[player] = nil
		
		-- Add new potion (2x for 5 minutes)
		playerLuckyPotions[player] = {
			multiplier = 2.0,
			endTime = os.time() + POTION_DURATION
		}
		
		-- Send luck update to client
		sendLuckUpdate(player)
		
		dlog("Activated 2x luck potion for", player.Name, "for", POTION_DURATION, "seconds")
		
	else
		warn("[DailyRewardService] Unknown reward type:", rewardType)
		return
	end
	
	-- Mark as claimed today (don't advance day until tomorrow)
	data.claimedToday = true
	
	-- Save updated data
	savePlayerDailyData(player)
	
	-- Send updated state to client
	sendDailyRewardState(player)
	
	dlog("Player", player.Name, "claimed day", day, "- claimedToday set to true")
end)

-- Clean up expired potions
task.spawn(function()
	while true do
		task.wait(60) -- Check every minute
		local currentTime = os.time()
		for player, potion in pairs(playerLuckyPotions) do
			if currentTime >= potion.endTime then
				playerLuckyPotions[player] = nil
				if player.Parent then
					sendLuckUpdate(player)
				end
			end
		end
	end
end)

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	loadPlayerDailyData(player)
end)

-- Clean up on player leaving
Players.PlayerRemoving:Connect(function(player)
	playerLuckyPotions[player] = nil
	-- Save data before player leaves
	if playerDailyData[player] then
		savePlayerDailyData(player)
		playerDailyData[player] = nil
	end
end)

dlog("DailyRewardService initialized")

return {}
