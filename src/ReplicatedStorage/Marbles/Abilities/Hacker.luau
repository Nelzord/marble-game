-- Hacker marble ability: zigzags up in a spiral with 0s and 1s
local Ability = {}

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Constants
local SPIRAL_HEIGHT = 50 -- Total height to spiral up
local SPIRAL_DURATION = 3.0 -- How long the spiral movement lasts (faster)
local SPIRAL_RADIUS = 8 -- Radius of the spiral
local SPIRAL_ROTATIONS = 3 -- Number of full rotations
local ABILITY_COOLDOWN = 10 -- Cooldown between uses
local BINARY_PARTICLE_COUNT = 50 -- Number of 0s and 1s to spawn
local ZIGZAG_AMPLITUDE = 50 -- How far side to side the zigzag goes (much larger)

function Ability.Description()
	return "Hacker: Zigzag up in a spiral pattern with binary code (0s and 1s) trailing behind."
end

function Ability.Cooldown()
	return ABILITY_COOLDOWN
end

-- Helper function to create a binary particle (0 or 1)
local function createBinaryParticle(position: Vector3, value: string)
	local particle = Instance.new("Part")
	particle.Name = "BinaryParticle"
	particle.Size = Vector3.new(0.5, 0.5, 0.1)
	particle.Shape = Enum.PartType.Block
	particle.Material = Enum.Material.Neon
	particle.CanCollide = false
	particle.Anchored = true
	particle.Transparency = 0.2
	
	-- Green for 1, black/dark green for 0
	if value == "1" then
		particle.Color = Color3.fromRGB(0, 255, 0) -- Bright green
	else
		particle.Color = Color3.fromRGB(0, 100, 0) -- Dark green/black
	end
	
	particle.Position = position
	particle.Parent = workspace
	
	-- Create text label for the binary digit
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = particle
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = value
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.Code
	textLabel.Parent = surfaceGui
	
	-- Add glow
	local pointLight = Instance.new("PointLight")
	pointLight.Color = value == "1" and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 50, 0)
	pointLight.Brightness = value == "1" and 2 or 0.5
	pointLight.Range = 5
	pointLight.Parent = particle
	
	-- Fade out and destroy
	local tween = TweenService:Create(particle, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = Vector3.new(0.2, 0.2, 0.1)
	})
	tween:Play()
	
	if pointLight then
		local lightTween = TweenService:Create(pointLight, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Brightness = 0
		})
		lightTween:Play()
	end
	
	tween.Completed:Connect(function()
		particle:Destroy()
	end)
end

-- Helper function to apply zigzag spiral movement
local function applyZigzagSpiral(character: Model)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	local startPosition = humanoidRootPart.Position
	local startTime = tick()
	
	-- Create BodyVelocity for movement control with high force
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "HackerSpiralForce"
	bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000) -- Much higher force
	bodyVelocity.Parent = humanoidRootPart
	
	-- Track spiral progress
	local connection
	local lastParticleTime = 0
	connection = RunService.Heartbeat:Connect(function()
		if not bodyVelocity or not bodyVelocity.Parent or not humanoidRootPart or not humanoidRootPart.Parent then
			if connection then
				connection:Disconnect()
			end
			return
		end
		
		local elapsed = tick() - startTime
		if elapsed > SPIRAL_DURATION then
			connection:Disconnect()
			bodyVelocity:Destroy()
			return
		end
		
		local progress = elapsed / SPIRAL_DURATION
		
		-- Calculate spiral position
		-- Height increases linearly with upward force
		local targetHeight = startPosition.Y + (SPIRAL_HEIGHT * progress)
		
		-- Spiral in XZ plane with zigzag pattern
		local angle = progress * SPIRAL_ROTATIONS * math.pi * 2
		local radius = SPIRAL_RADIUS * (1 - progress * 0.2) -- Radius decreases slightly as we go up
		
		-- Add rapid zigzag pattern with hard angles (more frequent and sharper)
		-- Use a higher frequency multiplier for more rapid zigzagging and harder to control
		local zigzagFrequency = progress * SPIRAL_ROTATIONS * 5 -- Increased for more rapid, unpredictable changes
		-- Add multiple sine waves with different frequencies for harder to control movement
		local zigzagOffsetX = (math.sin(zigzagFrequency) + math.sin(zigzagFrequency * 2.3) * 0.5) * ZIGZAG_AMPLITUDE -- Large, unpredictable side-to-side movement
		local zigzagOffsetZ = (math.cos(zigzagFrequency * 1.3) + math.cos(zigzagFrequency * 3.1) * 0.5) * ZIGZAG_AMPLITUDE -- Offset phase for diagonal zigzag pattern
		
		-- Apply zigzag to both X and Z for harder angles
		local targetX = startPosition.X + math.cos(angle) * radius + zigzagOffsetX
		local targetZ = startPosition.Z + math.sin(angle) * radius + zigzagOffsetZ
		
		-- Calculate current position
		local currentPosition = humanoidRootPart.Position
		
		-- Calculate direction to target
		local directionX = targetX - currentPosition.X
		local directionZ = targetZ - currentPosition.Z
		local directionY = targetHeight - currentPosition.Y
		
		-- Calculate velocities with strong forces - much faster
		-- Increased horizontal speed significantly to move farther side to side and faster
		local horizontalSpeed = 120 -- Increased from 80 to 120 for faster, larger side-to-side movement
		local verticalSpeed = SPIRAL_HEIGHT / SPIRAL_DURATION -- Speed for vertical movement (faster due to shorter duration)
		
		-- Normalize horizontal direction
		local horizontalDistance = math.sqrt(directionX * directionX + directionZ * directionZ)
		local velocityX = 0
		local velocityZ = 0
		if horizontalDistance > 0.1 then
			velocityX = (directionX / horizontalDistance) * horizontalSpeed
			velocityZ = (directionZ / horizontalDistance) * horizontalSpeed
		end
		
		-- Apply vertical velocity (always upward during spiral)
		local velocityY = verticalSpeed
		
		-- Apply the velocity
		bodyVelocity.Velocity = Vector3.new(velocityX, velocityY, velocityZ)
		
		-- Spawn binary particles along the path (less frequently)
		local currentTime = tick()
		if currentTime - lastParticleTime > 0.1 then -- Every 0.1 seconds
			lastParticleTime = currentTime
			local binaryValue = math.random() < 0.5 and "0" or "1"
			createBinaryParticle(currentPosition + Vector3.new(
				math.random(-2, 2),
				math.random(-1, 1),
				math.random(-2, 2)
			), binaryValue)
		end
	end)
	
	-- Safety cleanup
	task.delay(SPIRAL_DURATION + 0.5, function()
		if connection then
			connection:Disconnect()
		end
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
	end)
end

function Ability.ActivateAbility(player: Player, character: Model)
	print("HACKER ABILITY: Activating for player:", player.Name)
	
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("HACKER ABILITY: No character or HumanoidRootPart found, aborting")
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Check if Hacker ability is already active
	local prev = character:GetAttribute("HackerActive")
	if typeof(prev) == "boolean" and prev then
		print("HACKER ABILITY: Already active")
		return
	end
	
	-- Set Hacker attribute to true
	character:SetAttribute("HackerActive", true)
	
	print("HACKER ABILITY: Starting zigzag spiral movement with binary particles")
	
	-- Apply zigzag spiral movement
	applyZigzagSpiral(character)
	
	-- Create green 0s and 1s particle emitter attachment
	local binaryEmitterAttachment = Instance.new("Attachment")
	binaryEmitterAttachment.Name = "HackerBinaryEmitter"
	binaryEmitterAttachment.Parent = humanoidRootPart
	
	local binaryEmitter = Instance.new("ParticleEmitter")
	binaryEmitter.Name = "HackerBinaryEmitter"
	binaryEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	binaryEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)), -- Bright green
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 200, 0)), -- Medium green
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 0)) -- Dark green
	})
	binaryEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0.3)
	})
	binaryEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	binaryEmitter.Rate = 150 -- High rate for lots of particles
	binaryEmitter.Lifetime = NumberRange.new(0.8, 1.5)
	binaryEmitter.Speed = NumberRange.new(8, 15) -- Fast particles
	binaryEmitter.SpreadAngle = Vector2.new(360, 360)
	binaryEmitter.LightEmission = 1
	binaryEmitter.Parent = binaryEmitterAttachment
	
	-- Spawn initial burst of binary particles
	for i = 1, BINARY_PARTICLE_COUNT do
		task.delay(i * 0.03, function()
			if not character or not character.Parent then return end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local binaryValue = math.random() < 0.5 and "0" or "1"
				createBinaryParticle(hrp.Position + Vector3.new(
					math.random(-3, 3),
					math.random(-2, 2),
					math.random(-3, 3)
				), binaryValue)
			end
		end)
	end
	
	-- Cleanup particle emitter after duration
	task.delay(SPIRAL_DURATION + 0.5, function()
		if binaryEmitter and binaryEmitter.Parent then
			binaryEmitter.Enabled = false
		end
		task.delay(2, function()
			if binaryEmitterAttachment and binaryEmitterAttachment.Parent then
				binaryEmitterAttachment:Destroy()
			end
		end)
	end)
	
	-- Reset attribute after spiral completes
	task.delay(SPIRAL_DURATION + 1, function()
		if character then
			character:SetAttribute("HackerActive", false)
			print("HACKER ABILITY: Spiral movement completed")
		end
	end)
	
	print("HACKER ABILITY: Activation complete")
end

function Ability.DeactivateAbility(player: Player, character: Model)
	print("HACKER ABILITY: Deactivating for player:", player.Name)
	
	if character then
		character:SetAttribute("HackerActive", false)
		
		-- Clean up any remaining effects
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local spiralForce = hrp:FindFirstChild("HackerSpiralForce")
			if spiralForce then
				spiralForce:Destroy()
			end
			
			local binaryEmitter = hrp:FindFirstChild("HackerBinaryEmitter")
			if binaryEmitter then
				binaryEmitter:Destroy()
			end
		end
	end
end

return Ability
