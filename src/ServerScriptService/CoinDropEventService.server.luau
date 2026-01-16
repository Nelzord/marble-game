-- CoinDropEventService: Manages periodic coin drop events
-- 5 minute countdown, then coins drop at center, then over spawn locations for 30 seconds

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENT_INTERVAL = 600 -- 10 minutes in seconds
local DROP_DURATION = 30 -- 30 seconds of dropping
local COUNTDOWN_TIME = 300 -- 5 minutes countdown before event
local COINS_PER_SECOND = 2 -- Coins spawned per second during event
local CENTER_DROP_HEIGHT = 50 -- Height above center to drop from
local SPAWN_DROP_HEIGHT = 30 -- Height above spawn to drop from

local DEBUG = true
local function dlog(...)
	if DEBUG then
		print("[CoinDropEventService]", ...)
	end
end

-- Track current event state for new players
local currentEventState = {
	isCountdown = false,
	isEventActive = false,
	timeRemaining = 0,
	eventStartTime = 0,
}

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
		CoinDropEventStart = ensureEvent("CoinDropEventStart"),
		CoinDropEventEnd = ensureEvent("CoinDropEventEnd"),
		CoinDropCountdown = ensureEvent("CoinDropCountdown"),
	}
end

local Remotes = getOrCreateRemotes()

-- Get CoinService
local CoinService = require(script.Parent.CoinService)

-- Track active event coins for efficient batch updates (reduces data ping)
local activeEventCoins: { { coin: Model, root: BasePart, sensor: BasePart, startTime: number } } = {}
local coinUpdateConnection: RBXScriptConnection? = nil

-- Helper function to get center of map
local function getMapCenter(): Vector3
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		return baseplate.Position
	end
	-- Fallback to origin
	return Vector3.new(0, 0, 0)
end

-- Helper function to get all spawn locations
local function getSpawnLocations(): { Vector3 }
	local spawns: { Vector3 } = {}
	
	-- Find SpawnLocation objects
	for _, spawnLocation in ipairs(workspace:GetDescendants()) do
		if spawnLocation:IsA("SpawnLocation") then
			table.insert(spawns, spawnLocation.Position)
		end
	end
	
	-- If no spawn locations found, use default
	if #spawns == 0 then
		table.insert(spawns, Vector3.new(0, 10, 0))
	end
	
	return spawns
end

-- Create a coin at a specific position (similar to CoinService.createCoin but with custom position)
local function createCoinAtPosition(position: Vector3)
	local coin = Instance.new("Model")
	coin.Name = "Coin"
	coin.Parent = workspace

	local root = Instance.new("Part")
	root.Name = "CoinRoot"
	root.Shape = Enum.PartType.Cylinder
	root.Size = Vector3.new(0.5, 3, 3)
	root.Color = Color3.fromRGB(255, 215, 0)
	root.Material = Enum.Material.Metal
	root.Anchored = false -- Unanchored so it falls
	root.CanCollide = true -- Can collide so it bounces/lands
	root.Parent = coin

	coin:PivotTo(CFrame.new(position))
	
	-- Track if coin has landed
	local hasLanded = false
	local lastPosition = position
	local stationaryFrames = 0
	
	-- Monitor coin to anchor it once it lands
	task.spawn(function()
		while coin and coin.Parent and not hasLanded do
			task.wait(0.1)
			if not root or not root.Parent then break end
			
			local currentPos = root.Position
			local distanceMoved = (currentPos - lastPosition).Magnitude
			
			-- If coin hasn't moved much, it's likely landed
			if distanceMoved < 0.1 then
				stationaryFrames = stationaryFrames + 1
				if stationaryFrames >= 3 then -- 0.3 seconds of being stationary
					hasLanded = true
					root.Anchored = true
					-- Position it slightly above ground
					local raycastParams = RaycastParams.new()
					raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
					raycastParams.FilterDescendantsInstances = {coin}
					local raycast = workspace:Raycast(root.Position, Vector3.new(0, -10, 0), raycastParams)
					if raycast then
						root.CFrame = CFrame.new(raycast.Position + Vector3.new(0, 1.5, 0))
					end
					break
				end
			else
				stationaryFrames = 0
			end
			
			lastPosition = currentPos
		end
	end)

	-- Touch collect sensor (follows the coin, invisible)
	-- Use anchored sensor that updates position continuously for immediate detection
	local sensor = Instance.new("Part")
	sensor.Name = "CoinSensor"
	sensor.Size = Vector3.new(6, 6, 6) -- Larger sensor for better detection
	sensor.Transparency = 1
	sensor.CanCollide = false
	sensor.CanTouch = true -- Explicitly enable touch detection
	sensor.Anchored = true -- Anchored for reliable touch detection
	sensor.CFrame = root.CFrame -- Start at coin position
	sensor.Parent = coin
	
	-- Add to active coins list for batch updates (reduces data ping from individual connections)
	table.insert(activeEventCoins, {
		coin = coin,
		root = root,
		sensor = sensor,
		startTime = os.clock(),
	})
	
	-- Start batch update loop if not already running
	if not coinUpdateConnection then
		coinUpdateConnection = RunService.Heartbeat:Connect(function()
			for i = #activeEventCoins, 1, -1 do
				local coinData = activeEventCoins[i]
				if not coinData.coin or not coinData.coin.Parent or not coinData.root or not coinData.root.Parent then
					-- Coin was destroyed, remove from list
					table.remove(activeEventCoins, i)
				else
					-- Update sensor position to match coin position
					coinData.sensor.CFrame = coinData.root.CFrame
					
					-- Rotate coin (visual only)
					local t = os.clock() - coinData.startTime
					local rot = CFrame.Angles(0, (t * 2) % (math.pi * 2), 0)
					local currentCFrame = coinData.root.CFrame
					coinData.root.CFrame = CFrame.new(currentCFrame.Position) * rot
				end
			end
			
			-- Disconnect if no coins left
			if #activeEventCoins == 0 and coinUpdateConnection then
				coinUpdateConnection:Disconnect()
				coinUpdateConnection = nil
			end
		end)
	end

	-- Track if coin has been collected to prevent double collection
	local collected = false

	sensor.Touched:Connect(function(hit)
		if collected then return end
		
		local model = hit:FindFirstAncestorOfClass("Model")
		if not model then return end
		local player = Players:GetPlayerFromCharacter(model)
		if not player then return end
		
		-- Prevent double collection
		collected = true
		
		-- Check for multipliers (Gold and Diamond) - same logic as normal coins
		local goldMultiplier = model:GetAttribute("GoldMultiplier")
		local diamondMultiplier = model:GetAttribute("DiamondMultiplier")
		dlog(string.format("Coin collection - GoldMultiplier: %s, DiamondMultiplier: %s", tostring(goldMultiplier), tostring(diamondMultiplier)))
		
		local coinAmount = 1
		local activeMultiplier = 1
		local multiplierType = "none"
		
		-- Check Diamond multiplier first (higher priority)
		if typeof(diamondMultiplier) == "number" and diamondMultiplier > 1 then
			activeMultiplier = diamondMultiplier
			multiplierType = "diamond"
		-- Check Gold multiplier if no Diamond multiplier
		elseif typeof(goldMultiplier) == "number" and goldMultiplier > 1 then
			activeMultiplier = goldMultiplier
			multiplierType = "gold"
		end
		
		if activeMultiplier > 1 then
			coinAmount = math.floor(coinAmount * activeMultiplier)
			dlog(string.format("%s multiplier active: %dx coins for %s", multiplierType:upper(), activeMultiplier, player.Name))
		else
			dlog(string.format("No multiplier - using base coin amount: %d", coinAmount))
		end
		
		-- Use CoinService to add coins (same as normal coins)
		CoinService:AddCoins(player, coinAmount)
		local coinPosition = root.Position
		dlog(string.format("Collected %d coins by %s at (%.1f, %.1f, %.1f)", coinAmount, player.Name, coinPosition.X, coinPosition.Y, coinPosition.Z))
		
		-- Play pickup sound at coin position (same as normal coins)
		local sfxPart = Instance.new("Part")
		sfxPart.Name = "CoinSFX"
		sfxPart.Anchored = true
		sfxPart.CanCollide = false
		sfxPart.CanQuery = false
		sfxPart.CanTouch = false
		sfxPart.Transparency = 1
		sfxPart.Size = Vector3.new(1, 1, 1)
		sfxPart.CFrame = CFrame.new(coinPosition)
		sfxPart.Parent = workspace
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://6792279908"
		sound.Volume = 0.8
		sound.RollOffMaxDistance = 100
		sound.RollOffMode = Enum.RollOffMode.Inverse
		sound.Parent = sfxPart
		sound:Play()
		task.delay(3, function()
			if sfxPart then sfxPart:Destroy() end
		end)
		
		-- Remove from active coins list (batch update loop will handle cleanup)
		for i = #activeEventCoins, 1, -1 do
			if activeEventCoins[i].coin == coin then
				table.remove(activeEventCoins, i)
				break
			end
		end
		
		-- Destroy the coin
		coin:Destroy()
	end)
	
	-- Despawn coin after 2 minutes if not collected
	task.delay(120, function()
		if coin and coin.Parent then
			-- Remove from active coins list
			for i = #activeEventCoins, 1, -1 do
				if activeEventCoins[i].coin == coin then
					table.remove(activeEventCoins, i)
					break
				end
			end
			coin:Destroy()
		end
	end)
	
	return coin
end

-- Start a coin drop event
local function startCoinDropEvent()
	dlog("Starting coin drop event!")
	
	local mapCenter = getMapCenter()
	local spawnLocations = getSpawnLocations()
	
	-- Update event state
	currentEventState.isCountdown = false
	currentEventState.isEventActive = true
	currentEventState.timeRemaining = DROP_DURATION
	currentEventState.eventStartTime = os.clock()
	
	-- Notify all clients that event is starting
	for _, player in ipairs(Players:GetPlayers()) do
		Remotes.CoinDropEventStart:FireClient(player, DROP_DURATION)
	end
	
	-- Phase 1: Drop coins at center for first 10 seconds
	local centerDropStart = os.clock()
	local centerDropEnd = centerDropStart + 10
	
	-- Phase 2: Drop coins over spawn locations for remaining time
	local spawnDropStart = centerDropEnd
	local spawnDropEnd = spawnDropStart + (DROP_DURATION - 10)
	
	local eventEndTime = os.clock() + DROP_DURATION
	local lastSpawnTime = os.clock()
	
	-- Spawn loop (throttled to reduce data ping - only check spawn timing, not every frame)
	local spawnConnection
	local lastSpawnCheckTime = os.clock()
	local SPAWN_CHECK_INTERVAL = 0.1 -- Check every 0.1 seconds instead of every frame
	spawnConnection = RunService.Heartbeat:Connect(function()
		local currentTime = os.clock()
		
		if currentTime >= eventEndTime then
			-- Event ended
			spawnConnection:Disconnect()
			
			-- Update event state for countdown
			currentEventState.isCountdown = true
			currentEventState.isEventActive = false
			currentEventState.timeRemaining = COUNTDOWN_TIME
			currentEventState.eventStartTime = os.clock()
			
			for _, player in ipairs(Players:GetPlayers()) do
				Remotes.CoinDropEventEnd:FireClient(player)
				-- Immediately send next countdown
				Remotes.CoinDropCountdown:FireClient(player, COUNTDOWN_TIME)
			end
			dlog("Coin drop event ended, starting next countdown")
			return
		end
		
		-- Only check spawn timing at intervals (reduces data ping)
		if currentTime - lastSpawnCheckTime < SPAWN_CHECK_INTERVAL then
			return
		end
		lastSpawnCheckTime = currentTime
		
		-- Update remaining time for event
		currentEventState.timeRemaining = math.max(0, eventEndTime - currentTime)
		
		-- Check if it's time to spawn coins
		if currentTime - lastSpawnTime >= (1 / COINS_PER_SECOND) then
			lastSpawnTime = currentTime
			
			if currentTime < centerDropEnd then
				-- Phase 1: Drop at center
				local dropHeight = CENTER_DROP_HEIGHT - ((currentTime - centerDropStart) / 10) * (CENTER_DROP_HEIGHT - 5)
				local dropPos = mapCenter + Vector3.new(
					(math.random() - 0.5) * 20, -- Random X offset
					dropHeight,
					(math.random() - 0.5) * 20  -- Random Z offset
				)
				createCoinAtPosition(dropPos)
				dlog("Dropped coin at center:", dropPos)
			else
				-- Phase 2: Drop over spawn locations
				if #spawnLocations > 0 then
					local randomSpawn = spawnLocations[math.random(1, #spawnLocations)]
					local dropPos = randomSpawn + Vector3.new(
						(math.random() - 0.5) * 15, -- Random X offset
						SPAWN_DROP_HEIGHT,
						(math.random() - 0.5) * 15  -- Random Z offset
					)
					createCoinAtPosition(dropPos)
					dlog("Dropped coin over spawn:", dropPos)
				end
			end
		end
	end)
end

-- Main event loop
local function startEventLoop()
	dlog("Event loop started")
	
	-- For testing: Start first countdown after 10 seconds (remove this in production)
	-- This allows you to see the countdown immediately
	task.wait(10)
	
	-- Continuous loop: countdown -> drop -> countdown -> drop -> ...
	while true do
		-- Update event state for countdown
		currentEventState.isCountdown = true
		currentEventState.isEventActive = false
		currentEventState.timeRemaining = COUNTDOWN_TIME
		currentEventState.eventStartTime = os.clock()
		
		-- Send countdown to clients (30 seconds before event)
		dlog("Sending countdown to all players")
		for _, player in ipairs(Players:GetPlayers()) do
			Remotes.CoinDropCountdown:FireClient(player, COUNTDOWN_TIME)
			dlog("Sent countdown to player:", player.Name)
		end
		
		-- Update countdown timer for new players
		task.spawn(function()
			local startTime = os.clock()
			while currentEventState.isCountdown and (os.clock() - startTime) < COUNTDOWN_TIME do
				task.wait(1)
				currentEventState.timeRemaining = math.max(0, COUNTDOWN_TIME - (os.clock() - startTime))
			end
		end)
		
		-- Wait for countdown
		task.wait(COUNTDOWN_TIME)
		
		-- Start the event
		startCoinDropEvent()
		
		-- Wait for event to finish
		task.wait(DROP_DURATION)
		
		-- Immediately start next countdown (no wait between events)
	end
end

-- Handle new players joining - send them current event state
Players.PlayerAdded:Connect(function(player)
	-- Wait a moment for client to be ready
	task.wait(1)
	
	-- Send current state to new player
	if currentEventState.isCountdown then
		local timeRemaining = math.ceil(currentEventState.timeRemaining)
		if timeRemaining > 0 then
			dlog("Sending countdown to new player:", player.Name, "Time remaining:", timeRemaining)
			Remotes.CoinDropCountdown:FireClient(player, timeRemaining)
		end
	elseif currentEventState.isEventActive then
		local timeRemaining = math.ceil(currentEventState.timeRemaining)
		if timeRemaining > 0 then
			dlog("Sending active event to new player:", player.Name, "Time remaining:", timeRemaining)
			Remotes.CoinDropEventStart:FireClient(player, timeRemaining)
		end
	end
end)

-- Start the service
task.spawn(startEventLoop)
dlog("CoinDropEventService initialized")

return {}
