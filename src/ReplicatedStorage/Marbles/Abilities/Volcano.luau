-- Volcano marble ability: spawns a volcano that erupts and shoots the player up with falling magma
local Ability = {}

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Constants
local ERUPTION_FORCE = 120 -- Upward force applied during eruption
local ERUPTION_DURATION = 0.5 -- How long the eruption force lasts
local ABILITY_COOLDOWN = 8 -- Cooldown between uses
local VOLCANO_LIFETIME = 5 -- Volcano disappears after 5 seconds
local MAGMA_ROCK_COUNT = 20 -- Number of magma rocks that fall
local VOLCANO_HEIGHT = 12 -- Height of the volcano cone
local VOLCANO_BASE_RADIUS = 8 -- Base radius of the volcano

function Ability.Description()
	return "Volcano: Summon a volcano that erupts, launching you skyward as magma rains down."
end

function Ability.Cooldown()
	return ABILITY_COOLDOWN
end

-- Helper function to create a single magma rock
local function createMagmaRock(volcanoTop: Vector3)
	local rock = Instance.new("Part")
	rock.Name = "MagmaRock"
	rock.Size = Vector3.new(
		math.random(10, 25) / 10,
		math.random(10, 25) / 10,
		math.random(10, 25) / 10
	)
	rock.Shape = Enum.PartType.Ball
	rock.Material = Enum.Material.Neon
	rock.CanCollide = true
	rock.Anchored = false
	
	-- Magma colors (orange to red)
	local magmaColors = {
		Color3.fromRGB(255, 69, 0),    -- Red-orange
		Color3.fromRGB(255, 140, 0),   -- Dark orange
		Color3.fromRGB(255, 0, 0),     -- Red
		Color3.fromRGB(255, 100, 0),   -- Orange
		Color3.fromRGB(200, 50, 0),    -- Dark red
	}
	rock.Color = magmaColors[math.random(1, #magmaColors)]
	
	-- Random offset from volcano top
	local angle = math.random() * math.pi * 2
	local spreadRadius = math.random() * 3
	rock.Position = volcanoTop + Vector3.new(
		math.cos(angle) * spreadRadius,
		math.random(5, 15),
		math.sin(angle) * spreadRadius
	)
	
	rock.Parent = workspace
	
	-- Apply random velocity to spread the magma
	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(10000, 10000, 10000)
	velocity.Velocity = Vector3.new(
		math.random(-30, 30),
		math.random(30, 60),
		math.random(-30, 30)
	)
	velocity.Parent = rock
	
	-- Remove velocity after a short time to let physics take over
	task.delay(0.2, function()
		if velocity and velocity.Parent then
			velocity:Destroy()
		end
	end)
	
	-- Add fire particles to the magma rock
	local fireAttachment = Instance.new("Attachment")
	fireAttachment.Parent = rock
	
	local fireParticles = Instance.new("ParticleEmitter")
	fireParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
	fireParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 0))
	})
	fireParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	fireParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	fireParticles.Rate = 30
	fireParticles.Lifetime = NumberRange.new(0.3, 0.6)
	fireParticles.Speed = NumberRange.new(2, 5)
	fireParticles.SpreadAngle = Vector2.new(30, 30)
	fireParticles.Parent = fireAttachment
	
	-- Add glow to the rock
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(255, 100, 0)
	pointLight.Brightness = 2
	pointLight.Range = 6
	pointLight.Parent = rock
	
	-- Cleanup after a few seconds
	task.delay(4, function()
		if rock and rock.Parent then
			-- Fade out effect
			local tween = TweenService:Create(rock, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1
			})
			tween:Play()
			tween.Completed:Wait()
			rock:Destroy()
		end
	end)
end

-- Helper function to create the volcano model
local function createVolcano(position: Vector3): Model
	local volcano = Instance.new("Model")
	volcano.Name = "VolcanoEffect"
	
	-- Create the volcano cone (using multiple cylinders stacked)
	local layers = 6
	for i = 1, layers do
		local layer = Instance.new("Part")
		layer.Name = "VolcanoLayer" .. i
		layer.Shape = Enum.PartType.Cylinder
		layer.Anchored = true
		layer.CanCollide = true
		layer.Material = Enum.Material.Rock
		
		-- Calculate size and position for this layer
		local progress = (i - 1) / (layers - 1)
		local radius = VOLCANO_BASE_RADIUS * (1 - progress * 0.7) -- Taper towards top
		local layerHeight = VOLCANO_HEIGHT / layers
		
		layer.Size = Vector3.new(layerHeight, radius * 2, radius * 2)
		layer.CFrame = CFrame.new(
			position.X,
			position.Y + (i - 0.5) * layerHeight,
			position.Z
		) * CFrame.Angles(0, 0, math.rad(90))
		
		-- Color gradient from dark at base to orange/red at top
		local colorProgress = progress
		layer.Color = Color3.fromRGB(
			60 + colorProgress * 140,
			40 + colorProgress * 30,
			30
		)
		
		layer.Parent = volcano
	end
	
	-- Create the crater at the top
	local crater = Instance.new("Part")
	crater.Name = "VolcanoCrater"
	crater.Shape = Enum.PartType.Cylinder
	crater.Anchored = true
	crater.CanCollide = false
	crater.Material = Enum.Material.Neon
	crater.Color = Color3.fromRGB(255, 100, 0)
	crater.Size = Vector3.new(1, VOLCANO_BASE_RADIUS * 0.6, VOLCANO_BASE_RADIUS * 0.6)
	crater.CFrame = CFrame.new(
		position.X,
		position.Y + VOLCANO_HEIGHT,
		position.Z
	) * CFrame.Angles(0, 0, math.rad(90))
	crater.Parent = volcano
	
	-- Add lava glow inside crater
	local lavaGlow = Instance.new("PointLight")
	lavaGlow.Color = Color3.fromRGB(255, 100, 0)
	lavaGlow.Brightness = 5
	lavaGlow.Range = 20
	lavaGlow.Parent = crater
	
	-- Add smoke particles at the top
	local smokeAttachment = Instance.new("Attachment")
	smokeAttachment.Position = Vector3.new(0, 0, 0)
	smokeAttachment.Parent = crater
	
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "VolcanoSmoke"
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 100, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 50, 50))
	})
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 8)
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.8, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	smoke.Rate = 20
	smoke.Lifetime = NumberRange.new(3, 5)
	smoke.Speed = NumberRange.new(10, 20)
	smoke.SpreadAngle = Vector2.new(15, 15)
	smoke.RotSpeed = NumberRange.new(-30, 30)
	smoke.Parent = smokeAttachment
	
	-- Add fire/lava particles
	local fireAttachment = Instance.new("Attachment")
	fireAttachment.Parent = crater
	
	local fireParticles = Instance.new("ParticleEmitter")
	fireParticles.Name = "VolcanoFire"
	fireParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
	fireParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 150, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 0))
	})
	fireParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 3),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	fireParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	fireParticles.Rate = 80
	fireParticles.Lifetime = NumberRange.new(0.5, 1.5)
	fireParticles.Speed = NumberRange.new(15, 30)
	fireParticles.SpreadAngle = Vector2.new(20, 20)
	fireParticles.Acceleration = Vector3.new(0, -10, 0)
	fireParticles.Parent = fireAttachment
	
	volcano.Parent = workspace
	
	return volcano
end

-- Helper function to create eruption visual effects
local function createEruptionEffect(volcanoTop: Vector3)
	-- Create a burst of fire particles
	local burstPart = Instance.new("Part")
	burstPart.Name = "EruptionBurst"
	burstPart.Anchored = true
	burstPart.CanCollide = false
	burstPart.Transparency = 1
	burstPart.Size = Vector3.new(1, 1, 1)
	burstPart.Position = volcanoTop
	burstPart.Parent = workspace
	
	local burstAttachment = Instance.new("Attachment")
	burstAttachment.Parent = burstPart
	
	-- Intense fire burst
	local burstParticles = Instance.new("ParticleEmitter")
	burstParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
	burstParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 0))
	})
	burstParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(0.5, 5),
		NumberSequenceKeypoint.new(1, 1)
	})
	burstParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	burstParticles.Rate = 500
	burstParticles.Lifetime = NumberRange.new(0.5, 1)
	burstParticles.Speed = NumberRange.new(50, 80)
	burstParticles.SpreadAngle = Vector2.new(30, 30)
	burstParticles.Parent = burstAttachment
	
	-- Bright flash
	local flash = Instance.new("PointLight")
	flash.Color = Color3.fromRGB(255, 200, 100)
	flash.Brightness = 10
	flash.Range = 50
	flash.Parent = burstPart
	
	-- Fade out the flash
	task.spawn(function()
		for i = 1, 10 do
			task.wait(0.05)
			flash.Brightness = 10 - i
		end
	end)
	
	-- Stop burst after a short time
	task.delay(0.5, function()
		burstParticles.Enabled = false
	end)
	
	-- Cleanup
	task.delay(2, function()
		if burstPart and burstPart.Parent then
			burstPart:Destroy()
		end
	end)
	
	-- Spawn magma rocks
	for i = 1, MAGMA_ROCK_COUNT do
		task.delay(i * 0.05, function()
			createMagmaRock(volcanoTop)
		end)
	end
end

-- Helper function to apply eruption force to player
local function applyEruptionForce(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Create BodyVelocity for the eruption launch
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "VolcanoEruptionForce"
	bodyVelocity.MaxForce = Vector3.new(0, ERUPTION_FORCE * 2000, 0)
	bodyVelocity.Velocity = Vector3.new(0, ERUPTION_FORCE, 0)
	bodyVelocity.Parent = humanoidRootPart
	
	-- Add some fire particles to the player during eruption
	local playerFireAttachment = Instance.new("Attachment")
	playerFireAttachment.Name = "EruptionFireAttachment"
	playerFireAttachment.Parent = humanoidRootPart
	
	local playerFire = Instance.new("ParticleEmitter")
	playerFire.Name = "EruptionFireParticles"
	playerFire.Texture = "rbxasset://textures/particles/fire_main.dds"
	playerFire.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0))
	})
	playerFire.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(1, 0.3)
	})
	playerFire.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1)
	})
	playerFire.Rate = 100
	playerFire.Lifetime = NumberRange.new(0.3, 0.6)
	playerFire.Speed = NumberRange.new(5, 10)
	playerFire.SpreadAngle = Vector2.new(180, 180)
	playerFire.Parent = playerFireAttachment
	
	-- Gradually reduce the force
	local startTime = tick()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not bodyVelocity or not bodyVelocity.Parent then
			connection:Disconnect()
			return
		end
		
		local elapsed = tick() - startTime
		if elapsed > ERUPTION_DURATION then
			connection:Disconnect()
			bodyVelocity:Destroy()
			return
		end
		
		-- Ease out the force
		local progress = elapsed / ERUPTION_DURATION
		local easedForce = ERUPTION_FORCE * (1 - progress * progress)
		bodyVelocity.Velocity = Vector3.new(0, easedForce, 0)
	end)
	
	-- Cleanup fire particles after eruption
	task.delay(ERUPTION_DURATION + 0.5, function()
		if playerFire and playerFire.Parent then
			playerFire.Enabled = false
		end
		task.delay(1, function()
			if playerFireAttachment and playerFireAttachment.Parent then
				playerFireAttachment:Destroy()
			end
		end)
	end)
	
	-- Safety cleanup for bodyVelocity
	task.delay(ERUPTION_DURATION + 0.1, function()
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
	end)
end

-- Helper function to destroy volcano with fade effect
local function destroyVolcanoWithEffect(volcano: Model)
	-- Disable new particles first
	for _, descendant in volcano:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = false
		end
	end
	
	-- Fade out all parts
	for _, descendant in volcano:GetDescendants() do
		if descendant:IsA("BasePart") then
			local tween = TweenService:Create(
				descendant,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Transparency = 1 }
			)
			tween:Play()
		end
		if descendant:IsA("PointLight") then
			local tween = TweenService:Create(
				descendant,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Brightness = 0 }
			)
			tween:Play()
		end
	end
	
	-- Destroy after fade completes
	task.delay(1.5, function()
		if volcano and volcano.Parent then
			volcano:Destroy()
		end
	end)
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("VOLCANO ABILITY: Activating for player:", player.Name)
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("VOLCANO ABILITY: No character or HumanoidRootPart found, aborting")
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Check if volcano is already active
	local prev = character:GetAttribute("VolcanoActive")
	if typeof(prev) == "boolean" and prev then
		print("VOLCANO ABILITY: Already active")
		return
	end
	
	-- Set volcano attribute to true
	character:SetAttribute("VolcanoActive", true)
	
	print("VOLCANO ABILITY: Creating volcano and erupting player")
	
	-- Get position for volcano (below the player)
	local volcanoPosition = Vector3.new(
		humanoidRootPart.Position.X,
		humanoidRootPart.Position.Y - 3,
		humanoidRootPart.Position.Z
	)
	
	-- Create the volcano
	local volcano = createVolcano(volcanoPosition)
	
	-- Small delay before eruption
	task.delay(0.3, function()
		if not character or not character.Parent then return end
		
		-- Get the top of volcano position
		local volcanoTop = Vector3.new(
			volcanoPosition.X,
			volcanoPosition.Y + VOLCANO_HEIGHT,
			volcanoPosition.Z
		)
		
		-- Create eruption effects
		createEruptionEffect(volcanoTop)
		
		-- Apply eruption force to player
		applyEruptionForce(character)
	end)
	
	-- Schedule volcano destruction after VOLCANO_LIFETIME seconds
	task.delay(VOLCANO_LIFETIME, function()
		print("VOLCANO ABILITY: Destroying volcano after", VOLCANO_LIFETIME, "seconds")
		destroyVolcanoWithEffect(volcano)
	end)
	
	-- Reset attribute after effect ends
	task.delay(ERUPTION_DURATION + 1, function()
		if character then
			character:SetAttribute("VolcanoActive", false)
			print("VOLCANO ABILITY: Eruption ended")
		end
	end)
	
	print("VOLCANO ABILITY: Activation complete")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("VOLCANO ABILITY: Deactivating for player:", player.Name)
	
	if character then
		character:SetAttribute("VolcanoActive", false)
		
		-- Clean up any remaining eruption force
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local eruptionForce = hrp:FindFirstChild("VolcanoEruptionForce")
			if eruptionForce then
				eruptionForce:Destroy()
			end
			
			local fireAttachment = hrp:FindFirstChild("EruptionFireAttachment")
			if fireAttachment then
				fireAttachment:Destroy()
			end
		end
	end
end

return Ability
