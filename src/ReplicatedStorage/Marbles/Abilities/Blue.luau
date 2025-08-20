-- Blue marble ability: geyser creation
local Ability = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- Constants
local GEYSER_DURATION = 8 -- seconds the geyser should exist
local GEYSER_SIZE = Vector3.new(6, 12, 6) -- Width, Height, Depth
local GEYSER_FORCE = 50 -- force applied to push marbles up
local GEYSER_RADIUS = 8 -- radius to check for marbles to push
local PUSH_INTERVAL = 0.1 -- how often to apply force (seconds)

function Ability.Description()
	return "Blue: Creates a geyser that pushes marbles upward and disappears after 8 seconds."
end

function Ability.Cooldown()
	return 6 -- 6 second cooldown (shorter than geyser duration)
end

-- Helper: get (or create) the folder that holds references to geysers
local function getOrCreateGeyserFolder(character: Model)
	local folder = character:FindFirstChild("BlueGeyserFolder")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "BlueGeyserFolder"
		folder.Archivable = false
		folder.Parent = character
	end
	return folder
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

-- Helper: apply upward force to marbles
local function pushMarblesUp(geyserPart: BasePart, force: number)
	local marbles = findMarblesInRadius(geyserPart.Position, GEYSER_RADIUS)
	
	for _, marble in pairs(marbles) do
		if marble and marble.Parent and marble:IsA("BasePart") then
			-- Apply upward force
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(0, force * 1000, 0) -- Strong upward force
			bodyVelocity.Velocity = Vector3.new(0, force, 0)
			bodyVelocity.Parent = marble
			
			-- Remove the BodyVelocity after a short time
			Debris:AddItem(bodyVelocity, 0.5)
		end
	end
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("BLUE ABILITY LOG: Activating Blue marble ability for player:", player and player.Name or "nil")
	print("BLUE ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")
	print("BLUE ABILITY LOG: Cooldown duration:", Ability.Cooldown(), "seconds")

	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("BLUE ABILITY LOG: No character or HumanoidRootPart found, aborting")
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Create geyser at character's position, starting from ground level
	local geyserPosition = humanoidRootPart.Position
	print("BLUE ABILITY LOG: Creating geyser at position:", geyserPosition)

	-- Create the geyser with error handling
	local geyser
	local success, error = pcall(function()
		geyser = Instance.new("Part")
		geyser.Name = ("BlueGeyser_%s"):format(player and player.UserId or "unknown")
		geyser.Material = Enum.Material.Water
		geyser.Color = Color3.fromRGB(0, 150, 255) -- Blue water color
		geyser.Size = GEYSER_SIZE
		geyser.Anchored = true
		geyser.CanCollide = false -- Don't block movement
		geyser.Transparency = 0.3 -- Semi-transparent
		-- Position the geyser so it starts at ground level (Y = 0) and extends upward
		geyser.CFrame = CFrame.new(geyserPosition.X, GEYSER_SIZE.Y / 2, geyserPosition.Z)
		geyser.Parent = workspace
		
		return geyser
	end)
	
	if not success or not geyser then
		print("BLUE ABILITY LOG: Failed to create geyser:", error)
		return
	end
	
	print("BLUE ABILITY LOG: Geyser created successfully")

	-- Visuals: water texture
	local success, error = pcall(function()
		local waterTexture = Instance.new("Texture")
		waterTexture.Texture = "rbxasset://textures/terrain/water.jpg"
		waterTexture.StudsPerTileU = 4
		waterTexture.StudsPerTileV = 4
		waterTexture.Parent = geyser
	end)
	if not success then
		print("BLUE ABILITY LOG: Failed to create water texture:", error)
	end

	-- Visuals: water particles
	local success2, error2 = pcall(function()
		local waterEmitter = Instance.new("ParticleEmitter")
		waterEmitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		waterEmitter.Color = ColorSequence.new(Color3.fromRGB(0, 150, 255))
		waterEmitter.Size = NumberSequence.new(0.2, 0.6)
		waterEmitter.Transparency = NumberSequence.new(0.3, 1)
		waterEmitter.Rate = 20
		waterEmitter.Lifetime = NumberRange.new(1, 2)
		waterEmitter.Speed = NumberRange.new(2, 5)
		waterEmitter.SpreadAngle = Vector2.new(15, 15)
		waterEmitter.Parent = geyser
	end)
	if not success2 then
		print("BLUE ABILITY LOG: Failed to create water particles:", error2)
	end

	-- Visuals: bubble effect
	local success3, error3 = pcall(function()
		local bubbleEmitter = Instance.new("ParticleEmitter")
		bubbleEmitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		bubbleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		bubbleEmitter.Size = NumberSequence.new(0.1, 0.3)
		bubbleEmitter.Transparency = NumberSequence.new(0.2, 0.8)
		bubbleEmitter.Rate = 15
		bubbleEmitter.Lifetime = NumberRange.new(0.5, 1.5)
		bubbleEmitter.Speed = NumberRange.new(1, 3)
		bubbleEmitter.SpreadAngle = Vector2.new(10, 10)
		bubbleEmitter.Parent = geyser
	end)
	if not success3 then
		print("BLUE ABILITY LOG: Failed to create bubble particles:", error3)
	end

	-- Create a point light for the geyser
	local success4, error4 = pcall(function()
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(0, 150, 255)
		light.Range = 15
		light.Brightness = 2
		light.Parent = geyser
	end)
	if not success4 then
		print("BLUE ABILITY LOG: Failed to create light:", error4)
	end

	print("BLUE ABILITY LOG: Geyser created at position:", geyserPosition)

	-- Store a reference to the geyser safely in the folder
	local folder = getOrCreateGeyserFolder(character)
	local ref = Instance.new("ObjectValue")
	ref.Name = ("Geyser_%s"):format(tick()) -- Unique name for each geyser
	ref.Value = geyser
	ref.Parent = folder

	-- Start the pushing mechanism
	local pushConnection
	local function startPushing()
		pushConnection = RunService.Heartbeat:Connect(function()
			if geyser and geyser.Parent then
				pushMarblesUp(geyser, GEYSER_FORCE)
			else
				-- Stop pushing if geyser is destroyed
				if pushConnection then
					pushConnection:Disconnect()
					pushConnection = nil
				end
			end
		end)
	end
	
	startPushing()

	-- Schedule automatic cleanup with Debris (destroys the geyser after GEYSER_DURATION)
	Debris:AddItem(geyser, GEYSER_DURATION)

	-- Clean up the reference and stop pushing after GEYSER_DURATION
	task.delay(GEYSER_DURATION, function()
		if pushConnection then
			pushConnection:Disconnect()
			pushConnection = nil
		end
		if ref and ref.Parent then
			ref:Destroy()
		end
	end)

	print("BLUE ABILITY LOG: Blue ability activation complete - Geyser duration:", GEYSER_DURATION, "seconds, Cooldown:", Ability.Cooldown(), "seconds")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("BLUE ABILITY LOG: Deactivating Blue marble ability for player:", player and player.Name or "nil")
	print("BLUE ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")

	if not character then
		print("BLUE ABILITY LOG: Character no longer exists, cannot deactivate ability")
		return
	end

	-- Remove all geysers immediately if they exist
	local folder = character:FindFirstChild("BlueGeyserFolder")
	if folder then
		for _, ref in pairs(folder:GetChildren()) do
			if ref:IsA("ObjectValue") and ref.Value then
				if ref.Value.Parent then
					print("BLUE ABILITY LOG: Removing geyser immediately")
					ref.Value:Destroy()
				end
			end
		end
		folder:Destroy()
	end
end

return Ability 