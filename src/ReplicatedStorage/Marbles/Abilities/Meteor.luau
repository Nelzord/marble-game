-- Meteor marble ability: teleports player up high and rains down meteors
local Ability = {}

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Constants
local TELEPORT_HEIGHT = 100 -- Height to teleport player upward (twice as high)
local ABILITY_COOLDOWN = 12 -- Cooldown between uses
local METEOR_RAIN_DURATION = 8 -- How long meteors rain down
local METEOR_COUNT = 60 -- Number of meteors to spawn (twice as many)
local METEOR_SPAWN_RADIUS = 40 -- Radius around player where meteors spawn
local METEOR_FALL_SPEED = 80 -- Speed at which meteors fall
local DOWNWARD_FORCE = 100 -- Force to shoot player downward

function Ability.Description()
	return "Meteor: Teleport high into the sky as meteors rain down around you."
end

function Ability.Cooldown()
	return ABILITY_COOLDOWN
end

-- Helper function to create a single meteor
local function createMeteor(spawnPosition: Vector3, targetPosition: Vector3)
	local meteor = Instance.new("Part")
	meteor.Name = "Meteor"
	meteor.Shape = Enum.PartType.Block -- Big rock shape
	meteor.Size = Vector3.new(
		math.random(30, 60) / 10, -- Bigger rocks
		math.random(30, 60) / 10,
		math.random(30, 60) / 10
	)
	meteor.Material = Enum.Material.Rock -- Rock material for realistic look
	meteor.CanCollide = true
	meteor.Anchored = false
	
	-- Random rotation for more natural rock appearance
	meteor.CFrame = CFrame.new(spawnPosition) * CFrame.Angles(
		math.rad(math.random(-45, 45)),
		math.rad(math.random(0, 360)),
		math.rad(math.random(-45, 45))
	)
	
	-- Rock colors (dark grey to brown - realistic rock colors)
	local rockColors = {
		Color3.fromRGB(80, 80, 80),    -- Dark grey
		Color3.fromRGB(100, 100, 100), -- Medium grey
		Color3.fromRGB(60, 60, 60),    -- Very dark grey
		Color3.fromRGB(90, 70, 50),    -- Brown-grey
		Color3.fromRGB(70, 70, 70),    -- Charcoal grey
	}
	meteor.Color = rockColors[math.random(1, #rockColors)]
	
	meteor.Parent = workspace
	
	-- Add fire trail effect
	local fireAttachment = Instance.new("Attachment")
	fireAttachment.Parent = meteor
	
	local fireTrail = Instance.new("ParticleEmitter")
	fireTrail.Texture = "rbxasset://textures/particles/fire_main.dds"
	fireTrail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 150, 0)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 100, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 0))
	})
	fireTrail.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(0.5, 3),
		NumberSequenceKeypoint.new(1, 1)
	})
	fireTrail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	fireTrail.Rate = 100
	fireTrail.Lifetime = NumberRange.new(0.5, 1)
	fireTrail.Speed = NumberRange.new(5, 10)
	fireTrail.SpreadAngle = Vector2.new(15, 15)
	fireTrail.Parent = fireAttachment
	
	-- Add glow to the meteor
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(255, 150, 0)
	pointLight.Brightness = 3
	pointLight.Range = 10
	pointLight.Parent = meteor
	
	-- Calculate direction to target
	local direction = (targetPosition - spawnPosition).Unit
	local distance = (targetPosition - spawnPosition).Magnitude
	
	-- Apply velocity to make meteor fall
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
	bodyVelocity.Velocity = direction * METEOR_FALL_SPEED
	bodyVelocity.Parent = meteor
	
	-- Remove velocity after a short time to let physics take over
	task.delay(0.3, function()
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
	end)
	
	-- Add smoke trail
	local smokeAttachment = Instance.new("Attachment")
	smokeAttachment.Parent = meteor
	
	local smokeTrail = Instance.new("ParticleEmitter")
	smokeTrail.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smokeTrail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 100, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 50, 50))
	})
	smokeTrail.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 3),
		NumberSequenceKeypoint.new(1, 5)
	})
	smokeTrail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.8, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	})
	smokeTrail.Rate = 50
	smokeTrail.Lifetime = NumberRange.new(1, 2)
	smokeTrail.Speed = NumberRange.new(2, 5)
	smokeTrail.SpreadAngle = Vector2.new(20, 20)
	smokeTrail.Parent = smokeAttachment
	
	-- Make meteor disappear on contact with any item
	local touchedConnection
	touchedConnection = meteor.Touched:Connect(function(hit)
		if meteor and meteor.Parent then
			-- Disconnect the connection
			if touchedConnection then
				touchedConnection:Disconnect()
			end
			
			-- Create impact effect
			local impactPart = Instance.new("Part")
			impactPart.Name = "MeteorImpact"
			impactPart.Shape = Enum.PartType.Ball
			impactPart.Size = Vector3.new(3, 3, 3)
			impactPart.Position = meteor.Position
			impactPart.Anchored = true
			impactPart.CanCollide = false
			impactPart.Material = Enum.Material.Neon
			impactPart.Color = Color3.fromRGB(255, 150, 0)
			impactPart.Transparency = 0.3
			impactPart.Parent = workspace
			
			-- Impact glow
			local impactLight = Instance.new("PointLight")
			impactLight.Color = Color3.fromRGB(255, 150, 0)
			impactLight.Brightness = 5
			impactLight.Range = 15
			impactLight.Parent = impactPart
			
			-- Animate impact
			local impactTween = TweenService:Create(impactPart, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(8, 8, 8),
				Transparency = 1
			})
			impactTween:Play()
			impactTween.Completed:Connect(function()
				impactPart:Destroy()
			end)
			
			-- Fade out and destroy meteor
			local tween = TweenService:Create(meteor, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1
			})
			tween:Play()
			tween.Completed:Wait()
			meteor:Destroy()
		end
	end)
	
	-- Safety cleanup after timeout
	task.delay(10, function()
		if meteor and meteor.Parent then
			if touchedConnection then
				touchedConnection:Disconnect()
			end
			-- Fade out effect
			local tween = TweenService:Create(meteor, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1
			})
			tween:Play()
			tween.Completed:Wait()
			meteor:Destroy()
		end
	end)
end

-- Helper function to create teleportation effect
local function createTeleportEffect(position: Vector3)
	local teleportEffect = Instance.new("Part")
	teleportEffect.Shape = Enum.PartType.Ball
	teleportEffect.Size = Vector3.new(8, 8, 8)
	teleportEffect.Position = position
	teleportEffect.Anchored = true
	teleportEffect.CanCollide = false
	teleportEffect.Material = Enum.Material.Neon
	teleportEffect.Color = Color3.fromRGB(255, 150, 0) -- Orange meteor color
	teleportEffect.Transparency = 0.3
	teleportEffect.Parent = workspace
	
	-- Add glow
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 150, 0)
	glow.Brightness = 5
	glow.Range = 20
	glow.Parent = teleportEffect
	
	-- Animate the effect
	local tween = TweenService:Create(teleportEffect, TweenInfo.new(0.6), {
		Size = Vector3.new(20, 20, 20),
		Transparency = 1
	})
	
	tween:Play()
	tween.Completed:Connect(function()
		teleportEffect:Destroy()
	end)
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("METEOR ABILITY: Activating for player:", player.Name)
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("METEOR ABILITY: No character or HumanoidRootPart found, aborting")
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Check if meteor is already active
	local prev = character:GetAttribute("MeteorActive")
	if typeof(prev) == "boolean" and prev then
		print("METEOR ABILITY: Already active")
		return
	end
	
	-- Set meteor attribute to true
	character:SetAttribute("MeteorActive", true)
	
	print("METEOR ABILITY: Teleporting player and raining meteors")
	
	-- Create teleportation effect at current position
	createTeleportEffect(humanoidRootPart.Position)
	
	-- Calculate teleportation position (high in the sky)
	local currentPosition = humanoidRootPart.Position
	local teleportPosition = currentPosition + Vector3.new(0, TELEPORT_HEIGHT, 0)
	
	-- Small delay before teleport for effect
	task.delay(0.2, function()
		if not character or not character.Parent then return end
		
		-- Teleport player
		humanoidRootPart.CFrame = CFrame.new(teleportPosition)
		
		-- Create teleportation effect at new position
		createTeleportEffect(teleportPosition)
		
		-- Small delay before shooting player down
		task.delay(0.3, function()
			if not character or not character.Parent then return end
			
			-- Shoot player downward with force
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Name = "MeteorDownwardForce"
			bodyVelocity.MaxForce = Vector3.new(0, DOWNWARD_FORCE * 2000, 0)
			bodyVelocity.Velocity = Vector3.new(0, -DOWNWARD_FORCE, 0)
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
				if elapsed > 1.5 then -- Force duration
					connection:Disconnect()
					bodyVelocity:Destroy()
					return
				end
				
				-- Ease out the force
				local progress = elapsed / 1.5
				local easedForce = DOWNWARD_FORCE * (1 - progress * progress)
				bodyVelocity.Velocity = Vector3.new(0, -easedForce, 0)
			end)
			
			-- Safety cleanup
			task.delay(2, function()
				if bodyVelocity and bodyVelocity.Parent then
					bodyVelocity:Destroy()
				end
				if connection then
					connection:Disconnect()
				end
			end)
		end)
	end)
	
	-- Start raining meteors
	local meteorSpawnInterval = METEOR_RAIN_DURATION / METEOR_COUNT
	local meteorsSpawned = 0
	
	local function spawnMeteor()
		if not character or not character.Parent then return end
		if meteorsSpawned >= METEOR_COUNT then return end
		
		meteorsSpawned += 1
		
		-- Get player's ground position (where they were before teleporting)
		local groundPosition = Vector3.new(currentPosition.X, currentPosition.Y, currentPosition.Z)
		
		-- Random position around the ground position
		local angle = math.random() * math.pi * 2
		local radius = math.random() * METEOR_SPAWN_RADIUS
		local targetX = groundPosition.X + math.cos(angle) * radius
		local targetZ = groundPosition.Z + math.sin(angle) * radius
		local targetPosition = Vector3.new(targetX, groundPosition.Y, targetZ)
		
		-- Spawn meteor much higher above the target
		local spawnHeight = math.random(80, 120) -- Higher spawn height
		local spawnPosition = targetPosition + Vector3.new(0, spawnHeight, 0)
		
		-- Add some random horizontal offset to spawn position
		spawnPosition = spawnPosition + Vector3.new(
			math.random(-10, 10),
			0,
			math.random(-10, 10)
		)
		
		createMeteor(spawnPosition, targetPosition)
	end
	
	-- Spawn meteors over time
	for i = 1, METEOR_COUNT do
		task.delay(i * meteorSpawnInterval, spawnMeteor)
	end
	
	-- Reset attribute after meteor rain ends
	task.delay(METEOR_RAIN_DURATION + 1, function()
		if character then
			character:SetAttribute("MeteorActive", false)
			print("METEOR ABILITY: Meteor rain ended")
		end
	end)
	
	print("METEOR ABILITY: Activation complete")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("METEOR ABILITY: Deactivating for player:", player.Name)
	
	if character then
		character:SetAttribute("MeteorActive", false)
	end
end

return Ability
