-- Glass marble ability: leaves behind connected glass trail tiles while moving
local Ability = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- Constants
local GLASS_DURATION = 6 -- seconds each glass tile should exist
local GLASS_SIZE = Vector3.new(3, 0.3, 3) -- Width, Height, Length of each glass tile
local GLASS_SLIP_FACTOR = 0.3 -- How much marbles slip on glass (0.3 = 30% of normal friction)
local GLASS_RADIUS = 5 -- radius to check for marbles to affect
local GLASS_TRAIL_INTERVAL = 0.2 -- how often to drop glass tiles while moving (seconds)
local GLASS_MIN_SPEED = 1 -- minimum speed to start leaving glass trail (lowered for easier activation)
local GLASS_TRAIL_DISTANCE = 1 -- minimum distance between glass tiles (lowered for more frequent drops)
local MAX_GLASS_TILES = 20 -- maximum number of glass tiles in trail

function Ability.Description()
	return "Glass: Leaves behind a connected glass trail while moving that makes marbles slip and slide."
end

function Ability.Cooldown()
	return 0 -- No cooldown - passive trail ability
end

-- Helper: get (or create) the folder that holds references to glass tiles
local function getOrCreateGlassFolder(character: Model)
	local folder = character:FindFirstChild("GlassFolder")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "GlassFolder"
		folder.Archivable = false
		folder.Parent = character
	end
	return folder
end

-- Helper: remove the oldest glass tile when we reach the limit
local function removeOldestGlassTile(character: Model)
	local folder = character:FindFirstChild("GlassFolder")
	if not folder then return end
	
	local glassTiles = {}
	for _, ref in pairs(folder:GetChildren()) do
		if ref:IsA("ObjectValue") and ref.Value and ref.Value.Parent then
			table.insert(glassTiles, ref)
		end
	end
	
	-- Sort by creation time (name contains timestamp)
	table.sort(glassTiles, function(a, b)
		return a.Name < b.Name
	end)
	
	-- Remove the oldest tile
	if #glassTiles > 0 then
		local oldestTile = glassTiles[1]
		if oldestTile.Value and oldestTile.Value.Parent then
			oldestTile.Value:Destroy()
		end
		oldestTile:Destroy()
	end
end

-- Helper: find marbles within radius of a position
local function findMarblesInRadius(position: Vector3, radius: number): {BasePart}
	local marbles = {}
	
	-- Check all players' characters
	for _, player in pairs(Players:GetPlayers()) do
		local character = player.Character
		if character and character:GetAttribute("IsMarbleCharacter") then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				local distance = (hrp.Position - position).Magnitude
				if distance <= radius then
					table.insert(marbles, hrp)
				end
			end
		end
	end
	
	return marbles
end

-- Helper: apply glass physics to marbles on the glass surface
local function applyGlassPhysics(glassPart: BasePart, slipFactor: number)
	local marbles = findMarblesInRadius(glassPart.Position, GLASS_RADIUS)
	
	for _, marble in pairs(marbles) do
		if marble and marble.Parent and marble:IsA("BasePart") then
			-- Check if marble is actually on the glass surface (Y level check)
			local marbleY = marble.Position.Y
			local glassY = glassPart.Position.Y
			local glassHeight = glassPart.Size.Y / 2
			
			-- If marble is within the glass surface height range
			if marbleY >= glassY - glassHeight and marbleY <= glassY + glassHeight then
				-- Apply reduced friction by modifying the marble's physics
				local bodyVelocity = marble:FindFirstChild("GlassBodyVelocity")
				if not bodyVelocity then
					bodyVelocity = Instance.new("BodyVelocity")
					bodyVelocity.Name = "GlassBodyVelocity"
					bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000) -- Only affect horizontal movement
					bodyVelocity.Parent = marble
				end
				
				-- Get current velocity and apply slip effect
				local currentVelocity = marble.Velocity
				local horizontalVelocity = Vector3.new(currentVelocity.X, 0, currentVelocity.Z)
				local slippedVelocity = horizontalVelocity * (1 + slipFactor) -- Increase velocity for sliding effect
				
				bodyVelocity.Velocity = Vector3.new(slippedVelocity.X, 0, slippedVelocity.Z)
			end
		end
	end
end

-- Helper: create a single glass tile
local function createGlassTile(character: Model, position: Vector3, player: Player)
	-- Place glass on ground level
	local glassPosition = Vector3.new(position.X, position.Y - 1, position.Z)
	
	-- Create the glass tile with error handling
	local glassTile
	local success, error = pcall(function()
		glassTile = Instance.new("Part")
		glassTile.Name = ("GlassTile_%s_%s"):format(player and player.UserId or "unknown", tick())
		glassTile.Material = Enum.Material.Glass
		glassTile.Color = Color3.fromRGB(220, 240, 255) -- Light blue glass color
		glassTile.Size = GLASS_SIZE
		glassTile.Anchored = true
		glassTile.CanCollide = true
		glassTile.Transparency = 0.3 -- Semi-transparent glass
		glassTile.Reflectance = 0.5 -- Glass reflection
		glassTile.CFrame = CFrame.new(glassPosition)
		glassTile.Parent = workspace
		
		return glassTile
	end)
	
	if not success or not glassTile then
		return nil
	end
	
	-- Visuals: glass texture
	pcall(function()
		local glassTexture = Instance.new("Texture")
		glassTexture.Texture = "rbxasset://textures/terrain/glass.jpg"
		glassTexture.StudsPerTileU = 1
		glassTexture.StudsPerTileV = 1
		glassTexture.Parent = glassTile
	end)

	-- Visuals: glass particles
	pcall(function()
		local glassEmitter = Instance.new("ParticleEmitter")
		glassEmitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		glassEmitter.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
		glassEmitter.Size = NumberSequence.new(0.05, 0.2)
		glassEmitter.Transparency = NumberSequence.new(0.5, 1)
		glassEmitter.Rate = 5
		glassEmitter.Lifetime = NumberRange.new(0.5, 1.5)
		glassEmitter.Speed = NumberRange.new(0.3, 1)
		glassEmitter.SpreadAngle = Vector2.new(10, 10)
		glassEmitter.Parent = glassTile
	end)

	-- Visuals: sparkle effect for glass
	pcall(function()
		local sparkleEmitter = Instance.new("ParticleEmitter")
		sparkleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		sparkleEmitter.Size = NumberSequence.new(0.03, 0.1)
		sparkleEmitter.Transparency = NumberSequence.new(0.2, 0.9)
		sparkleEmitter.Rate = 2
		sparkleEmitter.Lifetime = NumberRange.new(0.3, 0.8)
		sparkleEmitter.Speed = NumberRange.new(0.1, 0.5)
		sparkleEmitter.SpreadAngle = Vector2.new(5, 5)
		sparkleEmitter.Parent = glassTile
	end)

	-- Create a subtle point light for the glass tile
	pcall(function()
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(220, 240, 255)
		light.Range = 6
		light.Brightness = 0.8
		light.Parent = glassTile
	end)

	-- Store a reference to the glass tile safely in the folder
	local folder = getOrCreateGlassFolder(character)
	local ref = Instance.new("ObjectValue")
	ref.Name = ("GlassTile_%s"):format(tick()) -- Unique name for each glass tile
	ref.Value = glassTile
	ref.Parent = folder

	-- Start the glass physics mechanism for this tile
	local glassConnection
	glassConnection = RunService.Heartbeat:Connect(function()
		if glassTile and glassTile.Parent then
			applyGlassPhysics(glassTile, GLASS_SLIP_FACTOR)
		else
			-- Stop applying physics if glass tile is destroyed
			if glassConnection then
				glassConnection:Disconnect()
				glassConnection = nil
			end
		end
	end)

	-- Schedule automatic cleanup with Debris (destroys the glass tile after GLASS_DURATION)
	Debris:AddItem(glassTile, GLASS_DURATION)

	-- Clean up the reference after GLASS_DURATION
	task.delay(GLASS_DURATION, function()
		if ref and ref.Parent then
			ref:Destroy()
		end
	end)
	
	return glassTile
end

function Ability.ActivateAbility(player: Player, character: Model)
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	-- Check if glass trail is already active
	if character:GetAttribute("GlassTrailActive") then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Set glass trail as active
	character:SetAttribute("GlassTrailActive", true)
	character:SetAttribute("GlassGlowActive", true)
	
	-- Store last glass drop position
	local lastGlassPosition = humanoidRootPart.Position
	character:SetAttribute("LastGlassPosition", lastGlassPosition)
	
	-- Create glass trail connection
	local glassTrailConnection
	local lastDropTime = tick() -- Initialize with current time
	
	glassTrailConnection = RunService.Heartbeat:Connect(function()
		-- Safety check: ensure character still exists and glass trail is still active
		if not character or not character.Parent or not character:FindFirstChild("HumanoidRootPart") then
			if glassTrailConnection then
				glassTrailConnection:Disconnect()
				glassTrailConnection = nil
			end
			return
		end
		
		-- Check if glass trail is still supposed to be active
		if not character:GetAttribute("GlassTrailActive") then
			if glassTrailConnection then
				glassTrailConnection:Disconnect()
				glassTrailConnection = nil
			end
			return
		end
		
		-- Check if the glass marble is still equipped
		if character:GetAttribute("EquippedMarbleId") ~= "Glass" then
			if glassTrailConnection then
				glassTrailConnection:Disconnect()
				glassTrailConnection = nil
			end
			return
		end
		
		local currentTime = tick()
		local currentPosition = humanoidRootPart.Position
		local lastPosition = character:GetAttribute("LastGlassPosition")
		
		if lastPosition then
			-- Calculate speed and distance
			local distance = (currentPosition - lastPosition).Magnitude
			local timeSinceLastDrop = currentTime - lastDropTime
			local speed = timeSinceLastDrop > 0 and (distance / timeSinceLastDrop) or 0
			
			-- Check if we should drop glass (moving fast enough and enough time/distance passed)
			if distance >= GLASS_TRAIL_DISTANCE and timeSinceLastDrop >= GLASS_TRAIL_INTERVAL then
				if speed >= GLASS_MIN_SPEED then
					-- Check current tile count
					local folder = character:FindFirstChild("GlassFolder")
					local currentTileCount = folder and #folder:GetChildren() or 0
					
					-- If we're at the limit, remove the oldest tile first
					if currentTileCount >= MAX_GLASS_TILES then
						removeOldestGlassTile(character)
					end
					
					-- Drop glass tile at current position
					createGlassTile(character, currentPosition, player)
					character:SetAttribute("LastGlassPosition", currentPosition)
					lastDropTime = currentTime
				end
			end
		else
			-- Initialize last position and drop time
			character:SetAttribute("LastGlassPosition", currentPosition)
			lastDropTime = currentTime
		end
	end)
	
	-- Store the connection reference
	character:SetAttribute("GlassTrailConnection", glassTrailConnection)
end

function Ability.DeactivateAbility(player: Player, character: Model)
	if not character then
		return
	end

	-- Stop the glass trail
	character:SetAttribute("GlassTrailActive", false)
	character:SetAttribute("GlassGlowActive", false)
	
	-- Disconnect the trail connection
	local connection = character:GetAttribute("GlassTrailConnection")
	if connection then
		pcall(function()
			connection:Disconnect()
		end)
		character:SetAttribute("GlassTrailConnection", nil)
	end
	
	-- Clear last position
	character:SetAttribute("LastGlassPosition", nil)

	-- Remove all glass tiles immediately if they exist
	local folder = character:FindFirstChild("GlassFolder")
	if folder then
		for _, ref in pairs(folder:GetChildren()) do
			if ref:IsA("ObjectValue") and ref.Value then
				if ref.Value.Parent then
					ref.Value:Destroy()
				end
			end
		end
		folder:Destroy()
	end
end

return Ability
