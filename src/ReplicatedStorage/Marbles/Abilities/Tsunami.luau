-- Tsunami marble ability: spawns a massive wave that rises from below and launches the player up with ocean effects
local Ability = {}

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Constants
local WAVE_LAUNCH_FORCE = 150 -- Upward force applied during wave launch
local WAVE_DURATION = 0.6 -- How long the wave force lasts
local ABILITY_COOLDOWN = 10 -- Cooldown between uses
local WAVE_LIFETIME = 6 -- Wave disappears after 6 seconds
local WAVE_HEIGHT = 60 -- Height of the wave (3x larger)
local WAVE_WIDTH = 75 -- Width of the wave (3x larger)
local WAVE_DEPTH = 45 -- Depth/thickness of the wave (3x larger)
local SPARKLE_COUNT = 150 -- Number of sparkle particles (3x more)
local FOAM_PARTICLES_COUNT = 90 -- Number of foam/water droplets (3x more)

function Ability.Description()
	return "Tsunami: Summon a massive wave from below that launches you skyward with ocean sparkles."
end

function Ability.Cooldown()
	return ABILITY_COOLDOWN
end

-- Helper function to create sparkle particles
local function createSparkle(position: Vector3)
	local sparkle = Instance.new("Part")
	sparkle.Name = "TsunamiSparkle"
	sparkle.Size = Vector3.new(0.2, 0.2, 0.2)
	sparkle.Shape = Enum.PartType.Ball
	sparkle.Material = Enum.Material.Neon
	sparkle.CanCollide = false
	sparkle.Anchored = true
	sparkle.Transparency = 0
	
	-- Ocean sparkle colors (cyan, blue, white, teal)
	local sparkleColors = {
		Color3.fromRGB(0, 255, 255),    -- Cyan
		Color3.fromRGB(100, 200, 255),  -- Light blue
		Color3.fromRGB(255, 255, 255),  -- White
		Color3.fromRGB(0, 200, 200),    -- Teal
		Color3.fromRGB(173, 216, 230),  -- Light blue
	}
	sparkle.Color = sparkleColors[math.random(1, #sparkleColors)]
	
	-- Random position around the wave
	local angle = math.random() * math.pi * 2
	local radius = math.random(5, 15)
	local height = math.random(0, WAVE_HEIGHT)
	sparkle.Position = position + Vector3.new(
		math.cos(angle) * radius,
		height,
		math.sin(angle) * radius
	)
	
	sparkle.Parent = workspace
	
	-- Add glow
	local pointLight = Instance.new("PointLight")
	pointLight.Color = sparkle.Color
	pointLight.Brightness = 3
	pointLight.Range = 5
	pointLight.Parent = sparkle
	
	-- Animate sparkle (twinkle effect)
	local tween = TweenService:Create(sparkle, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true, 0), {
		Transparency = 0.5,
		Size = Vector3.new(0.3, 0.3, 0.3)
	})
	tween:Play()
	
	-- Cleanup after a few seconds
	task.delay(3, function()
		if sparkle and sparkle.Parent then
			local fadeTween = TweenService:Create(sparkle, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1
			})
			fadeTween:Play()
			fadeTween.Completed:Wait()
			sparkle:Destroy()
		end
	end)
end

-- Helper function to create foam/water droplets
local function createFoamDroplet(waveTop: Vector3)
	local droplet = Instance.new("Part")
	droplet.Name = "FoamDroplet"
	droplet.Size = Vector3.new(
		math.random(5, 15) / 10,
		math.random(5, 15) / 10,
		math.random(5, 15) / 10
	)
	droplet.Shape = Enum.PartType.Ball
	droplet.Material = Enum.Material.ForceField
	droplet.CanCollide = true
	droplet.Anchored = false
	
	-- Water/foam colors (white, light blue, cyan)
	local waterColors = {
		Color3.fromRGB(255, 255, 255),  -- White foam
		Color3.fromRGB(200, 230, 255),  -- Light blue
		Color3.fromRGB(173, 216, 230),  -- Light blue
		Color3.fromRGB(135, 206, 250),  -- Sky blue
	}
	droplet.Color = waterColors[math.random(1, #waterColors)]
	droplet.Transparency = 0.3
	
	-- Random offset from wave top
	local angle = math.random() * math.pi * 2
	local spreadRadius = math.random() * 4
	droplet.Position = waveTop + Vector3.new(
		math.cos(angle) * spreadRadius,
		math.random(2, 8),
		math.sin(angle) * spreadRadius
	)
	
	droplet.Parent = workspace
	
	-- Apply random velocity to spread the droplets
	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(10000, 10000, 10000)
	velocity.Velocity = Vector3.new(
		math.random(-20, 20),
		math.random(20, 40),
		math.random(-20, 20)
	)
	velocity.Parent = droplet
	
	-- Remove velocity after a short time
	task.delay(0.3, function()
		if velocity and velocity.Parent then
			velocity:Destroy()
		end
	end)
	
	-- Cleanup after a few seconds
	task.delay(5, function()
		if droplet and droplet.Parent then
			local tween = TweenService:Create(droplet, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1
			})
			tween:Play()
			tween.Completed:Wait()
			droplet:Destroy()
		end
	end)
end

-- Helper function to create a kelp (seaweed) plant
local function createKelp(basePosition: Vector3, height: number, swayOffset: number): Model
	local kelp = Instance.new("Model")
	kelp.Name = "Kelp"
	
	-- Create kelp segments that sway
	local segments = math.max(3, math.floor(height / 1.5))
	for i = 1, segments do
		local segment = Instance.new("Part")
		segment.Name = "KelpSegment" .. i
		segment.Anchored = true
		segment.CanCollide = false
		segment.Material = Enum.Material.Neon
		segment.Color = Color3.fromRGB(34, 139, 34) -- Seaweed green
		segment.Transparency = 0.05 -- Less translucent kelp
		
		local progress = (i - 1) / (segments - 1)
		local segmentHeight = height / segments
		local segmentWidth = 0.3 * (1 - progress * 0.5) -- Taper towards top
		
		-- Sway effect using sine wave
		local swayAmount = math.sin(swayOffset + progress * math.pi * 2) * 0.8
		
		segment.Size = Vector3.new(segmentWidth, segmentHeight, segmentWidth)
		segment.CFrame = CFrame.new(
			basePosition.X + swayAmount,
			basePosition.Y + (i - 0.5) * segmentHeight,
			basePosition.Z
		) * CFrame.Angles(0, 0, math.rad(swayAmount * 15))
		
		segment.Parent = kelp
	end
	
	return kelp
end

-- Helper function to create a rock
local function createRock(position: Vector3, size: number): Part
	local rock = Instance.new("Part")
	rock.Name = "Rock"
	rock.Shape = Enum.PartType.Block
	rock.Anchored = true
	rock.CanCollide = true
	rock.Material = Enum.Material.Rock
	rock.Color = Color3.fromRGB(80, 80, 90) -- Dark gray rock
	rock.Transparency = 0 -- Fully opaque
	
	-- Randomize size slightly
	local actualSize = size * (0.7 + math.random() * 0.6)
	rock.Size = Vector3.new(actualSize, actualSize * 0.6, actualSize)
	
	-- Random rotation
	rock.CFrame = CFrame.new(position) * CFrame.Angles(
		math.rad(math.random(-15, 15)),
		math.rad(math.random(0, 360)),
		math.rad(math.random(-15, 15))
	)
	
	return rock
end

-- Helper function to create the wave model
local function createWave(position: Vector3): Model
	local wave = Instance.new("Model")
	wave.Name = "TsunamiWave"
	
	-- Create the main wave body using a curved wave shape
	-- Use multiple segments to create a smooth, organic wave curve
	local waveSegments = 12
	local waveBaseY = position.Y
	
	for i = 1, waveSegments do
		local segment = Instance.new("Part")
		segment.Name = "WaveSegment" .. i
		segment.Anchored = true
		segment.CanCollide = false
		segment.Material = Enum.Material.ForceField
		
		-- Calculate position along wave curve
		local progress = (i - 1) / (waveSegments - 1)
		
		-- Create a smooth wave curve using sine function
		-- Wave starts flat at bottom, curves forward and up
		local waveCurve = math.sin(progress * math.pi) -- 0 to 1 to 0
		local forwardOffset = waveCurve * 24 -- Wave curves forward (3x larger)
		local heightOffset = progress * WAVE_HEIGHT -- Wave rises
		
		-- Wave width varies - wider in middle, narrower at edges
		local widthVariation = math.sin(progress * math.pi) * 0.3 + 0.7
		local segmentWidth = WAVE_WIDTH * widthVariation
		
		-- Wave depth - thicker at base, thinner at top
		local segmentDepth = WAVE_DEPTH * (1 - progress * 0.5)
		local segmentHeight = WAVE_HEIGHT / waveSegments * 1.2
		
		segment.Size = Vector3.new(segmentDepth, segmentHeight, segmentWidth)
		
		-- Position and rotate to create wave shape
		local segmentPosition = Vector3.new(
			position.X + forwardOffset,
			waveBaseY + heightOffset,
			position.Z
		)
		
		-- Rotate segments to create curved wave effect
		local rotationAngle = math.deg(math.atan(forwardOffset / (heightOffset + 0.1))) * 0.3
		segment.CFrame = CFrame.new(segmentPosition) * CFrame.Angles(
			math.rad(rotationAngle),
			0,
			math.rad(-10 * waveCurve) -- Slight tilt forward
		)
		
		-- Ocean color gradient from deep blue at base to cyan/white at top
		local colorProgress = progress
		segment.Color = Color3.fromRGB(
			30 + colorProgress * 120,   -- R: 30 to 150
			100 + colorProgress * 155,  -- G: 100 to 255
			200 + colorProgress * 55    -- B: 200 to 255
		)
		segment.Transparency = 0.05 + progress * 0.15 -- Less translucent (more opaque)
		
		segment.Parent = wave
	end
	
	-- Create kelp at the bottom
	local kelpCount = 8
	for i = 1, kelpCount do
		local angle = (i / kelpCount) * math.pi * 2
		local radius = math.random(9, 24) -- 3x larger radius
		local kelpX = position.X - 12 + math.cos(angle) * radius -- 3x larger offset
		local kelpZ = position.Z + math.sin(angle) * radius
		local kelpBase = Vector3.new(kelpX, waveBaseY - 1.5, kelpZ) -- 3x larger offset
		
		local kelpHeight = math.random(9, 18) -- 3x larger kelp
		local kelp = createKelp(kelpBase, kelpHeight, angle * 2)
		kelp.Parent = wave
		
		-- Animate kelp swaying
		task.spawn(function()
			local startTime = tick()
			local segmentHeights = {}
			local maxHeight = 0
			-- Store original heights
			for _, segment in ipairs(kelp:GetChildren()) do
				if segment:IsA("BasePart") then
					local relativeHeight = segment.Position.Y - kelpBase.Y
					segmentHeights[segment] = relativeHeight
					maxHeight = math.max(maxHeight, relativeHeight)
				end
			end
			
			while kelp and kelp.Parent do
				local elapsed = tick() - startTime
				local baseSway = math.sin(elapsed * 2 + angle * 2) * 0.8
				
				for segment, relativeHeight in pairs(segmentHeights) do
					if segment and segment.Parent then
						-- Each segment sways more at the top
						local segmentProgress = maxHeight > 0 and (relativeHeight / maxHeight) or 0
						local segmentSway = baseSway * (0.3 + segmentProgress * 0.7)
						local swayAngle = math.rad(segmentSway * 20 * segmentProgress)
						
						segment.CFrame = CFrame.new(
							kelpX + segmentSway,
							kelpBase.Y + relativeHeight,
							kelpZ
						) * CFrame.Angles(0, 0, swayAngle)
					end
				end
				task.wait(0.05)
			end
		end)
	end
	
	-- Create rocks at the bottom
	local rockCount = 8 -- More rocks for better visibility
	for i = 1, rockCount do
		local angle = (i / rockCount) * math.pi * 2 + math.pi / 4
		local radius = math.random(8, 20) -- Slightly larger radius for better spread
		local rockX = position.X - 10 + math.cos(angle) * radius
		local rockZ = position.Z + math.sin(angle) * radius
		local rockY = waveBaseY - 2 -- Position rocks lower so they're more visible
		
		local rock = createRock(Vector3.new(rockX, rockY, rockZ), math.random(4, 8)) -- Larger, more visible rocks
		rock.Transparency = 0 -- Ensure fully opaque
		rock.Parent = wave
	end
	
	-- Add ocean glow to the top wave segment
	local topSegment = wave:FindFirstChild("WaveSegment" .. waveSegments)
	if topSegment then
		local oceanGlow = Instance.new("PointLight")
		oceanGlow.Color = Color3.fromRGB(100, 200, 255)
		oceanGlow.Brightness = 2
		oceanGlow.Range = 30
		oceanGlow.Parent = topSegment
		
		-- Add water particles at the wave front
		local waterAttachment = Instance.new("Attachment")
		waterAttachment.Position = Vector3.new(0, 0, 0)
		waterAttachment.Parent = topSegment
		
		local waterParticles = Instance.new("ParticleEmitter")
		waterParticles.Name = "WaveWaterParticles"
		waterParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
		waterParticles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 230, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255))
		})
		waterParticles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 2),
			NumberSequenceKeypoint.new(0.5, 4),
			NumberSequenceKeypoint.new(1, 1)
		})
		waterParticles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.7, 0.6),
			NumberSequenceKeypoint.new(1, 1)
		})
		waterParticles.Rate = 100
		waterParticles.Lifetime = NumberRange.new(1, 2)
		waterParticles.Speed = NumberRange.new(20, 40)
		waterParticles.SpreadAngle = Vector2.new(30, 30)
		waterParticles.Acceleration = Vector3.new(0, -5, 0)
		waterParticles.Parent = waterAttachment
		
		-- Add sparkle particles throughout the wave
		local sparkleAttachment = Instance.new("Attachment")
		sparkleAttachment.Position = Vector3.new(0, -WAVE_HEIGHT/2, 0)
		sparkleAttachment.Parent = topSegment
		
		local sparkleParticles = Instance.new("ParticleEmitter")
		sparkleParticles.Name = "WaveSparkleParticles"
		sparkleParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkleParticles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(173, 216, 230)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(100, 200, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255))
		})
		sparkleParticles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 1.5),
			NumberSequenceKeypoint.new(1, 0.3)
		})
		sparkleParticles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.8, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		})
		sparkleParticles.Rate = 150
		sparkleParticles.Lifetime = NumberRange.new(1, 2.5)
		sparkleParticles.Speed = NumberRange.new(5, 15)
		sparkleParticles.SpreadAngle = Vector2.new(180, 180)
		sparkleParticles.Parent = sparkleAttachment
	end
	
	wave.Parent = workspace
	
	return wave
end

-- Helper function to create wave surge visual effects
local function createWaveSurgeEffect(wavePosition: Vector3)
	-- Create a burst of water particles
	local surgePart = Instance.new("Part")
	surgePart.Name = "WaveSurge"
	surgePart.Anchored = true
	surgePart.CanCollide = false
	surgePart.Transparency = 1
	surgePart.Size = Vector3.new(1, 1, 1)
	surgePart.Position = wavePosition + Vector3.new(0, WAVE_HEIGHT/2, 0)
	surgePart.Parent = workspace
	
	local surgeAttachment = Instance.new("Attachment")
	surgeAttachment.Parent = surgePart
	
	-- Intense water burst
	local surgeParticles = Instance.new("ParticleEmitter")
	surgeParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	surgeParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(200, 230, 255)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(100, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 255))
	})
	surgeParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 4),
		NumberSequenceKeypoint.new(0.5, 8),
		NumberSequenceKeypoint.new(1, 2)
	})
	surgeParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	surgeParticles.Rate = 600
	surgeParticles.Lifetime = NumberRange.new(0.8, 1.5)
	surgeParticles.Speed = NumberRange.new(60, 100)
	surgeParticles.SpreadAngle = Vector2.new(40, 40)
	surgeParticles.Parent = surgeAttachment
	
	-- Bright ocean glow flash
	local flash = Instance.new("PointLight")
	flash.Color = Color3.fromRGB(100, 200, 255)
	flash.Brightness = 8
	flash.Range = 50
	flash.Parent = surgePart
	
	-- Fade out the flash
	task.spawn(function()
		for i = 1, 15 do
			task.wait(0.05)
			flash.Brightness = 8 - (i * 0.5)
		end
	end)
	
	-- Stop surge after a short time
	task.delay(0.8, function()
		if surgeParticles and surgeParticles.Parent then
			surgeParticles.Enabled = false
		end
	end)
	
	-- Cleanup
	task.delay(2.5, function()
		if surgePart and surgePart.Parent then
			surgePart:Destroy()
		end
	end)
	
	-- Spawn foam droplets
	for i = 1, FOAM_PARTICLES_COUNT do
		task.delay(i * 0.03, function()
			createFoamDroplet(wavePosition + Vector3.new(0, WAVE_HEIGHT, 0))
		end)
	end
	
	-- Spawn sparkles around the wave
	for i = 1, SPARKLE_COUNT do
		task.delay(i * 0.05, function()
			createSparkle(wavePosition)
		end)
	end
end

-- Helper function to apply wave launch force to player
local function applyWaveLaunchForce(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Create BodyVelocity for the wave launch
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "TsunamiWaveForce"
	bodyVelocity.MaxForce = Vector3.new(0, WAVE_LAUNCH_FORCE * 2000, 0)
	bodyVelocity.Velocity = Vector3.new(0, WAVE_LAUNCH_FORCE, 0)
	bodyVelocity.Parent = humanoidRootPart
	
	-- Add water particles to the player during launch
	local playerWaterAttachment = Instance.new("Attachment")
	playerWaterAttachment.Name = "TsunamiWaterAttachment"
	playerWaterAttachment.Parent = humanoidRootPart
	
	local playerWater = Instance.new("ParticleEmitter")
	playerWater.Name = "TsunamiWaterParticles"
	playerWater.Texture = "rbxasset://textures/particles/smoke_main.dds"
	playerWater.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 230, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255))
	})
	playerWater.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	playerWater.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	playerWater.Rate = 120
	playerWater.Lifetime = NumberRange.new(0.4, 0.8)
	playerWater.Speed = NumberRange.new(8, 15)
	playerWater.SpreadAngle = Vector2.new(180, 180)
	playerWater.Parent = playerWaterAttachment
	
	-- Add sparkle particles to player
	local playerSparkleAttachment = Instance.new("Attachment")
	playerSparkleAttachment.Name = "TsunamiSparkleAttachment"
	playerSparkleAttachment.Parent = humanoidRootPart
	
	local playerSparkles = Instance.new("ParticleEmitter")
	playerSparkles.Name = "TsunamiSparkleParticles"
	playerSparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	playerSparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(173, 216, 230)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255))
	})
	playerSparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 1.5),
		NumberSequenceKeypoint.new(1, 0.3)
	})
	playerSparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	playerSparkles.Rate = 80
	playerSparkles.Lifetime = NumberRange.new(0.5, 1)
	playerSparkles.Speed = NumberRange.new(3, 8)
	playerSparkles.SpreadAngle = Vector2.new(180, 180)
	playerSparkles.Parent = playerSparkleAttachment
	
	-- Gradually reduce the force
	local startTime = tick()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not bodyVelocity or not bodyVelocity.Parent then
			connection:Disconnect()
			return
		end
		
		local elapsed = tick() - startTime
		if elapsed > WAVE_DURATION then
			connection:Disconnect()
			bodyVelocity:Destroy()
			return
		end
		
		-- Ease out the force
		local progress = elapsed / WAVE_DURATION
		local easedForce = WAVE_LAUNCH_FORCE * (1 - progress * progress)
		bodyVelocity.Velocity = Vector3.new(0, easedForce, 0)
	end)
	
	-- Cleanup particles after launch
	task.delay(WAVE_DURATION + 0.5, function()
		if playerWater and playerWater.Parent then
			playerWater.Enabled = false
		end
		if playerSparkles and playerSparkles.Parent then
			playerSparkles.Enabled = false
		end
		task.delay(1, function()
			if playerWaterAttachment and playerWaterAttachment.Parent then
				playerWaterAttachment:Destroy()
			end
			if playerSparkleAttachment and playerSparkleAttachment.Parent then
				playerSparkleAttachment:Destroy()
			end
		end)
	end)
	
	-- Safety cleanup for bodyVelocity
	task.delay(WAVE_DURATION + 0.1, function()
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
	end)
end

-- Helper function to animate wave rising
local function animateWaveRising(wave: Model, startPosition: Vector3, targetHeight: number)
	-- Animate the wave rising from below
	for _, part in ipairs(wave:GetDescendants()) do
		if part:IsA("BasePart") and part.Name:match("WaveSegment") then
			local segmentNum = tonumber(part.Name:match("%d+")) or 1
			local progress = (segmentNum - 1) / 11
			
			-- Calculate wave curve for this segment
			local waveCurve = math.sin(progress * math.pi)
			local forwardOffset = waveCurve * 24 -- 3x larger
			local heightOffset = progress * WAVE_HEIGHT
			
			-- Start position (below ground)
			local startY = startPosition.Y - WAVE_HEIGHT
			local startPos = Vector3.new(
				startPosition.X + forwardOffset * 0.3, -- Start with less curve
				startY,
				part.Position.Z
			)
			
			-- Target position (final wave position)
			local targetY = startPosition.Y + heightOffset
			local targetPos = Vector3.new(
				startPosition.X + forwardOffset,
				targetY,
				part.Position.Z
			)
			
			-- Store original CFrame rotation
			local originalCFrame = part.CFrame
			local targetRotation = originalCFrame - originalCFrame.Position
			
			-- Set initial position and make transparent
			part.CFrame = CFrame.new(startPos) * (originalCFrame - originalCFrame.Position)
			part.Transparency = 1
			
			-- Tween the wave segment rising with curve
			local riseTween = TweenService:Create(
				part,
				TweenInfo.new(0.6 + progress * 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = targetPos
				}
			)
			riseTween:Play()
			
			-- Fade in
			local fadeTween = TweenService:Create(
				part,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Transparency = 0.05 + progress * 0.15
				}
			)
			fadeTween:Play()
		elseif part:IsA("BasePart") and (part.Name:match("Kelp") or part.Name == "Rock") then
			-- Keep kelp and rocks at their positions, just fade them in
			part.Transparency = 1
			local fadeTween = TweenService:Create(
				part,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Transparency = part.Name == "Rock" and 0 or 0.05
				}
			)
			fadeTween:Play()
		end
	end
end

-- Helper function to destroy wave with fade effect
local function destroyWaveWithEffect(wave: Model)
	-- Disable new particles first
	for _, descendant in wave:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = false
		end
	end
	
	-- Fade out all parts
	for _, descendant in wave:GetDescendants() do
		if descendant:IsA("BasePart") then
			local tween = TweenService:Create(
				descendant,
				TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Transparency = 1 }
			)
			tween:Play()
		end
		if descendant:IsA("PointLight") then
			local tween = TweenService:Create(
				descendant,
				TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Brightness = 0 }
			)
			tween:Play()
		end
	end
	
	-- Destroy after fade completes
	task.delay(2, function()
		if wave and wave.Parent then
			wave:Destroy()
		end
	end)
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("TSUNAMI ABILITY: Activating for player:", player.Name)
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("TSUNAMI ABILITY: No character or HumanoidRootPart found, aborting")
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Check if tsunami is already active
	local prev = character:GetAttribute("TsunamiActive")
	if typeof(prev) == "boolean" and prev then
		print("TSUNAMI ABILITY: Already active")
		return
	end
	
	-- Set tsunami attribute to true
	character:SetAttribute("TsunamiActive", true)
	
	print("TSUNAMI ABILITY: Creating wave and launching player")
	
	-- Get position for wave (below the player)
	local wavePosition = Vector3.new(
		humanoidRootPart.Position.X,
		humanoidRootPart.Position.Y - 5,
		humanoidRootPart.Position.Z
	)
	
	-- Create the wave
	local wave = createWave(wavePosition)
	
	-- Animate wave rising
	animateWaveRising(wave, wavePosition, WAVE_HEIGHT)
	
	-- Small delay before surge and launch
	task.delay(0.4, function()
		if not character or not character.Parent then return end
		
		-- Get the top of wave position
		local waveTop = Vector3.new(
			wavePosition.X,
			wavePosition.Y + WAVE_HEIGHT,
			wavePosition.Z
		)
		
		-- Create surge effects
		createWaveSurgeEffect(waveTop)
		
		-- Apply wave launch force to player
		applyWaveLaunchForce(character)
	end)
	
	-- Schedule wave destruction after WAVE_LIFETIME seconds
	task.delay(WAVE_LIFETIME, function()
		print("TSUNAMI ABILITY: Destroying wave after", WAVE_LIFETIME, "seconds")
		destroyWaveWithEffect(wave)
	end)
	
	-- Reset attribute after effect ends
	task.delay(WAVE_DURATION + 1, function()
		if character then
			character:SetAttribute("TsunamiActive", false)
			print("TSUNAMI ABILITY: Wave launch ended")
		end
	end)
	
	print("TSUNAMI ABILITY: Activation complete")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("TSUNAMI ABILITY: Deactivating for player:", player.Name)
	
	if character then
		character:SetAttribute("TsunamiActive", false)
		
		-- Clean up any remaining wave force
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local waveForce = hrp:FindFirstChild("TsunamiWaveForce")
			if waveForce then
				waveForce:Destroy()
			end
			
			local waterAttachment = hrp:FindFirstChild("TsunamiWaterAttachment")
			if waterAttachment then
				waterAttachment:Destroy()
			end
			
			local sparkleAttachment = hrp:FindFirstChild("TsunamiSparkleAttachment")
			if sparkleAttachment then
				sparkleAttachment:Destroy()
			end
		end
	end
end

return Ability
