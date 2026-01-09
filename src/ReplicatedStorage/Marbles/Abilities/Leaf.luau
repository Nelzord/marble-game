-- Leaf marble ability: creates a gust/tornado of leaves that glides the player up
local Ability = {}

-- Constants
local LIFT_FORCE = 30 -- Upward force applied (half power)
local LIFT_DURATION = 1.5 -- How long the lift lasts
local ABILITY_COOLDOWN = 5 -- Cooldown between uses
local LEAF_COUNT = 50 -- Number of leaf particles to spawn
local TORNADO_RADIUS = 5 -- Radius of the leaf tornado

function Ability.Description()
	return "Leaf: Create a gust of swirling leaves that lifts you into the air."
end

function Ability.Cooldown()
	return ABILITY_COOLDOWN
end

-- Helper function to create a single leaf particle
local function createLeafParticle(position: Vector3, character: Model)
	local leaf = Instance.new("Part")
	leaf.Name = "LeafParticle"
	leaf.Size = Vector3.new(0.5, 0.1, 0.3)
	leaf.Shape = Enum.PartType.Block
	leaf.Material = Enum.Material.Grass
	leaf.CanCollide = false
	leaf.Anchored = false
	leaf.Massless = true
	
	-- Random leaf colors (various greens, yellows, oranges for autumn feel)
	local leafColors = {
		Color3.fromRGB(34, 139, 34),   -- Forest green
		Color3.fromRGB(50, 205, 50),   -- Lime green
		Color3.fromRGB(85, 107, 47),   -- Dark olive green
		Color3.fromRGB(154, 205, 50),  -- Yellow green
		Color3.fromRGB(255, 165, 0),   -- Orange
		Color3.fromRGB(255, 140, 0),   -- Dark orange
	}
	leaf.Color = leafColors[math.random(1, #leafColors)]
	
	-- Random offset around the character
	local angle = math.random() * math.pi * 2
	local radius = math.random() * TORNADO_RADIUS
	local offsetX = math.cos(angle) * radius
	local offsetZ = math.sin(angle) * radius
	local offsetY = math.random() * 2 - 1
	
	leaf.Position = position + Vector3.new(offsetX, offsetY, offsetZ)
	leaf.Parent = workspace
	
	-- Add spinning motion
	local angularVelocity = Instance.new("AngularVelocity")
	angularVelocity.MaxTorque = 1000
	angularVelocity.AngularVelocity = Vector3.new(
		math.random(-10, 10),
		math.random(-10, 10),
		math.random(-10, 10)
	)
	angularVelocity.Attachment0 = Instance.new("Attachment", leaf)
	angularVelocity.Parent = leaf
	
	-- Swirling upward motion using BodyVelocity
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(500, 500, 500)
	
	-- Create swirling effect
	local startTime = tick()
	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		if not leaf or not leaf.Parent then
			connection:Disconnect()
			return
		end
		
		local elapsed = tick() - startTime
		if elapsed > LIFT_DURATION + 1 then
			connection:Disconnect()
			leaf:Destroy()
			return
		end
		
		-- Spiral upward motion
		local spiralSpeed = 8
		local upwardSpeed = 15 + math.random() * 5
		local currentAngle = angle + elapsed * spiralSpeed
		local currentRadius = radius * (1 - elapsed / (LIFT_DURATION + 1))
		
		bodyVelocity.Velocity = Vector3.new(
			math.cos(currentAngle) * spiralSpeed,
			upwardSpeed,
			math.sin(currentAngle) * spiralSpeed
		)
	end)
	
	bodyVelocity.Parent = leaf
	
	-- Cleanup after duration
	task.delay(LIFT_DURATION + 1.5, function()
		if leaf and leaf.Parent then
			leaf:Destroy()
		end
	end)
end

-- Helper function to create the tornado visual effect
local function createTornadoEffect(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	local position = humanoidRootPart.Position
	
	-- Create multiple leaf particles
	for i = 1, LEAF_COUNT do
		task.delay(i * 0.05, function()
			createLeafParticle(position, character)
		end)
	end
	
	-- Create wind particle effect
	local attachment = Instance.new("Attachment")
	attachment.Name = "LeafTornadoAttachment"
	attachment.Parent = humanoidRootPart
	
	-- Main leaf/wind particles
	local windParticles = Instance.new("ParticleEmitter")
	windParticles.Name = "LeafWindParticles"
	windParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	windParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 139, 34)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(154, 205, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 165, 0))
	})
	windParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0.1)
	})
	windParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	windParticles.Rate = 350
	windParticles.Lifetime = NumberRange.new(0.8, 1.5)
	windParticles.Speed = NumberRange.new(10, 20)
	windParticles.SpreadAngle = Vector2.new(360, 30)
	windParticles.RotSpeed = NumberRange.new(-180, 180)
	windParticles.Rotation = NumberRange.new(0, 360)
	windParticles.Acceleration = Vector3.new(0, 15, 0) -- Upward acceleration
	windParticles.Parent = attachment
	
	-- Add a green glow effect
	local glowEffect = Instance.new("PointLight")
	glowEffect.Name = "LeafGlow"
	glowEffect.Color = Color3.fromRGB(100, 200, 100)
	glowEffect.Brightness = 2
	glowEffect.Range = 12
	glowEffect.Parent = humanoidRootPart
	
	-- Cleanup after duration
	task.delay(LIFT_DURATION + 0.5, function()
		if windParticles and windParticles.Parent then
			windParticles.Enabled = false
			task.delay(1.5, function()
				if attachment and attachment.Parent then
					attachment:Destroy()
				end
			end)
		end
		if glowEffect and glowEffect.Parent then
			glowEffect:Destroy()
		end
	end)
end

-- Helper function to apply lift force
local function applyLiftForce(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Create BodyVelocity for the upward lift
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "LeafLiftForce"
	bodyVelocity.MaxForce = Vector3.new(0, LIFT_FORCE * 1000, 0)
	bodyVelocity.Velocity = Vector3.new(0, LIFT_FORCE, 0)
	bodyVelocity.Parent = humanoidRootPart
	
	-- Gradually reduce the lift force for a gliding effect
	local startTime = tick()
	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		if not bodyVelocity or not bodyVelocity.Parent then
			connection:Disconnect()
			return
		end
		
		local elapsed = tick() - startTime
		if elapsed > LIFT_DURATION then
			connection:Disconnect()
			bodyVelocity:Destroy()
			return
		end
		
		-- Ease out the lift force
		local progress = elapsed / LIFT_DURATION
		local easedForce = LIFT_FORCE * (1 - progress * progress)
		bodyVelocity.Velocity = Vector3.new(0, easedForce, 0)
	end)
	
	-- Safety cleanup
	task.delay(LIFT_DURATION + 0.1, function()
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
	end)
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("LEAF ABILITY: Activating for player:", player.Name)
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("LEAF ABILITY: No character or HumanoidRootPart found, aborting")
		return
	end
	
	-- Check if leaf gust is already active
	local prev = character:GetAttribute("LeafGustActive")
	if typeof(prev) == "boolean" and prev then
		print("LEAF ABILITY: Already active")
		return
	end
	
	-- Set leaf gust attribute to true
	character:SetAttribute("LeafGustActive", true)
	character:SetAttribute("LeafGlowActive", true)
	
	print("LEAF ABILITY: Creating leaf tornado and lifting player")
	
	-- Apply the lift force
	applyLiftForce(character)
	
	-- Create the tornado visual effect
	createTornadoEffect(character)
	
	-- Reset after duration
	task.delay(LIFT_DURATION, function()
		if character then
			character:SetAttribute("LeafGustActive", false)
			character:SetAttribute("LeafGlowActive", false)
			print("LEAF ABILITY: Leaf gust ended")
		end
	end)
	
	print("LEAF ABILITY: Activation complete")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("LEAF ABILITY: Deactivating for player:", player.Name)
	
	if character then
		character:SetAttribute("LeafGustActive", false)
		character:SetAttribute("LeafGlowActive", false)
		
		-- Clean up any remaining lift force
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local liftForce = hrp:FindFirstChild("LeafLiftForce")
			if liftForce then
				liftForce:Destroy()
			end
			
			local attachment = hrp:FindFirstChild("LeafTornadoAttachment")
			if attachment then
				attachment:Destroy()
			end
			
			local glow = hrp:FindFirstChild("LeafGlow")
			if glow then
				glow:Destroy()
			end
		end
	end
end

return Ability
