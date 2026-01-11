-- Gold marble ability: Creates a walkable gold staircase with coins
local Ability = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- Constants
local STAIRCASE_DURATION = 10 -- seconds the staircase should exist
local STAIRCASE_STEPS = 8 -- number of steps in the staircase
local STEP_DISTANCE = 4 -- distance between each step
local STEP_HEIGHT = 2 -- height increase per step
local STEP_WIDTH = 6 -- width of each step
local STEP_DEPTH = 3 -- depth of each step
local COIN_SIZE = Vector3.new(0.5, 3, 3) -- size of each coin

function Ability.Description()
	return "Gold: Creates a walkable gold staircase with coins that disappears after 10 seconds."
end

function Ability.Cooldown()
	return 20 -- 20 second cooldown
end

-- Helper: get the player's movement direction
local function getMovementDirection(character: Model)
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

-- Helper: create a single coin
local function createCoin(position: Vector3, player: Player)
	local coin = Instance.new("Model")
	coin.Name = "GoldStaircaseCoin"
	coin.Parent = workspace

	local root = Instance.new("Part")
	root.Name = "CoinRoot"
	root.Shape = Enum.PartType.Cylinder
	root.Size = COIN_SIZE
	root.Color = Color3.fromRGB(255, 215, 0) -- Gold color
	root.Material = Enum.Material.Metal
	root.Anchored = true
	root.CanCollide = false
	root.Parent = coin

	coin:PivotTo(CFrame.new(position))

	-- Touch collect sensor (anchored, invisible)
	local sensor = Instance.new("Part")
	sensor.Name = "CoinSensor"
	sensor.Size = Vector3.new(4, 4, 4)
	sensor.Transparency = 1
	sensor.CanCollide = false
	sensor.Anchored = true
	sensor.CFrame = CFrame.new(position)
	sensor.Parent = coin

	-- Collection logic
	sensor.Touched:Connect(function(hit)
		local model = hit:FindFirstAncestorOfClass("Model")
		if not model then return end
		local collectingPlayer = Players:GetPlayerFromCharacter(model)
		if not collectingPlayer then return end
		
		-- Get CoinService to add coins
		local CoinService = require(game:GetService("ServerScriptService"):WaitForChild("CoinService"))
		if CoinService then
			-- Check for multipliers
			local goldMultiplier = model:GetAttribute("GoldMultiplier")
			local diamondMultiplier = model:GetAttribute("DiamondMultiplier")
			
			local coinAmount = 1
			local activeMultiplier = 1
			
			-- Check Diamond multiplier first (higher priority)
			if typeof(diamondMultiplier) == "number" and diamondMultiplier > 1 then
				activeMultiplier = diamondMultiplier
			-- Check Gold multiplier if no Diamond multiplier
			elseif typeof(goldMultiplier) == "number" and goldMultiplier > 1 then
				activeMultiplier = goldMultiplier
			end
			
			if activeMultiplier > 1 then
				coinAmount = math.floor(coinAmount * activeMultiplier)
			end
			
			CoinService:AddCoins(collectingPlayer, coinAmount)
			
			-- Play pickup sound
			local sfxPart = Instance.new("Part")
			sfxPart.Name = "CoinSFX"
			sfxPart.Anchored = true
			sfxPart.CanCollide = false
			sfxPart.CanQuery = false
			sfxPart.CanTouch = false
			sfxPart.Transparency = 1
			sfxPart.Size = Vector3.new(1, 1, 1)
			sfxPart.CFrame = CFrame.new(position)
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
		end
		
		coin:Destroy()
	end)

	-- Animate coin (hover + rotate)
	local phase = math.random() * math.pi * 2
	local basePos = position
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not coin or not coin.Parent then
			connection:Disconnect()
			return
		end
		local t = os.clock()
		local y = math.sin((t + phase) * 2) * 0.5
		local rot = CFrame.Angles(0, (t * 2) % (math.pi * 2), 0)
		coin:PivotTo(CFrame.new(basePos + Vector3.new(0, y, 0)) * rot)
	end)

	-- Clean up connection when coin is destroyed
	coin.AncestryChanged:Connect(function()
		if not coin.Parent then
			if connection then
				connection:Disconnect()
			end
		end
	end)

	-- Schedule automatic cleanup with Debris (safety net)
	Debris:AddItem(coin, STAIRCASE_DURATION)

	return coin
end

-- Helper: create a single step with particles
local function createStep(position: Vector3, stepIndex: number, movementDirection: Vector3)
	local step = Instance.new("Part")
	step.Name = ("GoldStaircaseStep_%d"):format(stepIndex)
	step.Size = Vector3.new(STEP_WIDTH, 0.5, STEP_DEPTH)
	step.Color = Color3.fromRGB(255, 215, 0) -- Gold color
	step.Material = Enum.Material.Neon -- Shiny material
	step.Anchored = true
	step.CanCollide = true -- Walkable
	step.Transparency = 0.1 -- Slightly transparent for ethereal look
	step.Position = position
	step.Parent = workspace
	
	-- Add point light for glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(255, 215, 0)
	pointLight.Brightness = 1.5
	pointLight.Range = 8
	pointLight.Parent = step
	
	-- Create gold particles
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 0.25, 0) -- At the top of the step
	attachment.Parent = step
	
	local goldParticles = Instance.new("ParticleEmitter")
	goldParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	goldParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)), -- Bright gold
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)), -- Gold
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 0)) -- Darker gold
	})
	goldParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	goldParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})
	goldParticles.Rate = 30
	goldParticles.Lifetime = NumberRange.new(1, 2)
	goldParticles.Speed = NumberRange.new(1, 3)
	goldParticles.SpreadAngle = Vector2.new(45, 45)
	goldParticles.EmissionDirection = Enum.NormalId.Top
	goldParticles.Parent = attachment
	
	-- Add subtle upward particle flow
	local upwardAttachment = Instance.new("Attachment")
	upwardAttachment.Position = Vector3.new(0, -0.25, 0) -- At the bottom of the step
	upwardAttachment.Parent = step
	
	local upwardParticles = Instance.new("ParticleEmitter")
	upwardParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	upwardParticles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	upwardParticles.Size = NumberSequence.new(0.2, 0.4)
	upwardParticles.Transparency = NumberSequence.new(0.3, 1)
	upwardParticles.Rate = 15
	upwardParticles.Lifetime = NumberRange.new(0.5, 1)
	upwardParticles.Speed = NumberRange.new(2, 4)
	upwardParticles.SpreadAngle = Vector2.new(30, 30)
	upwardParticles.VelocityInheritance = 0
	upwardParticles.Parent = upwardAttachment
	
	return step
end

-- Helper: get (or create) the folder that holds references to staircase
local function getOrCreateStaircaseFolder(character: Model)
	local folder = character:FindFirstChild("GoldStaircaseFolder")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "GoldStaircaseFolder"
		folder.Archivable = false
		folder.Parent = character
	end
	return folder
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("GOLD ABILITY: Activating for player:", player.Name)
	print("GOLD ABILITY: Character:", character and character.Name or "nil")
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("GOLD ABILITY: No character or HumanoidRootPart found, aborting")
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Get the player's movement direction
	local movementDirection = getMovementDirection(character)
	
	-- Find ground level (use raycast or character position)
	local groundY = humanoidRootPart.Position.Y - 2 -- Approximate ground level
	local startPosition = humanoidRootPart.Position + (movementDirection * 5)
	startPosition = Vector3.new(startPosition.X, groundY, startPosition.Z)
	
	print("GOLD ABILITY: Creating gold staircase at position:", startPosition)
	
	-- Create folder to store references
	local folder = getOrCreateStaircaseFolder(character)
	
	-- Create staircase model to hold everything
	local staircaseModel = Instance.new("Model")
	staircaseModel.Name = ("GoldStaircase_%s"):format(tick())
	staircaseModel.Parent = workspace
	
	-- Create staircase steps and coins
	local steps = {}
	local coins = {}
	for i = 1, STAIRCASE_STEPS do
		-- Calculate position for this step
		local stepOffset = movementDirection * (i * STEP_DISTANCE)
		local stepHeight = (i - 1) * STEP_HEIGHT
		local stepPosition = startPosition + stepOffset + Vector3.new(0, stepHeight + 0.25, 0)
		
		-- Create walkable step
		local step = createStep(stepPosition, i, movementDirection)
		step.Parent = staircaseModel
		table.insert(steps, step)
		
		-- Create coin on top of step
		local coinPosition = stepPosition + Vector3.new(0, 0.5, 0)
		local coin = createCoin(coinPosition, player)
		coin.Parent = staircaseModel
		table.insert(coins, coin)
		
		-- Store references
		local stepRef = Instance.new("ObjectValue")
		stepRef.Name = ("GoldStaircaseStep_%d_%s"):format(i, tick())
		stepRef.Value = step
		stepRef.Parent = folder
		
		local coinRef = Instance.new("ObjectValue")
		coinRef.Name = ("GoldStaircaseCoin_%d_%s"):format(i, tick())
		coinRef.Value = coin
		coinRef.Parent = folder
	end
	
	-- Store staircase model reference
	local staircaseRef = Instance.new("ObjectValue")
	staircaseRef.Name = ("GoldStaircaseModel_%s"):format(tick())
	staircaseRef.Value = staircaseModel
	staircaseRef.Parent = folder
	
	-- Schedule automatic cleanup after STAIRCASE_DURATION
	task.delay(STAIRCASE_DURATION, function()
		-- Fade out effect
		for _, step in ipairs(steps) do
			if step and step.Parent then
				local tween = TweenService:Create(step, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Transparency = 1
				})
				tween:Play()
			end
		end
		
		-- Destroy all after fade
		task.delay(1.1, function()
			if staircaseModel and staircaseModel.Parent then
				staircaseModel:Destroy()
			end
			
			-- Clean up references
			if folder then
				for _, ref in pairs(folder:GetChildren()) do
					if ref:IsA("ObjectValue") and (ref.Value == nil or not ref.Value.Parent) then
						ref:Destroy()
					end
				end
			end
		end)
	end)
	
	-- Also use Debris as safety net
	Debris:AddItem(staircaseModel, STAIRCASE_DURATION + 2)
	
	print("GOLD ABILITY: Gold staircase created with", STAIRCASE_STEPS, "steps, will disappear after", STAIRCASE_DURATION, "seconds")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("GOLD ABILITY: Deactivating for player:", player.Name)
	
	if not character then
		return
	end
	
	-- Remove all staircase components immediately if they exist
	local folder = character:FindFirstChild("GoldStaircaseFolder")
	if folder then
		for _, ref in pairs(folder:GetChildren()) do
			if ref:IsA("ObjectValue") and ref.Value then
				if ref.Value.Parent then
					print("GOLD ABILITY: Removing staircase component immediately")
					ref.Value:Destroy()
				end
			end
		end
		folder:Destroy()
	end
end

return Ability
