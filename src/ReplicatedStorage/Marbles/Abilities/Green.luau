-- Green marble ability: dirt ramp creation
local Ability = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Constants
local RAMP_DURATION = 10 -- seconds the ramp should exist
local RAMP_SIZE = Vector3.new(8, 1, 12) -- Width, Height, Length
local RAMP_ANGLE = math.rad(15) -- 15 degree incline

function Ability.Description()
	return "Green: Creates a dirt ramp that disappears after 10 seconds."
end

function Ability.Cooldown()
	return 5 -- 5 second cooldown (half of debris removal time)
end

-- Helper: get (or create) the folder that holds references to multiple ramps
local function getOrCreateRampFolder(character: Model)
	local folder = character:FindFirstChild("GreenRampFolder")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "GreenRampFolder"
		folder.Archivable = false
		folder.Parent = character
	end
	return folder
end

-- Helper: get the player's last movement direction
local function getLastMovementDirection(character: Model)
	-- Check if we have a stored last direction
	local lastDirection = character:GetAttribute("LastMovementDirection")
	if lastDirection then
		return Vector3.new(lastDirection.X, 0, lastDirection.Z).Unit
	end
	
	-- Fallback to character's current facing direction
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		local fallbackDirection = Vector3.new(humanoidRootPart.CFrame.LookVector.X, 0, humanoidRootPart.CFrame.LookVector.Z)
		if fallbackDirection.Magnitude > 0.1 then
			return fallbackDirection.Unit
		end
	end
	
	-- Default to forward if nothing else works
	return Vector3.new(0, 0, -1)
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("GREEN ABILITY LOG: Activating Green marble ability for player:", player and player.Name or "nil")
	print("GREEN ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")
	print("GREEN ABILITY LOG: Cooldown duration:", Ability.Cooldown(), "seconds")

	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("GREEN ABILITY LOG: No character or HumanoidRootPart found, aborting")
		return
	end

	-- Allow multiple ramps (cooldown is shorter than ramp duration)
	-- No need to check if ramp is already active

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Get the player's last movement direction (much simpler than camera calculations)
	local movementDirection = getLastMovementDirection(character)
	
	-- Calculate ramp position in front of the character on the ground
	local rampPosition = humanoidRootPart.Position + (movementDirection * (RAMP_SIZE.Z / 2 + 2))
	-- Keep the ramp at ground level (slightly above the character's Y position)
	rampPosition = Vector3.new(rampPosition.X, humanoidRootPart.Position.Y + 0.5, rampPosition.Z)

	print("GREEN ABILITY LOG: Creating dirt ramp at position:", rampPosition)

	-- Create the dirt ramp with error handling
	local ramp
	local success, error = pcall(function()
		ramp = Instance.new("Part")
		ramp.Name = ("GreenDirtRamp_%s"):format(player and player.UserId or "unknown")
		ramp.Material = Enum.Material.Ground
		ramp.Color = Color3.fromRGB(139, 69, 19) -- Brown dirt
		ramp.Size = RAMP_SIZE
		ramp.Anchored = true
		ramp.CanCollide = true
		
		-- Orient the ramp to face the movement direction
		ramp.CFrame = CFrame.lookAt(rampPosition, rampPosition + movementDirection) * CFrame.Angles(RAMP_ANGLE, 0, 0)
		ramp.Parent = workspace
		
		return ramp
	end)
	
	if not success or not ramp then
		print("GREEN ABILITY LOG: Failed to create ramp:", error)
		return
	end
	
	print("GREEN ABILITY LOG: Ramp created successfully")

	-- Visuals: texture
	local success, error = pcall(function()
		local dirtTexture = Instance.new("Texture")
		dirtTexture.Texture = "rbxasset://textures/terrain/grass.jpg"
		dirtTexture.StudsPerTileU = 2
		dirtTexture.StudsPerTileV = 2
		dirtTexture.Parent = ramp
	end)
	if not success then
		print("GREEN ABILITY LOG: Failed to create texture:", error)
	end

	-- Visuals: subtle dirt particles
	local success2, error2 = pcall(function()
		local dirtEmitter = Instance.new("ParticleEmitter")
		dirtEmitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		dirtEmitter.Color = ColorSequence.new(Color3.fromRGB(139, 69, 19))
		dirtEmitter.Size = NumberSequence.new(0.1, 0.3)
		dirtEmitter.Transparency = NumberSequence.new(0.5, 1)
		dirtEmitter.Rate = 5
		dirtEmitter.Lifetime = NumberRange.new(1, 2)
		dirtEmitter.Speed = NumberRange.new(0.5, 1)
		dirtEmitter.SpreadAngle = Vector2.new(10, 10)
		dirtEmitter.Parent = ramp
	end)
	if not success2 then
		print("GREEN ABILITY LOG: Failed to create particles:", error2)
	end

	print("GREEN ABILITY LOG: Dirt ramp created at position:", rampPosition)

	-- Store a reference to the ramp safely in the folder
	local folder = getOrCreateRampFolder(character)
	local ref = Instance.new("ObjectValue")
	ref.Name = ("Ramp_%s"):format(tick()) -- Unique name for each ramp
	ref.Value = ramp
	ref.Parent = folder

	-- Schedule automatic cleanup with Debris (destroys the ramp after RAMP_DURATION)
	Debris:AddItem(ramp, RAMP_DURATION)

	-- Clean up the reference after RAMP_DURATION
	task.delay(RAMP_DURATION, function()
		if ref and ref.Parent then
			ref:Destroy()
		end
	end)

	print("GREEN ABILITY LOG: Green ability activation complete - Ramp duration:", RAMP_DURATION, "seconds, Cooldown:", Ability.Cooldown(), "seconds")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("GREEN ABILITY LOG: Deactivating Green marble ability for player:", player and player.Name or "nil")
	print("GREEN ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")

	if not character then
		print("GREEN ABILITY LOG: Character no longer exists, cannot deactivate ability")
		return
	end

	-- Remove all ramps immediately if they exist
	local folder = character:FindFirstChild("GreenRampFolder")
	if folder then
		for _, ref in pairs(folder:GetChildren()) do
			if ref:IsA("ObjectValue") and ref.Value then
				if ref.Value.Parent then
					print("GREEN ABILITY LOG: Removing dirt ramp immediately")
					ref.Value:Destroy()
				end
			end
		end
		folder:Destroy()
	end
end

return Ability
