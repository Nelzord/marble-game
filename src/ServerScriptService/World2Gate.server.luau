-- World2Gate: Controls access to World 2 based on badge count
-- Players need 8 badges to pass through World2Gate

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local REQUIRED_BADGES = 8

-- Wait for BadgeService to be available
local BadgeService = nil
local function waitForBadgeService()
	while not _G.BadgeService do
		task.wait(0.1)
	end
	BadgeService = _G.BadgeService
end

-- Start waiting for BadgeService in a separate thread
task.spawn(waitForBadgeService)

-- Function to check if player can pass through gate
local function canPlayerPass(player: Player): boolean
	if not BadgeService then
		return false
	end
	
	local badgeCount = BadgeService.getUnlockedCount(player)
	return badgeCount >= REQUIRED_BADGES
end

-- Track players who are on cooldown (to prevent spam checks)
local playerCooldowns: { [Player]: boolean } = {}
local gateDebounce = false

-- Function to handle player touching the gate
local function onGateTouched(hit: BasePart, gatePart: BasePart)
	-- Check if the hit part is a HumanoidRootPart (marble character structure)
	if hit.Name ~= "HumanoidRootPart" then
		-- It might be another part, check if it's inside a character
		local character = hit.Parent
		if character and character:IsA("Model") then
			-- Check if this model has a HumanoidRootPart (it's a character)
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp == hit then
				-- This is the HRP, continue
			else
				-- Not the HRP, might be a different part of the character
				-- Try to get the character from the hit part's parent
				if character:FindFirstChild("Humanoid") then
					-- It's a character, but we want to check when HRP touches, not other parts
					return
				else
					-- Not a character at all
					return
				end
			end
		else
			-- Not a character model
			return
		end
	end
	
	-- Get the character model (parent of HumanoidRootPart)
	local character = hit.Parent
	if not character or not character:IsA("Model") then
		return
	end
	
	-- Check if it's a marble character
	if not character:GetAttribute("IsMarbleCharacter") then
		return
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	
	-- Prevent spam checks with cooldown
	if playerCooldowns[player] then
		return
	end
	
	-- Wait for BadgeService to be ready
	if not BadgeService then
		while not BadgeService do
			task.wait(0.1)
		end
	end
	
	-- Check if player can pass
	local canPass = canPlayerPass(player)
	
	if canPass then
		-- Set cooldown for this player
		playerCooldowns[player] = true
		task.delay(2, function()
			playerCooldowns[player] = nil
		end)
		
		-- Temporarily make gate non-collidable so player can pass through
		-- Use a global debounce to prevent multiple players from interfering
		if not gateDebounce then
			gateDebounce = true
			local originalCanCollide = gatePart.CanCollide
			gatePart.CanCollide = false
			
			task.wait(1) -- Give player time to pass through
			
			gatePart.CanCollide = originalCanCollide
			gateDebounce = false
		end
	else
		-- Gate remains collidable, blocking the player
		
		-- Set a short cooldown to prevent spam
		playerCooldowns[player] = true
		task.delay(1, function()
			playerCooldowns[player] = nil
		end)
	end
end

-- Function to setup gate detection and control
local function setupGate()
	-- Find World2Gate - first check in World2 folder, then directly in Workspace
	local gate = nil
	local world2Folder = Workspace:FindFirstChild("World2")
	if world2Folder then
		gate = world2Folder:FindFirstChild("World2Gate")
	end
	
	-- If not found in World2 folder, check directly in Workspace
	if not gate then
		gate = Workspace:FindFirstChild("World2Gate")
	end
	
	if not gate then
		-- Monitor for World2 folder to be added
		Workspace.ChildAdded:Connect(function(child)
			if child.Name == "World2" then
				task.wait(0.5) -- Wait for folder to fully load
				local world2Gate = child:FindFirstChild("World2Gate")
				if world2Gate then
					task.wait(0.5)
					setupGate()
				end
			elseif child.Name == "World2Gate" then
				task.wait(0.5)
				setupGate()
			end
		end)
		
		-- Also monitor World2 folder for World2Gate to be added
		if world2Folder then
			world2Folder.ChildAdded:Connect(function(child)
				if child.Name == "World2Gate" then
					task.wait(0.5)
					setupGate()
				end
			end)
		end
		return
	end
	
	-- Find the main part (could be a Model or a Part)
	local mainPart = nil
	if gate:IsA("Model") then
		mainPart = gate:FindFirstChild("HumanoidRootPart") or gate:FindFirstChild("Part") or gate:FindFirstChildOfClass("BasePart")
	elseif gate:IsA("BasePart") then
		mainPart = gate
	end
	
	if not mainPart then
		return
	end
	
	-- Ensure gate is collidable by default (blocks players without enough badges)
	if not mainPart.CanCollide then
		mainPart.CanCollide = true
	end
	
	-- Ensure CanTouch is enabled (required for Touched events)
	mainPart.CanTouch = true
	
	-- Connect touch event
	mainPart.Touched:Connect(function(hit)
		onGateTouched(hit, mainPart)
	end)
	
	-- Clean up player cooldowns when they leave
	Players.PlayerRemoving:Connect(function(player)
		playerCooldowns[player] = nil
	end)
end

-- Initialize
task.spawn(function()
	-- Wait for BadgeService to be ready
	while not BadgeService do
		task.wait(0.1)
	end
	
	-- Setup gate
	setupGate()
end)
