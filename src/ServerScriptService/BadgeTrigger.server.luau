-- BadgeTrigger: Detects when players collide with Badge1-Badge8 objects and unlocks badges
-- Badge objects should be created manually in Roblox Studio
-- This script should be placed in ServerScriptService

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BADGE_DEBUG = true
local function clog(...)
	if BADGE_DEBUG then
		print("[BadgeTrigger]", ...)
	end
end

clog("initializing...")

-- Wait for BadgeService to be available
local BadgeService = nil
local function waitForBadgeService()
	while not _G.BadgeService do
		task.wait(0.1)
	end
	BadgeService = _G.BadgeService
	clog("BadgeService found and ready")
end

-- Start waiting for BadgeService in a separate thread
task.spawn(waitForBadgeService)

-- Function to handle badge collection
local function onBadgeTouched(hit: BasePart, badgeNumber: number)
	local character = hit.Parent
	local humanoid = character:FindFirstChild("Humanoid")
	
	if not humanoid then return end
	
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end
	
	-- Wait for BadgeService to be ready
	if not BadgeService then
		clog("BadgeService not ready yet, waiting...")
		while not BadgeService do
			task.wait(0.1)
		end
	end
	
	local badgeId = BadgeService.getBadgeIdByNumber(badgeNumber)
	if not badgeId then
		clog("Invalid badge number:", badgeNumber)
		return
	end
	
	-- Check if already unlocked
	if BadgeService.isBadgeUnlocked(player, badgeId) then
		clog("Badge", badgeId, "already unlocked for", player.Name)
		return
	end
	
	-- Unlock the badge
	local success = BadgeService.unlockBadge(player, badgeId)
	if success then
		clog("Successfully unlocked badge", badgeId, "for", player.Name)
		
		-- Optional: Destroy the badge object after collection
		local badgeObject = hit.Parent
		if badgeObject and badgeObject.Name == "Badge" .. badgeNumber then
			badgeObject:Destroy()
			clog("Destroyed badge object Badge" .. badgeNumber)
		end
	else
		clog("Failed to unlock badge", badgeId, "for", player.Name)
	end
end

-- Function to setup badge detection
local function setupBadgeDetection()
	clog("Setting up badge detection...")
	
	-- Look for Badges folder first
	local badgesFolder = Workspace:FindFirstChild("Badges")
	if not badgesFolder then
		clog("Badges folder not found in Workspace")
		return
	end
	
	clog("Found Badges folder")
	
	-- Look for existing badge objects in the Badges folder
	for i = 1, 8 do
		local badgeName = "Badge" .. i
		local badgeObject = badgesFolder:FindFirstChild(badgeName)
		
		if badgeObject then
			clog("Found badge object:", badgeName)
			
			-- Find the main part (could be a Model or a Part)
			local mainPart = nil
			if badgeObject:IsA("Model") then
				mainPart = badgeObject:FindFirstChild("HumanoidRootPart") or badgeObject:FindFirstChild("Part")
			elseif badgeObject:IsA("BasePart") then
				mainPart = badgeObject
			end
			
			if mainPart then
				-- Connect touch event
				local connection
				connection = mainPart.Touched:Connect(function(hit)
					onBadgeTouched(hit, i)
				end)
				
				clog("Connected touch detection for", badgeName)
			else
				clog("Could not find main part for", badgeName)
			end
		else
			clog("Badge object not found:", badgeName)
		end
	end
end

-- Function to monitor for new badge objects
local function monitorForNewBadges()
	-- Monitor for new Badges folder
	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "Badges" then
			clog("New Badges folder detected, setting up badge detection")
			task.wait(0.5) -- Wait for folder to fully load
			setupBadgeDetection()
		end
	end)
	
	-- Monitor for new badge objects in the Badges folder
	local function monitorBadgesFolder()
		local badgesFolder = Workspace:FindFirstChild("Badges")
		if badgesFolder then
			badgesFolder.ChildAdded:Connect(function(child)
				-- Check if it's a badge object
				local badgeNumber = string.match(child.Name, "^Badge(%d+)$")
				if badgeNumber then
					local num = tonumber(badgeNumber)
					if num and num >= 1 and num <= 8 then
						clog("New badge object detected in Badges folder:", child.Name)
						
						-- Wait a moment for the object to fully load
						task.wait(0.5)
						
						-- Find the main part
						local mainPart = nil
						if child:IsA("Model") then
							mainPart = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Part")
						elseif child:IsA("BasePart") then
							mainPart = child
						end
						
						if mainPart then
							-- Connect touch event
							mainPart.Touched:Connect(function(hit)
								onBadgeTouched(hit, num)
							end)
							
							clog("Connected touch detection for new", child.Name)
						else
							clog("Could not find main part for new", child.Name)
						end
					end
				end
			end)
		end
	end
	
	-- Start monitoring the Badges folder
	monitorBadgesFolder()
end

-- Initialize
task.spawn(function()
	-- Wait for BadgeService to be ready
	while not BadgeService do
		task.wait(0.1)
	end
	
	-- Setup detection for existing badges
	setupBadgeDetection()
	
	-- Monitor for new badges
	monitorForNewBadges()
	
	clog("BadgeTrigger fully initialized")
end)

clog("BadgeTrigger script loaded")
