-- Pharaoh marble ability: yellow pyramid creation
local Ability = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Constants
local PYRAMID_DURATION = 15 -- seconds the pyramid should exist
local PYRAMID_BASE_SIZE = 24 -- base width and length of the pyramid (doubled)
local PYRAMID_HEIGHT = 16 -- height of the pyramid (doubled)
local PYRAMID_LAYERS = 4 -- number of layers in the pyramid

function Ability.Description()
	return "Pharaoh: Creates a yellow pyramid that players can scale."
end

function Ability.Cooldown()
	return 15 -- 15 second cooldown
end

-- Helper: get (or create) the folder that holds references to pyramids
local function getOrCreatePyramidFolder(character: Model)
	local folder = character:FindFirstChild("PharaohPyramidFolder")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "PharaohPyramidFolder"
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

-- Helper: create a single layer of the pyramid
local function createPyramidLayer(position: Vector3, size: number, height: number, layerIndex: number)
	local layer = Instance.new("Part")
	layer.Name = ("PharaohPyramidLayer_%d"):format(layerIndex)
	layer.Material = Enum.Material.Sand
	layer.Color = Color3.fromRGB(255, 215, 0) -- Gold/yellow color
	layer.Size = Vector3.new(size, height, size)
	layer.Anchored = true
	layer.CanCollide = true
	layer.Position = position
	
	-- Add pyramid texture
	local texture = Instance.new("Texture")
	texture.Texture = "rbxasset://textures/terrain/sand.jpg"
	texture.StudsPerTileU = 1
	texture.StudsPerTileV = 1
	texture.Parent = layer
	
	return layer
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("PHARAOH ABILITY LOG: Activating Pharaoh marble ability for player:", player and player.Name or "nil")
	print("PHARAOH ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")
	print("PHARAOH ABILITY LOG: Cooldown duration:", Ability.Cooldown(), "seconds")

	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("PHARAOH ABILITY LOG: No character or HumanoidRootPart found, aborting")
		return
	end

	-- Activate the red/gold trail effect
	character:SetAttribute("PharaohGlowActive", true)

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Get the player's last movement direction
	local movementDirection = getLastMovementDirection(character)
	
	-- Calculate pyramid position in front of the character
	local pyramidPosition = humanoidRootPart.Position + (movementDirection * (PYRAMID_BASE_SIZE / 2 + 3))
	-- Keep the pyramid at ground level
	pyramidPosition = Vector3.new(pyramidPosition.X, humanoidRootPart.Position.Y, pyramidPosition.Z)

	print("PHARAOH ABILITY LOG: Creating pyramid at position:", pyramidPosition)

	-- Create the pyramid with error handling
	local pyramid
	local success, error = pcall(function()
		pyramid = Instance.new("Model")
		pyramid.Name = ("PharaohPyramid_%s"):format(player and player.UserId or "unknown")
		pyramid.Parent = workspace
		
		-- Create pyramid layers from bottom to top
		local layerHeight = PYRAMID_HEIGHT / PYRAMID_LAYERS
		for i = 1, PYRAMID_LAYERS do
			local layerSize = PYRAMID_BASE_SIZE * (1 - (i - 1) / PYRAMID_LAYERS)
			local layerY = pyramidPosition.Y + (i - 1) * layerHeight + layerHeight / 2
			local layerPosition = Vector3.new(pyramidPosition.X, layerY, pyramidPosition.Z)
			
			local layer = createPyramidLayer(layerPosition, layerSize, layerHeight, i)
			layer.Parent = pyramid
		end
		
		return pyramid
	end)
	
	if not success or not pyramid then
		print("PHARAOH ABILITY LOG: Failed to create pyramid:", error)
		return
	end
	
	print("PHARAOH ABILITY LOG: Pyramid created successfully")

	-- Add visual effects
	local success2, error2 = pcall(function()
		-- Add golden particles at the top
		local topLayer = pyramid:FindFirstChild("PharaohPyramidLayer_1")
		if topLayer then
			local particleEmitter = Instance.new("ParticleEmitter")
			particleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			particleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
			particleEmitter.Size = NumberSequence.new(0.2, 0.5)
			particleEmitter.Transparency = NumberSequence.new(0.3, 1)
			particleEmitter.Rate = 10
			particleEmitter.Lifetime = NumberRange.new(2, 4)
			particleEmitter.Speed = NumberRange.new(1, 3)
			particleEmitter.SpreadAngle = Vector2.new(45, 45)
			particleEmitter.Parent = topLayer
		end
	end)
	if not success2 then
		print("PHARAOH ABILITY LOG: Failed to create particles:", error2)
	end

	print("PHARAOH ABILITY LOG: Pyramid created at position:", pyramidPosition)

	-- Store a reference to the pyramid safely in the folder
	local folder = getOrCreatePyramidFolder(character)
	local ref = Instance.new("ObjectValue")
	ref.Name = ("Pyramid_%s"):format(tick()) -- Unique name for each pyramid
	ref.Value = pyramid
	ref.Parent = folder

	-- Schedule automatic cleanup with Debris (destroys the pyramid after PYRAMID_DURATION)
	Debris:AddItem(pyramid, PYRAMID_DURATION)

	-- Clean up the reference after PYRAMID_DURATION
	task.delay(PYRAMID_DURATION, function()
		if ref and ref.Parent then
			ref:Destroy()
		end
	end)

	print("PHARAOH ABILITY LOG: Pharaoh ability activation complete - Pyramid duration:", PYRAMID_DURATION, "seconds, Cooldown:", Ability.Cooldown(), "seconds")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("PHARAOH ABILITY LOG: Deactivating Pharaoh marble ability for player:", player and player.Name or "nil")
	print("PHARAOH ABILITY LOG: Character exists:", character ~= nil, "Character Name:", character and character.Name or "nil")

	if not character then
		print("PHARAOH ABILITY LOG: Character no longer exists, cannot deactivate ability")
		return
	end

	-- Deactivate the red/gold trail effect
	character:SetAttribute("PharaohGlowActive", false)

	-- Remove all pyramids immediately if they exist
	local folder = character:FindFirstChild("PharaohPyramidFolder")
	if folder then
		for _, ref in pairs(folder:GetChildren()) do
			if ref:IsA("ObjectValue") and ref.Value then
				if ref.Value.Parent then
					print("PHARAOH ABILITY LOG: Removing pyramid immediately")
					ref.Value:Destroy()
				end
			end
		end
		folder:Destroy()
	end
end

return Ability
