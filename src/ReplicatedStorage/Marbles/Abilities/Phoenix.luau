-- Phoenix marble ability: creates a big yellow and blue flame explosion, launches the marble up, then falls down slowly with blue/yellow sparkle and trail
local Ability = {}

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Constants
local EXPLOSION_RADIUS = 25 -- Radius of the flame explosion
local LAUNCH_FORCE = 150 -- Upward force applied during launch
local LAUNCH_DURATION = 0.6 -- How long the launch force lasts
local SLOW_FALL_MULTIPLIER = 0.3 -- Multiplier for slow fall (0.3 = 30% of normal gravity)
local ABILITY_COOLDOWN = 10 -- Cooldown between uses
local EXPLOSION_DURATION = 1.5 -- How long the explosion effects last
local SPARKLE_LIFETIME = 5 -- How long sparkles persist
local TRAIL_LIFETIME = 3 -- How long the trail persists

function Ability.Description()
	return "Phoenix: Create a massive flame explosion, launch skyward, then descend slowly with magical sparkles and a fiery trail."
end

function Ability.Cooldown()
	return ABILITY_COOLDOWN
end

-- Helper function to create the flame explosion effect
local function createFlameExplosion(position: Vector3)
	-- Create explosion center part
	local explosionPart = Instance.new("Part")
	explosionPart.Name = "PhoenixExplosion"
	explosionPart.Anchored = true
	explosionPart.CanCollide = false
	explosionPart.Transparency = 1
	explosionPart.Size = Vector3.new(1, 1, 1)
	explosionPart.Position = position
	explosionPart.Parent = workspace
	
	local explosionAttachment = Instance.new("Attachment")
	explosionAttachment.Parent = explosionPart
	
	-- Yellow flame particles
	local yellowFlames = Instance.new("ParticleEmitter")
	yellowFlames.Name = "YellowFlames"
	yellowFlames.Texture = "rbxasset://textures/particles/fire_main.dds"
	yellowFlames.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)), -- Bright yellow
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 200, 0)), -- Golden yellow
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 150, 0)), -- Orange-yellow
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 0)) -- Dark orange
	})
	yellowFlames.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 4),
		NumberSequenceKeypoint.new(0.3, 8),
		NumberSequenceKeypoint.new(0.7, 6),
		NumberSequenceKeypoint.new(1, 2)
	})
	yellowFlames.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	yellowFlames.Rate = 800
	yellowFlames.Lifetime = NumberRange.new(0.8, 1.5)
	yellowFlames.Speed = NumberRange.new(60, 100)
	yellowFlames.SpreadAngle = Vector2.new(45, 45)
	yellowFlames.Acceleration = Vector3.new(0, -5, 0)
	yellowFlames.Parent = explosionAttachment
	
	-- Blue flame particles
	local blueFlames = Instance.new("ParticleEmitter")
	blueFlames.Name = "BlueFlames"
	blueFlames.Texture = "rbxasset://textures/particles/fire_main.dds"
	blueFlames.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 220, 255)), -- Light blue
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(100, 180, 255)), -- Bright blue
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(50, 150, 255)), -- Deep blue
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 200)) -- Dark blue
	})
	blueFlames.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(0.3, 7),
		NumberSequenceKeypoint.new(0.7, 5),
		NumberSequenceKeypoint.new(1, 1.5)
	})
	blueFlames.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	blueFlames.Rate = 600
	blueFlames.Lifetime = NumberRange.new(0.8, 1.5)
	blueFlames.Speed = NumberRange.new(50, 90)
	blueFlames.SpreadAngle = Vector2.new(45, 45)
	blueFlames.Acceleration = Vector3.new(0, -5, 0)
	blueFlames.Parent = explosionAttachment
	
	-- Bright flash effect
	local flash = Instance.new("PointLight")
	flash.Color = Color3.fromRGB(255, 200, 100)
	flash.Brightness = 15
	flash.Range = 60
	flash.Parent = explosionPart
	
	-- Fade out the flash
	task.spawn(function()
		for i = 1, 20 do
			task.wait(0.05)
			if flash and flash.Parent then
				flash.Brightness = 15 - (i * 0.7)
			end
		end
	end)
	
	-- Create expanding shockwave rings
	for i = 1, 3 do
		task.delay(i * 0.2, function()
			local ring = Instance.new("Part")
			ring.Name = "ExplosionRing"
			ring.Shape = Enum.PartType.Cylinder
			ring.Anchored = true
			ring.CanCollide = false
			ring.Material = Enum.Material.Neon
			ring.Color = i % 2 == 1 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(100, 180, 255)
			ring.Size = Vector3.new(0.5, EXPLOSION_RADIUS * 2, EXPLOSION_RADIUS * 2)
			ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
			ring.Transparency = 0.3
			ring.Parent = workspace
			
			local ringTween = TweenService:Create(ring, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.5, EXPLOSION_RADIUS * 4, EXPLOSION_RADIUS * 4),
				Transparency = 1
			})
			ringTween:Play()
			ringTween.Completed:Connect(function()
				ring:Destroy()
			end)
		end)
	end
	
	-- Stop particles after explosion duration
	task.delay(EXPLOSION_DURATION, function()
		if yellowFlames and yellowFlames.Parent then
			yellowFlames.Enabled = false
		end
		if blueFlames and blueFlames.Parent then
			blueFlames.Enabled = false
		end
	end)
	
	-- Cleanup
	task.delay(EXPLOSION_DURATION + 2, function()
		if explosionPart and explosionPart.Parent then
			explosionPart:Destroy()
		end
	end)
end

-- Helper function to apply launch force
local function applyLaunchForce(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Create BodyVelocity for the launch
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "PhoenixLaunchForce"
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

-- Helper function to apply slow fall
local function applySlowFall(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Create BodyVelocity to counteract gravity
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "PhoenixSlowFall"
	bodyVelocity.MaxForce = Vector3.new(0, 4000, 0)
	bodyVelocity.Parent = humanoidRootPart
	
	-- Apply upward force to slow fall
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not bodyVelocity or not bodyVelocity.Parent or not humanoidRootPart or not humanoidRootPart.Parent then
			if connection then
				connection:Disconnect()
			end
			return
		end
		
		-- Get current velocity
		local currentVelocity = humanoidRootPart.AssemblyLinearVelocity
		
		-- If falling, apply upward force to slow it
		if currentVelocity.Y < 0 then
			-- Apply upward force proportional to fall speed
			local upwardForce = math.abs(currentVelocity.Y) * (1 - SLOW_FALL_MULTIPLIER)
			bodyVelocity.Velocity = Vector3.new(0, upwardForce, 0)
		else
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		end
	end)
	
	-- Cleanup after a reasonable time or when character touches ground
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		local groundCheckConnection
		groundCheckConnection = RunService.Heartbeat:Connect(function()
			if not character or not character.Parent then
				groundCheckConnection:Disconnect()
				if connection then
					connection:Disconnect()
				end
				if bodyVelocity and bodyVelocity.Parent then
					bodyVelocity:Destroy()
				end
				return
			end
			
			-- Check if on ground
			if humanoid.FloorMaterial ~= Enum.Material.Air then
				groundCheckConnection:Disconnect()
				if connection then
					connection:Disconnect()
				end
				if bodyVelocity and bodyVelocity.Parent then
					bodyVelocity:Destroy()
				end
			end
		end)
		
		-- Safety timeout
		task.delay(10, function()
			groundCheckConnection:Disconnect()
			if connection then
				connection:Disconnect()
			end
			if bodyVelocity and bodyVelocity.Parent then
				bodyVelocity:Destroy()
			end
		end)
	else
		-- Fallback timeout if no humanoid
		task.delay(10, function()
			if connection then
				connection:Disconnect()
			end
			if bodyVelocity and bodyVelocity.Parent then
				bodyVelocity:Destroy()
			end
		end)
	end
end

-- Helper function to create sparkle effects
local function createSparkles(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Yellow sparkles attachment
	local yellowAttachment = Instance.new("Attachment")
	yellowAttachment.Name = "PhoenixYellowSparkles"
	yellowAttachment.Parent = humanoidRootPart
	
	local yellowSparkles = Instance.new("ParticleEmitter")
	yellowSparkles.Name = "YellowSparkles"
	yellowSparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	yellowSparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 0))
	})
	yellowSparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	yellowSparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	yellowSparkles.Rate = 100
	yellowSparkles.Lifetime = NumberRange.new(0.5, 1.5)
	yellowSparkles.Speed = NumberRange.new(2, 8)
	yellowSparkles.SpreadAngle = Vector2.new(360, 360)
	yellowSparkles.Parent = yellowAttachment
	
	-- Blue sparkles attachment
	local blueAttachment = Instance.new("Attachment")
	blueAttachment.Name = "PhoenixBlueSparkles"
	blueAttachment.Parent = humanoidRootPart
	
	local blueSparkles = Instance.new("ParticleEmitter")
	blueSparkles.Name = "BlueSparkles"
	blueSparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	blueSparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 220, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 180, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 150, 255))
	})
	blueSparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	blueSparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	blueSparkles.Rate = 100
	blueSparkles.Lifetime = NumberRange.new(0.5, 1.5)
	blueSparkles.Speed = NumberRange.new(2, 8)
	blueSparkles.SpreadAngle = Vector2.new(360, 360)
	blueSparkles.Parent = blueAttachment
	
	-- Cleanup after lifetime
	task.delay(SPARKLE_LIFETIME, function()
		if yellowSparkles and yellowSparkles.Parent then
			yellowSparkles.Enabled = false
		end
		if blueSparkles and blueSparkles.Parent then
			blueSparkles.Enabled = false
		end
		task.delay(2, function()
			if yellowAttachment and yellowAttachment.Parent then
				yellowAttachment:Destroy()
			end
			if blueAttachment and blueAttachment.Parent then
				blueAttachment:Destroy()
			end
		end)
	end)
end

-- Helper function to create wing effects during launch
local function createLaunchWings(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Create left wing attachment for launch
	local leftWingAttachment = Instance.new("Attachment")
	leftWingAttachment.Name = "PhoenixLaunchLeftWing"
	leftWingAttachment.Position = Vector3.new(-3, 0, 0) -- Left side, further out
	leftWingAttachment.Parent = humanoidRootPart
	
	local leftWingParticles = Instance.new("ParticleEmitter")
	leftWingParticles.Name = "PhoenixLaunchLeftWingParticles"
	leftWingParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
	leftWingParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)), -- Bright yellow
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 200, 0)), -- Golden
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(100, 180, 255)), -- Blue
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 150, 255)) -- Deep blue
	})
	leftWingParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 2.5),
		NumberSequenceKeypoint.new(0.6, 3),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	leftWingParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.4, 0.3),
		NumberSequenceKeypoint.new(0.7, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	leftWingParticles.Rate = 200
	leftWingParticles.Lifetime = NumberRange.new(0.5, 1)
	leftWingParticles.Speed = NumberRange.new(8, 15)
	leftWingParticles.SpreadAngle = Vector2.new(80, 60) -- Wide wing spread
	leftWingParticles.Rotation = NumberRange.new(-60, 60)
	leftWingParticles.Acceleration = Vector3.new(0, 5, 0) -- Slight upward drift
	leftWingParticles.LightEmission = 1
	leftWingParticles.Parent = leftWingAttachment
	
	-- Create right wing attachment for launch
	local rightWingAttachment = Instance.new("Attachment")
	rightWingAttachment.Name = "PhoenixLaunchRightWing"
	rightWingAttachment.Position = Vector3.new(3, 0, 0) -- Right side, further out
	rightWingAttachment.Parent = humanoidRootPart
	
	local rightWingParticles = Instance.new("ParticleEmitter")
	rightWingParticles.Name = "PhoenixLaunchRightWingParticles"
	rightWingParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
	rightWingParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)), -- Bright yellow
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 200, 0)), -- Golden
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(100, 180, 255)), -- Blue
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 150, 255)) -- Deep blue
	})
	rightWingParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 2.5),
		NumberSequenceKeypoint.new(0.6, 3),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	rightWingParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.4, 0.3),
		NumberSequenceKeypoint.new(0.7, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	rightWingParticles.Rate = 200
	rightWingParticles.Lifetime = NumberRange.new(0.5, 1)
	rightWingParticles.Speed = NumberRange.new(8, 15)
	rightWingParticles.SpreadAngle = Vector2.new(80, 60) -- Wide wing spread
	rightWingParticles.Rotation = NumberRange.new(-60, 60)
	rightWingParticles.Acceleration = Vector3.new(0, 5, 0) -- Slight upward drift
	rightWingParticles.LightEmission = 1
	rightWingParticles.Parent = rightWingAttachment
	
	-- Cleanup after launch duration
	task.delay(LAUNCH_DURATION + 0.5, function()
		if leftWingParticles and leftWingParticles.Parent then
			leftWingParticles.Enabled = false
		end
		if rightWingParticles and rightWingParticles.Parent then
			rightWingParticles.Enabled = false
		end
		task.delay(1, function()
			if leftWingAttachment and leftWingAttachment.Parent then
				leftWingAttachment:Destroy()
			end
			if rightWingAttachment and rightWingAttachment.Parent then
				rightWingAttachment:Destroy()
			end
		end)
	end)
end

-- Helper function to create trail effect
local function createTrail(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Yellow trail attachment
	local yellowTrailAttachment = Instance.new("Attachment")
	yellowTrailAttachment.Name = "PhoenixYellowTrail"
	yellowTrailAttachment.Parent = humanoidRootPart
	
	local yellowTrail = Instance.new("ParticleEmitter")
	yellowTrail.Name = "YellowTrail"
	yellowTrail.Texture = "rbxasset://textures/particles/fire_main.dds"
	yellowTrail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0))
	})
	yellowTrail.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(0.5, 2),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	yellowTrail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	yellowTrail.Rate = 150
	yellowTrail.Lifetime = NumberRange.new(0.8, 1.5)
	yellowTrail.Speed = NumberRange.new(2, 5)
	yellowTrail.SpreadAngle = Vector2.new(30, 30)
	yellowTrail.LightEmission = 1
	yellowTrail.Parent = yellowTrailAttachment
	
	-- Blue trail attachment
	local blueTrailAttachment = Instance.new("Attachment")
	blueTrailAttachment.Name = "PhoenixBlueTrail"
	blueTrailAttachment.Parent = humanoidRootPart
	
	local blueTrail = Instance.new("ParticleEmitter")
	blueTrail.Name = "BlueTrail"
	blueTrail.Texture = "rbxasset://textures/particles/fire_main.dds"
	blueTrail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 220, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 180, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 150, 255))
	})
	blueTrail.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(0.5, 2),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	blueTrail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	blueTrail.Rate = 150
	blueTrail.Lifetime = NumberRange.new(0.8, 1.5)
	blueTrail.Speed = NumberRange.new(2, 5)
	blueTrail.SpreadAngle = Vector2.new(30, 30)
	blueTrail.LightEmission = 1
	blueTrail.Parent = blueTrailAttachment
	
	-- Cleanup after lifetime
	task.delay(TRAIL_LIFETIME, function()
		if yellowTrail and yellowTrail.Parent then
			yellowTrail.Enabled = false
		end
		if blueTrail and blueTrail.Parent then
			blueTrail.Enabled = false
		end
		task.delay(2, function()
			if yellowTrailAttachment and yellowTrailAttachment.Parent then
				yellowTrailAttachment:Destroy()
			end
			if blueTrailAttachment and blueTrailAttachment.Parent then
				blueTrailAttachment:Destroy()
			end
		end)
	end)
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("PHOENIX ABILITY: Activating for player:", player.Name)
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("PHOENIX ABILITY: No character or HumanoidRootPart found, aborting")
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Check if Phoenix ability is already active
	local prev = character:GetAttribute("PhoenixActive")
	if typeof(prev) == "boolean" and prev then
		print("PHOENIX ABILITY: Already active")
		return
	end
	
	-- Set Phoenix attribute to true
	character:SetAttribute("PhoenixActive", true)
	
	print("PHOENIX ABILITY: Creating explosion and launching player")
	
	-- Create the flame explosion at player's position
	createFlameExplosion(humanoidRootPart.Position)
	
	-- Small delay before launch for dramatic effect
	task.delay(0.2, function()
		if not character or not character.Parent then return end
		
		-- Apply launch force
		applyLaunchForce(character)
		
		-- Create launch wings (intense wing effect during launch)
		createLaunchWings(character)
		
		-- Create sparkles and trail
		createSparkles(character)
		createTrail(character)
		
		-- Apply slow fall after launch duration
		task.delay(LAUNCH_DURATION + 0.1, function()
			if not character or not character.Parent then return end
			applySlowFall(character)
		end)
	end)
	
	-- Reset attribute after effects end
	task.delay(LAUNCH_DURATION + TRAIL_LIFETIME + 2, function()
		if character then
			character:SetAttribute("PhoenixActive", false)
			print("PHOENIX ABILITY: Effects ended")
		end
	end)
	
	print("PHOENIX ABILITY: Activation complete")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("PHOENIX ABILITY: Deactivating for player:", player.Name)
	
	if character then
		character:SetAttribute("PhoenixActive", false)
		
		-- Clean up any remaining effects
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local launchForce = hrp:FindFirstChild("PhoenixLaunchForce")
			if launchForce then
				launchForce:Destroy()
			end
			
			local slowFall = hrp:FindFirstChild("PhoenixSlowFall")
			if slowFall then
				slowFall:Destroy()
			end
			
			-- Clean up attachments
			local yellowSparkles = hrp:FindFirstChild("PhoenixYellowSparkles")
			if yellowSparkles then
				yellowSparkles:Destroy()
			end
			
			local blueSparkles = hrp:FindFirstChild("PhoenixBlueSparkles")
			if blueSparkles then
				blueSparkles:Destroy()
			end
			
			local yellowTrail = hrp:FindFirstChild("PhoenixYellowTrail")
			if yellowTrail then
				yellowTrail:Destroy()
			end
			
			local blueTrail = hrp:FindFirstChild("PhoenixBlueTrail")
			if blueTrail then
				blueTrail:Destroy()
			end
			
			local leftWing = hrp:FindFirstChild("PhoenixLaunchLeftWing")
			if leftWing then
				leftWing:Destroy()
			end
			
			local rightWing = hrp:FindFirstChild("PhoenixLaunchRightWing")
			if rightWing then
				rightWing:Destroy()
			end
		end
	end
end

return Ability
