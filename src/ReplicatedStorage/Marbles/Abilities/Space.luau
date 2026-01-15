-- Space marble ability: launches super high and creates a big smoke explosion at the base
local Ability = {}

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Constants
local LAUNCH_FORCE = 750 -- Upward force applied during launch (super high - 3x)
local LAUNCH_DURATION = 0.8 -- How long the launch force lasts
local ABILITY_COOLDOWN = 12 -- Cooldown between uses
local SMOKE_EXPLOSION_RADIUS = 30 -- Radius of the smoke explosion
local SMOKE_EXPLOSION_DURATION = 3 -- How long the smoke explosion lasts

function Ability.Description()
	return "Space: Launch super high into the sky with a massive smoke explosion at the base."
end

function Ability.Cooldown()
	return ABILITY_COOLDOWN
end

-- Helper function to create the big smoke explosion at the base
local function createSmokeExplosion(position: Vector3)
	-- Create explosion center part
	local explosionPart = Instance.new("Part")
	explosionPart.Name = "SpaceSmokeExplosion"
	explosionPart.Anchored = true
	explosionPart.CanCollide = false
	explosionPart.Transparency = 1
	explosionPart.Size = Vector3.new(1, 1, 1)
	explosionPart.Position = position
	explosionPart.Parent = workspace
	
	local explosionAttachment = Instance.new("Attachment")
	explosionAttachment.Parent = explosionPart
	
	-- Main smoke particles
	local smokeParticles = Instance.new("ParticleEmitter")
	smokeParticles.Name = "SpaceSmokeParticles"
	smokeParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smokeParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 150, 150)), -- Light gray
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(100, 100, 100)), -- Medium gray
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(60, 60, 60)), -- Dark gray
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30)) -- Very dark gray
	})
	smokeParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 5),
		NumberSequenceKeypoint.new(0.3, 12),
		NumberSequenceKeypoint.new(0.7, 15),
		NumberSequenceKeypoint.new(1, 8)
	})
	smokeParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.3, 0.4),
		NumberSequenceKeypoint.new(0.7, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	smokeParticles.Rate = 1000
	smokeParticles.Lifetime = NumberRange.new(2, 4)
	smokeParticles.Speed = NumberRange.new(20, 40)
	smokeParticles.SpreadAngle = Vector2.new(60, 60)
	smokeParticles.Acceleration = Vector3.new(0, 10, 0) -- Upward drift
	smokeParticles.RotSpeed = NumberRange.new(-30, 30)
	smokeParticles.Parent = explosionAttachment
	
	-- Additional dense smoke layer
	local denseSmoke = Instance.new("ParticleEmitter")
	denseSmoke.Name = "SpaceDenseSmoke"
	denseSmoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	denseSmoke.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 80)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 50, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
	})
	denseSmoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 8),
		NumberSequenceKeypoint.new(0.5, 18),
		NumberSequenceKeypoint.new(1, 10)
	})
	denseSmoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.4, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	denseSmoke.Rate = 600
	denseSmoke.Lifetime = NumberRange.new(2.5, 4.5)
	denseSmoke.Speed = NumberRange.new(15, 35)
	denseSmoke.SpreadAngle = Vector2.new(70, 70)
	denseSmoke.Acceleration = Vector3.new(0, 8, 0)
	denseSmoke.RotSpeed = NumberRange.new(-20, 20)
	denseSmoke.Parent = explosionAttachment
	
	-- Create expanding shockwave rings
	for i = 1, 4 do
		task.delay(i * 0.25, function()
			local ring = Instance.new("Part")
			ring.Name = "SmokeExplosionRing"
			ring.Shape = Enum.PartType.Cylinder
			ring.Anchored = true
			ring.CanCollide = false
			ring.Material = Enum.Material.Neon
			ring.Color = Color3.fromRGB(100, 100, 120) -- Gray-blue
			ring.Size = Vector3.new(0.5, SMOKE_EXPLOSION_RADIUS * 2, SMOKE_EXPLOSION_RADIUS * 2)
			ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
			ring.Transparency = 0.4
			ring.Parent = workspace
			
			local ringTween = TweenService:Create(ring, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.5, SMOKE_EXPLOSION_RADIUS * 5, SMOKE_EXPLOSION_RADIUS * 5),
				Transparency = 1
			})
			ringTween:Play()
			ringTween.Completed:Connect(function()
				ring:Destroy()
			end)
		end)
	end
	
	-- Stop particles after explosion duration
	task.delay(SMOKE_EXPLOSION_DURATION, function()
		if smokeParticles and smokeParticles.Parent then
			smokeParticles.Enabled = false
		end
		if denseSmoke and denseSmoke.Parent then
			denseSmoke.Enabled = false
		end
	end)
	
	-- Cleanup
	task.delay(SMOKE_EXPLOSION_DURATION + 3, function()
		if explosionPart and explosionPart.Parent then
			explosionPart:Destroy()
		end
	end)
end

-- Helper function to apply super high launch force
local function applyLaunchForce(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Create BodyVelocity for the launch
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "SpaceLaunchForce"
	bodyVelocity.MaxForce = Vector3.new(0, LAUNCH_FORCE * 2000, 0)
	bodyVelocity.Velocity = Vector3.new(0, LAUNCH_FORCE, 0)
	bodyVelocity.Parent = humanoidRootPart
	
	-- Gradually reduce the force
	local startTime = tick()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not bodyVelocity or not bodyVelocity.Parent then
			connection:Disconnect()
			return
		end
		
		local elapsed = tick() - startTime
		if elapsed > LAUNCH_DURATION then
			connection:Disconnect()
			bodyVelocity:Destroy()
			return
		end
		
		-- Ease out the force
		local progress = elapsed / LAUNCH_DURATION
		local easedForce = LAUNCH_FORCE * (1 - progress * progress)
		bodyVelocity.Velocity = Vector3.new(0, easedForce, 0)
	end)
	
	-- Safety cleanup
	task.delay(LAUNCH_DURATION + 0.1, function()
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
		if connection then
			connection:Disconnect()
		end
	end)
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("SPACE ABILITY: Activating for player:", player.Name)
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("SPACE ABILITY: No character or HumanoidRootPart found, aborting")
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Check if Space ability is already active
	local prev = character:GetAttribute("SpaceActive")
	if typeof(prev) == "boolean" and prev then
		print("SPACE ABILITY: Already active")
		return
	end
	
	-- Set Space attribute to true
	character:SetAttribute("SpaceActive", true)
	
	print("SPACE ABILITY: Creating smoke explosion and launching player super high")
	
	-- Get base position (where player is standing)
	local basePosition = Vector3.new(
		humanoidRootPart.Position.X,
		humanoidRootPart.Position.Y - 2, -- Slightly below player
		humanoidRootPart.Position.Z
	)
	
	-- Create the big smoke explosion at the base
	createSmokeExplosion(basePosition)
	
	-- Small delay before launch for dramatic effect
	task.delay(0.2, function()
		if not character or not character.Parent then return end
		
		-- Apply super high launch force
		applyLaunchForce(character)
	end)
	
	-- Reset attribute after launch completes
	task.delay(LAUNCH_DURATION + 1, function()
		if character then
			character:SetAttribute("SpaceActive", false)
			print("SPACE ABILITY: Launch completed")
		end
	end)
	
	print("SPACE ABILITY: Activation complete")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("SPACE ABILITY: Deactivating for player:", player.Name)
	
	if character then
		character:SetAttribute("SpaceActive", false)
		
		-- Clean up any remaining effects
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local launchForce = hrp:FindFirstChild("SpaceLaunchForce")
			if launchForce then
				launchForce:Destroy()
			end
		end
	end
end

return Ability
