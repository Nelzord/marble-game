-- Marble rolling controller (client-side)
-- Default Roblox camera; visual marble rotates around player while physics uses linear velocity

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local Marbles = require(ReplicatedStorage:WaitForChild("Marbles"):WaitForChild("MarblesModule"))

local DEBUG = false
local function dprint(...)
	if DEBUG then
		print("[MarbleClient]", ...)
	end
end

local MOVEMENT_DEBUG = false
local function mprint(...)
	if MOVEMENT_DEBUG then
		print("[MarbleMove]", ...)
	end
end

local inputState = {
	forward = 0,
	right = 0,
}

local boundCharacters: { [Model]: boolean } = {}

local baseSpeed = 35 -- movement magnitude; abilities can scale via SpeedMultiplier

-- Mobile/gamepad controls via PlayerModule
local controlModule = nil

local function initMobileControls()
	local playerScripts = player:WaitForChild("PlayerScripts", 5)
	if playerScripts then
		local pm = playerScripts:WaitForChild("PlayerModule", 5)
		if pm then
			local success, result = pcall(function()
				return require(pm)
			end)
			if success and result then
				local ctrl = result:GetControls()
				if ctrl then
					controlModule = ctrl
					dprint("Mobile controls initialized successfully")
				end
			end
		end
	end
end

task.spawn(initMobileControls)

local function getMoveDirection(camera: Camera): Vector3
	local cf = camera.CFrame
	local forward = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	if forward.Magnitude > 0 then forward = forward.Unit end
	local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
	if right.Magnitude > 0 then right = right.Unit end
	
	-- Start with keyboard input
	local inputForward = inputState.forward
	local inputRight = inputState.right
	
	-- Get mobile joystick/gamepad input if available
	if controlModule then
		local success, moveVector = pcall(function()
			return controlModule:GetMoveVector()
		end)
		if success and moveVector then
			-- moveVector: X = right/left, Z = forward/back (inverted)
			if math.abs(moveVector.X) > 0.01 or math.abs(moveVector.Z) > 0.01 then
				-- Only use mobile input if no keyboard input (prevents double-speed)
				if inputForward == 0 and inputRight == 0 then
					inputRight = moveVector.X
					inputForward = -moveVector.Z -- Z is inverted in Roblox control system
				end
			end
		end
	end
	
	local dir = forward * inputForward + right * inputRight
	if dir.Magnitude > 1 then dir = dir.Unit end
	return dir
end

local function bindInputs()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then inputState.forward = 1 end
		if input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then inputState.forward = -1 end
		if input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then inputState.right = 1 end
		if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then inputState.right = -1 end
	end)
	UserInputService.InputEnded:Connect(function(input, _processed)
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then if inputState.forward == 1 then inputState.forward = 0 end end
		if input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then if inputState.forward == -1 then inputState.forward = 0 end end
		if input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then if inputState.right == 1 then inputState.right = 0 end end
		if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then if inputState.right == -1 then inputState.right = 0 end end
	end)
end

local function waitForHRP(character: Model, timeoutSeconds: number?): BasePart?
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end
	local ok = character:WaitForChild("HumanoidRootPart", timeoutSeconds or 5)
	if ok and ok:IsA("BasePart") then
		return ok
	end
	return nil
end

local function ensureCosmeticBall(character: Model, hrp: BasePart): BasePart
	local existing = character:FindFirstChild("CosmeticBall")
	if existing and existing:IsA("BasePart") then
		-- Ensure it's still properly configured
		existing.Transparency = 0
		existing.CanCollide = false
		existing.Massless = true
		existing.Anchored = false
		return existing
	end
	local ball = Instance.new("Part")
	ball.Name = "CosmeticBall"
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.SmoothPlastic
	ball.Color = Color3.fromRGB(230, 230, 230)
	ball.Size = hrp.Size
	ball.Transparency = 0 -- Explicitly set to visible
	ball.CanCollide = false
	ball.Massless = true
	ball.Anchored = false
	ball.Parent = character
	
	return ball
end

local function createRedGlowTrail(character: Model, hrp: BasePart)
	-- Remove existing trail if it exists
	local existingTrail = character:FindFirstChild("RedGlowTrail")
	if existingTrail then
		existingTrail:Destroy()
	end
	
	-- Create new trail
	local trail = Instance.new("Trail")
	trail.Name = "RedGlowTrail"
	trail.Attachment0 = Instance.new("Attachment")
	trail.Attachment0.Name = "TrailAttachment0"
	trail.Attachment0.Parent = hrp
	
	trail.Attachment1 = Instance.new("Attachment")
	trail.Attachment1.Name = "TrailAttachment1"
	trail.Attachment1.Parent = hrp
	
	-- Position attachments with more separation for longer trail effect
	trail.Attachment0.Position = Vector3.new(0, 1, 0)
	trail.Attachment1.Position = Vector3.new(0, -1, 0)
	
	-- Configure trail appearance for much longer, path-following trail
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 50, 50)) -- Bright red
	trail.Transparency = NumberSequence.new(0.1, 0.9) -- More opaque at start, fade to transparent
	trail.Lifetime = 6.0 -- 5x longer trail duration (was 1.2)
	trail.MinLength = 2.5 -- 5x longer minimum trail length (was 0.5)
	trail.MaxLength = 20 -- 5x longer maximum trail length (was 4)
	trail.WidthScale = NumberSequence.new(0.8, 2.0) -- Slightly wider for better visibility
	trail.FaceCamera = true -- Trail faces the camera
	trail.Parent = character
	
	return trail
end

local function removeRedGlowTrail(character: Model)
	local trail = character:FindFirstChild("RedGlowTrail")
	if trail then
		trail:Destroy()
	end
end

-- Red marble permanent fire effects
local function createRedFireEffects(character: Model, cosmetic: BasePart)
	-- Remove existing fire effects if they exist
	local existingFire = cosmetic:FindFirstChild("RedFireAttachment")
	if existingFire then
		existingFire:Destroy()
	end
	
	-- Create attachment for fire particles
	local fireAttachment = Instance.new("Attachment")
	fireAttachment.Name = "RedFireAttachment"
	fireAttachment.Parent = cosmetic
	
	-- Main fire particles
	local fireParticles = Instance.new("ParticleEmitter")
	fireParticles.Name = "RedFireParticles"
	fireParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
	fireParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)), -- Bright yellow core
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 150, 50)), -- Orange
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 50, 0)),   -- Red-orange
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 20, 0))      -- Dark red
	})
	fireParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.3, 1.2),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	fireParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	fireParticles.Rate = 200
	fireParticles.Lifetime = NumberRange.new(0.3, 0.6)
	fireParticles.Speed = NumberRange.new(3, 8)
	fireParticles.SpreadAngle = Vector2.new(180, 180) -- Emit in all directions (sphere)
	fireParticles.RotSpeed = NumberRange.new(-100, 100)
	fireParticles.Rotation = NumberRange.new(0, 360)
	fireParticles.Acceleration = Vector3.new(0, 5, 0) -- Slight upward drift
	fireParticles.LightEmission = 0.8
	fireParticles.LightInfluence = 0.2
	fireParticles.Parent = fireAttachment
	
	-- Add ember/spark particles
	local emberParticles = Instance.new("ParticleEmitter")
	emberParticles.Name = "RedEmberParticles"
	emberParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emberParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0))
	})
	emberParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.5, 0.25),
		NumberSequenceKeypoint.new(1, 0.05)
	})
	emberParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	emberParticles.Rate = 15
	emberParticles.Lifetime = NumberRange.new(0.5, 1.0)
	emberParticles.Speed = NumberRange.new(5, 12)
	emberParticles.SpreadAngle = Vector2.new(180, 180)
	emberParticles.Acceleration = Vector3.new(0, 3, 0)
	emberParticles.LightEmission = 1
	emberParticles.LightInfluence = 0
	emberParticles.Parent = fireAttachment
	
	-- Add a warm glow light
	local fireGlow = Instance.new("PointLight")
	fireGlow.Name = "RedFireGlow"
	fireGlow.Color = Color3.fromRGB(255, 100, 30)
	fireGlow.Brightness = 1.5
	fireGlow.Range = 8
	fireGlow.Parent = cosmetic
	
	return fireAttachment
end

local function removeRedFireEffects(cosmetic: BasePart)
	local fireAttachment = cosmetic:FindFirstChild("RedFireAttachment")
	if fireAttachment then
		fireAttachment:Destroy()
	end
	
	local fireGlow = cosmetic:FindFirstChild("RedFireGlow")
	if fireGlow then
		fireGlow:Destroy()
	end
end

local function setupRedFireEffect(character: Model, cosmetic: BasePart)
	-- Function to update fire effects based on equipped marble
	local function updateFireEffects()
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "Red" then
			createRedFireEffects(character, cosmetic)
		else
			removeRedFireEffects(cosmetic)
		end
	end
	
	-- Initial check
	updateFireEffects()
	
	-- Monitor for marble changes
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(updateFireEffects)
end

local function createGumballGlowTrail(character: Model, hrp: BasePart)
	-- Remove existing trail if it exists
	local existingTrail = character:FindFirstChild("GumballGlowTrail")
	if existingTrail then
		existingTrail:Destroy()
	end
	
	-- Create new trail
	local trail = Instance.new("Trail")
	trail.Name = "GumballGlowTrail"
	trail.Attachment0 = Instance.new("Attachment")
	trail.Attachment0.Name = "GumballTrailAttachment0"
	trail.Attachment0.Parent = hrp
	
	trail.Attachment1 = Instance.new("Attachment")
	trail.Attachment1.Name = "GumballTrailAttachment1"
	trail.Attachment1.Parent = hrp
	
	-- Position attachments with more separation for longer trail effect
	trail.Attachment0.Position = Vector3.new(0, 1, 0)
	trail.Attachment1.Position = Vector3.new(0, -1, 0)
	
	-- Configure trail appearance for gumball effect
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 100, 200)) -- Pink gumball color
	trail.Transparency = NumberSequence.new(0.1, 0.9) -- More opaque at start, fade to transparent
	trail.Lifetime = 3.0 -- Trail duration
	trail.MinLength = 1.5 -- Trail length
	trail.MaxLength = 12 -- Maximum trail length
	trail.WidthScale = NumberSequence.new(0.6, 1.5) -- Trail width
	trail.FaceCamera = true -- Trail faces the camera
	trail.Parent = character
	
	return trail
end

local function removeGumballGlowTrail(character: Model)
	local trail = character:FindFirstChild("GumballGlowTrail")
	if trail then
		trail:Destroy()
	end
end

local function createMoonGlowTrail(character: Model, hrp: BasePart)
	-- Remove existing trail if it exists
	local existingTrail = character:FindFirstChild("MoonGlowTrail")
	if existingTrail then
		existingTrail:Destroy()
	end
	
	-- Create new trail
	local trail = Instance.new("Trail")
	trail.Name = "MoonGlowTrail"
	trail.Attachment0 = Instance.new("Attachment")
	trail.Attachment0.Name = "MoonTrailAttachment0"
	trail.Attachment0.Parent = hrp
	
	trail.Attachment1 = Instance.new("Attachment")
	trail.Attachment1.Name = "MoonTrailAttachment1"
	trail.Attachment1.Parent = hrp
	
	-- Position attachments with more separation for longer trail effect
	trail.Attachment0.Position = Vector3.new(0, 1, 0)
	trail.Attachment1.Position = Vector3.new(0, -1, 0)
	
	-- Configure trail appearance for moon effect
	trail.Color = ColorSequence.new(Color3.fromRGB(200, 200, 255)) -- Soft white/blue moon glow
	trail.Transparency = NumberSequence.new(0.2, 0.95) -- More transparent for subtle effect
	trail.Lifetime = 4.0 -- Trail duration
	trail.MinLength = 1.0 -- Trail length
	trail.MaxLength = 15 -- Maximum trail length
	trail.WidthScale = NumberSequence.new(0.5, 1.2) -- Trail width
	trail.FaceCamera = true -- Trail faces the camera
	trail.Parent = character
	
	return trail
end

local function removeMoonGlowTrail(character: Model)
	local trail = character:FindFirstChild("MoonGlowTrail")
	if trail then
		trail:Destroy()
	end
end

local function createBlueGlowTrail(character: Model, hrp: BasePart)
	-- Remove existing trail if it exists
	local existingTrail = character:FindFirstChild("BlueGlowTrail")
	if existingTrail then
		existingTrail:Destroy()
	end
	
	-- Create new trail
	local trail = Instance.new("Trail")
	trail.Name = "BlueGlowTrail"
	trail.Attachment0 = Instance.new("Attachment")
	trail.Attachment0.Name = "BlueTrailAttachment0"
	trail.Attachment0.Parent = hrp
	
	trail.Attachment1 = Instance.new("Attachment")
	trail.Attachment1.Name = "BlueTrailAttachment1"
	trail.Attachment1.Parent = hrp
	
	-- Position attachments with more separation for longer trail effect
	trail.Attachment0.Position = Vector3.new(0, 1, 0)
	trail.Attachment1.Position = Vector3.new(0, -1, 0)
	
	-- Configure trail appearance for blue effect
	trail.Color = ColorSequence.new(Color3.fromRGB(60, 120, 220)) -- Blue color
	trail.Transparency = NumberSequence.new(0.1, 0.9) -- More opaque at start, fade to transparent
	trail.Lifetime = 4.0 -- Long trail duration
	trail.MinLength = 2.0 -- Trail length
	trail.MaxLength = 20 -- Long maximum trail length
	trail.WidthScale = NumberSequence.new(0.8, 2.0) -- Trail width
	trail.FaceCamera = true -- Trail faces the camera
	trail.Parent = character
	
	return trail
end

local function removeBlueGlowTrail(character: Model)
	local trail = character:FindFirstChild("BlueGlowTrail")
	if trail then
		trail:Destroy()
	end
end

local function createGreenGlowTrail(character: Model, hrp: BasePart)
	-- Remove existing trail if it exists
	local existingTrail = character:FindFirstChild("GreenGlowTrail")
	if existingTrail then
		existingTrail:Destroy()
	end
	
	-- Create new trail
	local trail = Instance.new("Trail")
	trail.Name = "GreenGlowTrail"
	trail.Attachment0 = Instance.new("Attachment")
	trail.Attachment0.Name = "GreenTrailAttachment0"
	trail.Attachment0.Parent = hrp
	
	trail.Attachment1 = Instance.new("Attachment")
	trail.Attachment1.Name = "GreenTrailAttachment1"
	trail.Attachment1.Parent = hrp
	
	-- Position attachments with more separation for longer trail effect
	trail.Attachment0.Position = Vector3.new(0, 1, 0)
	trail.Attachment1.Position = Vector3.new(0, -1, 0)
	
	-- Configure trail appearance for green effect
	trail.Color = ColorSequence.new(Color3.fromRGB(70, 200, 90)) -- Green color
	trail.Transparency = NumberSequence.new(0.1, 0.9) -- More opaque at start, fade to transparent
	trail.Lifetime = 4.0 -- Long trail duration
	trail.MinLength = 2.0 -- Trail length
	trail.MaxLength = 20 -- Long maximum trail length
	trail.WidthScale = NumberSequence.new(0.8, 2.0) -- Trail width
	trail.FaceCamera = true -- Trail faces the camera
	trail.Parent = character
	
	return trail
end

local function removeGreenGlowTrail(character: Model)
	local trail = character:FindFirstChild("GreenGlowTrail")
	if trail then
		trail:Destroy()
	end
end

local function createGoldGlowTrail(character: Model, hrp: BasePart)
	-- Remove existing trail if it exists
	local existingTrail = character:FindFirstChild("GoldGlowTrail")
	if existingTrail then
		existingTrail:Destroy()
	end
	
	-- Create new trail
	local trail = Instance.new("Trail")
	trail.Name = "GoldGlowTrail"
	trail.Attachment0 = Instance.new("Attachment")
	trail.Attachment0.Name = "GoldTrailAttachment0"
	trail.Attachment0.Parent = hrp
	
	trail.Attachment1 = Instance.new("Attachment")
	trail.Attachment1.Name = "GoldTrailAttachment1"
	trail.Attachment1.Parent = hrp
	
	-- Position attachments with more separation for longer trail effect
	trail.Attachment0.Position = Vector3.new(0, 1, 0)
	trail.Attachment1.Position = Vector3.new(0, -1, 0)
	
	-- Configure trail appearance for gold effect
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)) -- Gold color
	trail.Transparency = NumberSequence.new(0.1, 0.9) -- More opaque at start, fade to transparent
	trail.Lifetime = 4.0 -- Trail duration
	trail.MinLength = 1.5 -- Trail length
	trail.MaxLength = 15 -- Maximum trail length
	trail.WidthScale = NumberSequence.new(0.7, 1.5) -- Trail width
	trail.FaceCamera = true -- Trail faces the camera
	trail.Parent = character
	
	return trail
end

local function removeGoldGlowTrail(character: Model)
	local trail = character:FindFirstChild("GoldGlowTrail")
	if trail then
		trail:Destroy()
	end
end

local function createPharaohGlowTrail(character: Model, hrp: BasePart)
	-- Remove existing trail if it exists
	local existingTrail = character:FindFirstChild("PharaohGlowTrail")
	if existingTrail then
		existingTrail:Destroy()
	end
	
	-- Create new trail
	local trail = Instance.new("Trail")
	trail.Name = "PharaohGlowTrail"
	trail.Attachment0 = Instance.new("Attachment")
	trail.Attachment0.Name = "PharaohTrailAttachment0"
	trail.Attachment0.Parent = hrp
	
	trail.Attachment1 = Instance.new("Attachment")
	trail.Attachment1.Name = "PharaohTrailAttachment1"
	trail.Attachment1.Parent = hrp
	
	-- Position attachments with more separation for longer trail effect
	trail.Attachment0.Position = Vector3.new(0, 1, 0)
	trail.Attachment1.Position = Vector3.new(0, -1, 0)
	
	-- Configure trail appearance for red/gold pharaoh effect
	trail.Color = ColorSequence.new(
		Color3.fromRGB(255, 50, 50), -- Red
		Color3.fromRGB(255, 215, 0)  -- Gold
	)
	trail.Transparency = NumberSequence.new(0.1, 0.9) -- More opaque at start, fade to transparent
	trail.Lifetime = 5.0 -- Trail duration
	trail.MinLength = 2.0 -- Trail length
	trail.MaxLength = 18 -- Maximum trail length
	trail.WidthScale = NumberSequence.new(0.8, 2.2) -- Trail width
	trail.FaceCamera = true -- Trail faces the camera
	trail.Parent = character
	
	return trail
end

local function removePharaohGlowTrail(character: Model)
	local trail = character:FindFirstChild("PharaohGlowTrail")
	if trail then
		trail:Destroy()
	end
end

local function createTsunamiWaterGlow(character: Model, hrp: BasePart)
	-- Remove existing effects if they exist
	local existingGlow = character:FindFirstChild("TsunamiWaterGlow")
	if existingGlow then
		existingGlow:Destroy()
	end
	
	-- Create water glow container
	local glowContainer = Instance.new("Model")
	glowContainer.Name = "TsunamiWaterGlow"
	glowContainer.Parent = character
	
	-- Create point light for ocean glow
	local waterLight = Instance.new("PointLight")
	waterLight.Name = "TsunamiWaterLight"
	waterLight.Color = Color3.fromRGB(100, 200, 255) -- Ocean blue
	waterLight.Brightness = 2
	waterLight.Range = 12
	waterLight.Parent = hrp
	
	-- Create attachment for water particles
	local waterAttachment = Instance.new("Attachment")
	waterAttachment.Name = "TsunamiWaterAttachment"
	waterAttachment.Parent = hrp
	
	-- Create water particle emitter
	local waterParticles = Instance.new("ParticleEmitter")
	waterParticles.Name = "TsunamiWaterParticles"
	waterParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	waterParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(200, 230, 255)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(100, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 255))
	})
	waterParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1.2),
		NumberSequenceKeypoint.new(1, 0.3)
	})
	waterParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.7, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	waterParticles.Rate = 30
	waterParticles.Lifetime = NumberRange.new(1, 2)
	waterParticles.Speed = NumberRange.new(2, 5)
	waterParticles.SpreadAngle = Vector2.new(360, 360)
	waterParticles.Acceleration = Vector3.new(0, -2, 0)
	waterParticles.Parent = waterAttachment
	
	-- Create sparkle particles for ocean sparkles
	local sparkleAttachment = Instance.new("Attachment")
	sparkleAttachment.Name = "TsunamiSparkleAttachment"
	sparkleAttachment.Parent = hrp
	
	local sparkleParticles = Instance.new("ParticleEmitter")
	sparkleParticles.Name = "TsunamiSparkleParticles"
	sparkleParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkleParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(173, 216, 230)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(100, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255))
	})
	sparkleParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	sparkleParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	sparkleParticles.Rate = 20
	sparkleParticles.Lifetime = NumberRange.new(0.8, 1.5)
	sparkleParticles.Speed = NumberRange.new(1, 3)
	sparkleParticles.SpreadAngle = Vector2.new(360, 360)
	sparkleParticles.Parent = sparkleAttachment
	
	-- Container is just for tracking - attachments and light stay on HRP
	return glowContainer
end

local function removeTsunamiWaterGlow(character: Model)
	local glow = character:FindFirstChild("TsunamiWaterGlow")
	if glow then
		glow:Destroy()
	end
	
	-- Also clean up any attachments that might be left on HRP
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local waterLight = hrp:FindFirstChild("TsunamiWaterLight")
		if waterLight then
			waterLight:Destroy()
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

local function setupRedGlowEffect(character: Model, hrp: BasePart)
	-- Monitor RedGlowActive attribute changes
	character:GetAttributeChangedSignal("RedGlowActive"):Connect(function()
		local isActive = character:GetAttribute("RedGlowActive")
		if isActive then
			createRedGlowTrail(character, hrp)
		else
			removeRedGlowTrail(character)
		end
	end)
	
	-- Check initial state
	local initialGlow = character:GetAttribute("RedGlowActive")
	if initialGlow then
		createRedGlowTrail(character, hrp)
	end
end

local function setupGumballGlowEffect(character: Model, hrp: BasePart)
	-- Monitor GumballGlowActive attribute changes
	character:GetAttributeChangedSignal("GumballGlowActive"):Connect(function()
		local isActive = character:GetAttribute("GumballGlowActive")
		if isActive then
			createGumballGlowTrail(character, hrp)
		else
			removeGumballGlowTrail(character)
		end
	end)
	
	-- Check initial state
	local initialGlow = character:GetAttribute("GumballGlowActive")
	if initialGlow then
		createGumballGlowTrail(character, hrp)
	end
end

local function setupMoonGlowEffect(character: Model, hrp: BasePart)
	-- Monitor MoonGlowActive attribute changes
	character:GetAttributeChangedSignal("MoonGlowActive"):Connect(function()
		local isActive = character:GetAttribute("MoonGlowActive")
		if isActive then
			createMoonGlowTrail(character, hrp)
		else
			removeMoonGlowTrail(character)
		end
	end)
	
	-- Check initial state
	local initialGlow = character:GetAttribute("MoonGlowActive")
	if initialGlow then
		createMoonGlowTrail(character, hrp)
	end
end

local function setupBlueGlowEffect(character: Model, hrp: BasePart)
	-- Function to update blue trail based on equipped marble
	local function updateBlueTrail()
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "Blue" then
			createBlueGlowTrail(character, hrp)
		else
			removeBlueGlowTrail(character)
		end
	end
	
	-- Initial check
	updateBlueTrail()
	
	-- Monitor for marble changes
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(updateBlueTrail)
end

local function setupGreenGlowEffect(character: Model, hrp: BasePart)
	-- Function to update green trail based on equipped marble
	local function updateGreenTrail()
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "Green" then
			createGreenGlowTrail(character, hrp)
		else
			removeGreenGlowTrail(character)
		end
	end
	
	-- Initial check
	updateGreenTrail()
	
	-- Monitor for marble changes
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(updateGreenTrail)
end

local function setupGoldGlowEffect(character: Model, hrp: BasePart)
	-- Monitor GoldGlowActive attribute changes
	character:GetAttributeChangedSignal("GoldGlowActive"):Connect(function()
		local isActive = character:GetAttribute("GoldGlowActive")
		if isActive then
			createGoldGlowTrail(character, hrp)
		else
			removeGoldGlowTrail(character)
		end
	end)
	
	-- Check initial state
	local initialGlow = character:GetAttribute("GoldGlowActive")
	if initialGlow then
		createGoldGlowTrail(character, hrp)
	end
end

local function setupPharaohGlowEffect(character: Model, hrp: BasePart)
	-- Monitor PharaohGlowActive attribute changes
	character:GetAttributeChangedSignal("PharaohGlowActive"):Connect(function()
		local isActive = character:GetAttribute("PharaohGlowActive")
		if isActive then
			createPharaohGlowTrail(character, hrp)
		else
			removePharaohGlowTrail(character)
		end
	end)
	
	-- Check initial state
	local initialGlow = character:GetAttribute("PharaohGlowActive")
	if initialGlow then
		createPharaohGlowTrail(character, hrp)
	end
end

local function setupTsunamiWaterGlowEffect(character: Model, hrp: BasePart)
	-- Function to update water glow based on equipped marble
	local function updateWaterGlow()
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "Tsunami" then
			createTsunamiWaterGlow(character, hrp)
		else
			removeTsunamiWaterGlow(character)
		end
	end
	
	-- Initial check
	updateWaterGlow()
	
	-- Monitor for marble changes
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(updateWaterGlow)
end

local function createMeteorFireEffect(character: Model, hrp: BasePart)
	-- Remove existing effects if they exist
	local existingEffect = character:FindFirstChild("MeteorFireEffect")
	if existingEffect then
		existingEffect:Destroy()
	end
	
	-- Create fire effect container
	local effectContainer = Instance.new("Model")
	effectContainer.Name = "MeteorFireEffect"
	effectContainer.Parent = character
	
	-- Create fire particles attachment
	local fireAttachment = Instance.new("Attachment")
	fireAttachment.Name = "MeteorFireAttachment"
	fireAttachment.Parent = hrp
	
	-- Create fire particle emitter
	local fireParticles = Instance.new("ParticleEmitter")
	fireParticles.Name = "MeteorFireParticles"
	fireParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
	fireParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 150, 0)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 100, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 0))
	})
	fireParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 1.5),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	fireParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	fireParticles.Rate = 40
	fireParticles.Lifetime = NumberRange.new(0.5, 1)
	fireParticles.Speed = NumberRange.new(2, 5)
	fireParticles.SpreadAngle = Vector2.new(360, 360)
	fireParticles.Parent = fireAttachment
	
	-- Create fire glow
	local fireLight = Instance.new("PointLight")
	fireLight.Name = "MeteorFireLight"
	fireLight.Color = Color3.fromRGB(255, 150, 0)
	fireLight.Brightness = 2.5
	fireLight.Range = 15
	fireLight.Parent = hrp
	
	-- Create grey trail
	local trail = Instance.new("Trail")
	trail.Name = "MeteorGreyTrail"
	trail.Attachment0 = Instance.new("Attachment")
	trail.Attachment0.Name = "MeteorTrailAttachment0"
	trail.Attachment0.Parent = hrp
	
	trail.Attachment1 = Instance.new("Attachment")
	trail.Attachment1.Name = "MeteorTrailAttachment1"
	trail.Attachment1.Parent = hrp
	
	-- Position attachments
	trail.Attachment0.Position = Vector3.new(0, 1, 0)
	trail.Attachment1.Position = Vector3.new(0, -1, 0)
	
	-- Configure trail appearance for grey meteor effect
	trail.Color = ColorSequence.new(Color3.fromRGB(120, 120, 120)) -- Grey color
	trail.Transparency = NumberSequence.new(0.2, 0.9) -- More opaque at start, fade to transparent
	trail.Lifetime = 2.5 -- Trail duration
	trail.MinLength = 1.5 -- Trail length
	trail.MaxLength = 15 -- Maximum trail length
	trail.WidthScale = NumberSequence.new(0.8, 2.0) -- Trail width
	trail.FaceCamera = true -- Trail faces the camera
	trail.Parent = character
	
	return effectContainer
end

local function removeMeteorFireEffect(character: Model)
	local effect = character:FindFirstChild("MeteorFireEffect")
	if effect then
		effect:Destroy()
	end
	
	-- Clean up trail
	local trail = character:FindFirstChild("MeteorGreyTrail")
	if trail then
		trail:Destroy()
	end
	
	-- Clean up attachments on HRP
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local fireLight = hrp:FindFirstChild("MeteorFireLight")
		if fireLight then
			fireLight:Destroy()
		end
		local fireAttachment = hrp:FindFirstChild("MeteorFireAttachment")
		if fireAttachment then
			fireAttachment:Destroy()
		end
		local trailAttachment0 = hrp:FindFirstChild("MeteorTrailAttachment0")
		if trailAttachment0 then
			trailAttachment0:Destroy()
		end
		local trailAttachment1 = hrp:FindFirstChild("MeteorTrailAttachment1")
		if trailAttachment1 then
			trailAttachment1:Destroy()
		end
	end
end

local function setupMeteorFireEffect(character: Model, hrp: BasePart)
	-- Function to update fire effect based on equipped marble
	local function updateFireEffect()
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "Meteor" then
			createMeteorFireEffect(character, hrp)
		else
			removeMeteorFireEffect(character)
		end
	end
	
	-- Initial check
	updateFireEffect()
	
	-- Monitor for marble changes
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(updateFireEffect)
end

local function applyCosmeticColorFromEquipped(character: Model, cosmetic: BasePart)
	local id = character:GetAttribute("EquippedMarbleId")
	dprint("applyCosmeticColor", id)
	if type(id) ~= "string" then return end
	local def = Marbles.getById(id)
	if def and def.color then
		cosmetic.Color = def.color
	else
		cosmetic.Color = Color3.fromRGB(230,230,230)
	end
end

local function applyCosmeticTexturesFromEquipped(character: Model, cosmetic: BasePart)
	local id = character:GetAttribute("EquippedMarbleId")
	dprint("applyCosmeticTextures", id)
	if type(id) ~= "string" then return end
	local texturesRoot = ReplicatedStorage:FindFirstChild("MarbleTextures")
	local folder = texturesRoot and texturesRoot:FindFirstChild(id) or nil
	-- Clear existing
	for _, ch in ipairs(cosmetic:GetChildren()) do
		if ch:IsA("Decal") or ch:IsA("Texture") then ch:Destroy() end
	end
	local assets = {}
	if folder then
		for _, inst in ipairs(folder:GetChildren()) do
			if inst:IsA("Decal") or inst:IsA("Texture") then
				table.insert(assets, inst)
			end
		end
	end
	local DEFAULT_DECALS: { [string]: string } = {
		Default = "rbxassetid://110926540048461",
		Red = "rbxassetid://99977275020564",
		Green = "rbxassetid://114474679212927",
		Blue = "rbxassetid://128223600665334",
		Spider = "rbxassetid://105354663033087",
		Gumball = "rbxassetid://92160789193138",
		TimeTravel = "rbxassetid://115652916108662",
		Moon = "rbxassetid://95370471502854",
		Jumper = "rbxassetid://81030833444551",
		Glass = "rbxassetid://101699002274981", -- Glass texture
		Gold = "rbxassetid://84142305330257", -- Gold texture
		Diamond = "rbxassetid://95881293008595", -- Diamond texture
		Teleporting = "rbxassetid://73544653958153", -- Teleporting texture
		Pharaoh = "rbxassetid://138858793251784", -- Pharaoh texture
		Leaf = "rbxassetid://107199178243113", -- Leaf texture
		Volcano = "rbxassetid://72936982579332", -- Volcano texture
		Tsunami = "rbxassetid://109162306563849", -- Tsunami texture
		Meteor = "rbxassetid://135554382256334", -- Meteor texture
		Coin = "rbxassetid://98528749229098", -- Coin texture
	}
	if #assets == 0 then
		local fallback = DEFAULT_DECALS[id]
		dprint("no assets found; using fallback?", fallback ~= nil)
		if fallback then
			for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
				local d = Instance.new("Decal")
				d.Texture = fallback
				d.Face = face
				d.Parent = cosmetic
			end
		end
		return
	end
	dprint("found", #assets, "assets for", id)
	if #assets == 1 then
		local src = assets[1]
		for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
			local clone = src:Clone()
			if clone:IsA("Decal") then
				(clone :: Decal).Face = face
			elseif clone:IsA("Texture") then
				(clone :: Texture).Face = face
			end
			clone.Parent = cosmetic
		end
		return
	end
	for _, src in ipairs(assets) do
		local clone = src:Clone()
		clone.Parent = cosmetic
	end
end

local function muteFootstepsLocal(character: Model)
	local function handleDescendant(descendant: Instance)
		if descendant:IsA("Sound") then
			local n = descendant.Name
			if n == "Running" or n == "Run" or n == "Footsteps" or n == "Jumping" or n == "Jump" then
				descendant.Volume = 0
				descendant.Playing = false
			end
		elseif (descendant:IsA("LocalScript") or descendant:IsA("Script")) and descendant.Name == "RbxCharacterSounds" then
			descendant:Destroy()
		end
	end
	for _, d in ipairs(character:GetDescendants()) do
		handleDescendant(d)
	end
	character.DescendantAdded:Connect(handleDescendant)
end

local function setupNameplateScaling(character: Model)
	local gui = character:FindFirstChild("Nameplate")
	if not gui or not gui:IsA("BillboardGui") then return end
	local basePixels = 180 -- must match server base width
	local baseDistance = 25 -- distance at which the size equals basePixels
	local minScale = 0.6
	local maxScale = 1.2
	local cam = workspace.CurrentCamera

	local function update()
		if not cam then cam = workspace.CurrentCamera end
		local adornee = gui.Adornee
		if not adornee or not adornee.Parent then return end
		local camPos = cam and cam.CFrame.Position or Vector3.zero
		local dist = (adornee.Position - camPos).Magnitude
		local scale = math.clamp(baseDistance / dist, minScale, maxScale)
		gui.Size = UDim2.fromOffset(basePixels * scale, 36 * scale)
	end

	update()
	RunService.RenderStepped:Connect(update)
end

-- Enhanced nameplate styling based on rarity
local function setupEnhancedNameplate(character: Model)
	local gui = character:FindFirstChild("Nameplate")
	if not gui or not gui:IsA("BillboardGui") then return end
	
	local label = gui:FindFirstChild("Label")
	if not label or not label:IsA("TextLabel") then return end
	
	-- Function to apply rarity-based styling
	local function applyRarityStyling()
		local rarityTier = character:GetAttribute("NameplateRarityTier")
		local fontName = character:GetAttribute("NameplateFont")
		local textColor = character:GetAttribute("NameplateTextColor")
		local glowColor = character:GetAttribute("NameplateGlowColor")
		local rarityScale = character:GetAttribute("NameplateScale") or 1.0
		
		if not rarityTier then return end
		
		-- Apply font
		if fontName then
			label.Font = Enum.Font[fontName] or Enum.Font.GothamBold
		end
		
		-- Apply text color
		if textColor then
			label.TextColor3 = textColor
		end
		
		-- Add text stroke effects for higher rarities
		if rarityTier == "Rare" or rarityTier == "Epic" or rarityTier == "Legendary" then
			label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			label.TextStrokeTransparency = 0.3
		else
			label.TextStrokeTransparency = 1
		end
		
		-- Add shadow effect for epic+ rarities
		if rarityTier == "Epic" or rarityTier == "Legendary" then
			label.TextStrokeTransparency = 0.1
			label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		end
		
		-- Apply rarity-based scaling
		local baseSize = gui.Size
		gui.Size = UDim2.fromOffset(baseSize.X.Offset * rarityScale, baseSize.Y.Offset * rarityScale)
		
		-- Add subtle floating animation for epic+ rarities
		if rarityTier == "Epic" or rarityTier == "Legendary" then
			local originalOffset = gui.StudsOffset
			local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local floatTween = game:GetService("TweenService"):Create(gui, tweenInfo, {
				StudsOffset = Vector3.new(originalOffset.X, originalOffset.Y + 0.3, originalOffset.Z)
			})
			floatTween:Play()
		end
		
		-- Add text scaling animation for legendary marbles
		if rarityTier == "Legendary" then
			local originalSize = label.Size
			local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local scaleTween = game:GetService("TweenService"):Create(label, tweenInfo, {
				Size = UDim2.fromScale(1.05, 1.05)
			})
			scaleTween:Play()
		end
		
		-- Remove existing rarity effects
		local effectsToRemove = {"RarityGlow", "RainbowGlow", "EpicStar", "RareDiamond", "LegendarySparkle", "UncommonLeaf"}
		for _, effectName in ipairs(effectsToRemove) do
			local existingEffect = gui:FindFirstChild(effectName)
			if existingEffect then
				existingEffect:Destroy()
			end
		end
		
		-- Add glow effect for uncommon+ rarities
		if glowColor and rarityTier ~= "Common" then
			local glow = Instance.new("TextLabel")
			glow.Name = "RarityGlow"
			glow.Size = UDim2.fromScale(1.1, 1.1)
			glow.Position = UDim2.fromScale(-0.05, -0.05)
			glow.BackgroundTransparency = 1
			glow.Text = label.Text
			glow.TextScaled = true
			glow.Font = label.Font
			glow.TextColor3 = glowColor
			glow.TextTransparency = 0.7
			glow.ZIndex = label.ZIndex - 1
			glow.Parent = gui
			
			-- Add subtle animation for epic+ rarities
			if rarityTier == "Epic" or rarityTier == "Legendary" then
				local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
				local tween = game:GetService("TweenService"):Create(glow, tweenInfo, {
					TextTransparency = 0.3
				})
				tween:Play()
			end
			
			-- Add rainbow effect for legendary marbles
			if rarityTier == "Legendary" then
				local rainbowTween = game:GetService("TweenService"):Create(glow, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
					TextColor3 = Color3.fromRGB(255, 100, 100)
				})
				rainbowTween:Play()
				
				-- Create a second rainbow layer for extra effect
				local rainbowGlow = glow:Clone()
				rainbowGlow.Name = "RainbowGlow"
				rainbowGlow.Position = UDim2.fromScale(-0.1, -0.1)
				rainbowGlow.Size = UDim2.fromScale(1.2, 1.2)
				rainbowGlow.TextTransparency = 0.8
				rainbowGlow.ZIndex = glow.ZIndex - 1
				rainbowGlow.Parent = gui
				
				local rainbowTween2 = game:GetService("TweenService"):Create(rainbowGlow, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
					TextColor3 = Color3.fromRGB(100, 255, 100)
				})
				rainbowTween2:Play()
			end
		end
		
		-- Add special effects for different rarity tiers
		if rarityTier == "Epic" then
			-- Add epic star effect
			local star = Instance.new("Frame")
			star.Name = "EpicStar"
			star.Size = UDim2.fromOffset(16, 16)
			star.Position = UDim2.fromScale(1.05, 0)
			star.BackgroundTransparency = 1
			star.Parent = gui
			
			local starLabel = Instance.new("TextLabel")
			starLabel.Size = UDim2.fromScale(1, 1)
			starLabel.BackgroundTransparency = 1
			starLabel.Text = "⭐"
			starLabel.TextScaled = true
			starLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
			starLabel.Parent = star
			
			-- Animate star
			local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local tween = game:GetService("TweenService"):Create(star, tweenInfo, {
				Rotation = 360
			})
			tween:Play()
		elseif rarityTier == "Rare" then
			-- Add rare diamond effect
			local diamond = Instance.new("Frame")
			diamond.Name = "RareDiamond"
			diamond.Size = UDim2.fromOffset(14, 14)
			diamond.Position = UDim2.fromScale(1.05, 0)
			diamond.BackgroundTransparency = 1
			diamond.Parent = gui
			
			local diamondLabel = Instance.new("TextLabel")
			diamondLabel.Size = UDim2.fromScale(1, 1)
			diamondLabel.BackgroundTransparency = 1
			diamondLabel.Text = "💎"
			diamondLabel.TextScaled = true
			diamondLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
			diamondLabel.Parent = diamond
			
			-- Subtle pulse animation
			local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local tween = game:GetService("TweenService"):Create(diamond, tweenInfo, {
				Size = UDim2.fromOffset(18, 18)
			})
			tween:Play()
		elseif rarityTier == "Uncommon" then
			-- Add uncommon leaf effect
			local leaf = Instance.new("Frame")
			leaf.Name = "UncommonLeaf"
			leaf.Size = UDim2.fromOffset(12, 12)
			leaf.Position = UDim2.fromScale(1.05, 0)
			leaf.BackgroundTransparency = 1
			leaf.Parent = gui
			
			local leafLabel = Instance.new("TextLabel")
			leafLabel.Size = UDim2.fromScale(1, 1)
			leafLabel.BackgroundTransparency = 1
			leafLabel.Text = "🍃"
			leafLabel.TextScaled = true
			leafLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			leafLabel.Parent = leaf
			
			-- Gentle sway animation
			local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local tween = game:GetService("TweenService"):Create(leaf, tweenInfo, {
				Rotation = 15
			})
			tween:Play()
		elseif rarityTier == "Legendary" then
			-- Add legendary sparkle effect
			local sparkle = Instance.new("Frame")
			sparkle.Name = "LegendarySparkle"
			sparkle.Size = UDim2.fromOffset(20, 20)
			sparkle.Position = UDim2.fromScale(1.1, 0)
			sparkle.BackgroundTransparency = 1
			sparkle.Parent = gui
			
			local sparkleLabel = Instance.new("TextLabel")
			sparkleLabel.Size = UDim2.fromScale(1, 1)
			sparkleLabel.BackgroundTransparency = 1
			sparkleLabel.Text = "✨"
			sparkleLabel.TextScaled = true
			sparkleLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
			sparkleLabel.Parent = sparkle
			
			-- Animate sparkle
			local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local tween = game:GetService("TweenService"):Create(sparkle, tweenInfo, {
				Rotation = 360
			})
			tween:Play()
		end
	end
	
	-- Apply initial styling
	applyRarityStyling()
	
	-- Monitor rarity attribute changes
	character:GetAttributeChangedSignal("NameplateRarityTier"):Connect(applyRarityStyling)
	character:GetAttributeChangedSignal("NameplateFont"):Connect(applyRarityStyling)
	character:GetAttributeChangedSignal("NameplateTextColor"):Connect(applyRarityStyling)
	character:GetAttributeChangedSignal("NameplateGlowColor"):Connect(applyRarityStyling)
	character:GetAttributeChangedSignal("NameplateScale"):Connect(applyRarityStyling)
end

local function setupController(character: Model)
	if boundCharacters[character] then return end
	dprint("setupController for", character)

	local hrp = waitForHRP(character, 5)
	if not hrp then
		local conn
		conn = character.ChildAdded:Connect(function(child)
			if child.Name == "HumanoidRootPart" and child:IsA("BasePart") then
				conn:Disconnect()
				setupController(character)
			end
		end)
		return
	end
	boundCharacters[character] = true

	-- Ensure default Roblox camera follows Humanoid
	local hum = character:FindFirstChildOfClass("Humanoid")
	local cam = workspace.CurrentCamera
	if cam and hum then
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = hum
	end

	-- Make physical root invisible; cosmetic ball will be visible
	hrp.Transparency = 1

	-- Create visual marble that we rotate for effect
	local cosmetic = ensureCosmeticBall(character, hrp)
	applyCosmeticColorFromEquipped(character, cosmetic)
	applyCosmeticTexturesFromEquipped(character, cosmetic)
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(function()
		applyCosmeticColorFromEquipped(character, cosmetic)
		applyCosmeticTexturesFromEquipped(character, cosmetic)
	end)

	-- Mute default character running/jump sounds for this character
	muteFootstepsLocal(character)

	-- Keep nameplate a constant on-screen size
	setupNameplateScaling(character)
	
	-- Setup enhanced rarity-based nameplate styling
	setupEnhancedNameplate(character)
	
	-- Setup glow effects for local player
	setupRedGlowEffect(character, hrp)
	setupGumballGlowEffect(character, hrp)
	setupMoonGlowEffect(character, hrp)
	setupBlueGlowEffect(character, hrp)
	setupGreenGlowEffect(character, hrp)
	setupGoldGlowEffect(character, hrp)
	setupPharaohGlowEffect(character, hrp)
	setupTsunamiWaterGlowEffect(character, hrp)
	setupMeteorFireEffect(character, hrp)
	
	-- Setup Red marble permanent fire effects
	setupRedFireEffect(character, cosmetic)
	
	-- Monitor SpeedMultiplier attribute changes for debugging
	character:GetAttributeChangedSignal("SpeedMultiplier"):Connect(function()
		local newValue = character:GetAttribute("SpeedMultiplier")
		print("[MarbleClient] SpeedMultiplier attribute changed to:", newValue, "Type:", typeof(newValue))
	end)
	
	-- Log initial SpeedMultiplier value
	local initialMultiplier = character:GetAttribute("SpeedMultiplier")
	if initialMultiplier == nil then
		character:SetAttribute("SpeedMultiplier", 1)
		initialMultiplier = 1
	end
	print("[MarbleClient] Initial SpeedMultiplier:", initialMultiplier, "Type:", typeof(initialMultiplier))
	
	-- Monitor JumpBoostActive attribute changes for debugging
	character:GetAttributeChangedSignal("JumpBoostActive"):Connect(function()
		local newValue = character:GetAttribute("JumpBoostActive")
		print("[MarbleClient] JumpBoostActive attribute changed to:", newValue, "Type:", typeof(newValue))
	end)
	
	-- Log initial JumpBoostActive value
	local initialJumpBoost = character:GetAttribute("JumpBoostActive")
	if initialJumpBoost == nil then
		character:SetAttribute("JumpBoostActive", false)
		initialJumpBoost = false
	end
	print("[MarbleClient] Initial JumpBoostActive:", initialJumpBoost, "Type:", typeof(initialJumpBoost))

	-- Track orientation for cosmetic rolling
	local visualCFrame = CFrame.new()
	local lastPos = hrp.Position

	local function getSpeedMultiplier(): number
		local mult = character:GetAttribute("SpeedMultiplier")
		local result = typeof(mult) == "number" and mult or 1
		
		-- Gumball marble gets a permanent speed boost
		local equippedMarbleId = character:GetAttribute("EquippedMarbleId")
		if equippedMarbleId == nil then
			character:SetAttribute("EquippedMarbleId", "Default")
			equippedMarbleId = "Default"
		end
		if equippedMarbleId == "Gumball" then
			result = result * 2 -- 30% speed boost for gumball
		end
		
		return result
	end
	
	local function shouldApplyJumpBoost(): boolean
		local jumpBoost = character:GetAttribute("JumpBoostActive")
		return typeof(jumpBoost) == "boolean" and jumpBoost
	end
	
	local function shouldApplyMoonGravity(): boolean
		local moonGravity = character:GetAttribute("MoonGravityActive")
		return typeof(moonGravity) == "boolean" and moonGravity
	end
	

	local logAccum = 0
	local prevIsInput = false
	local glideHoriz = Vector3.zero
	local jumpStuckTimer = 0 -- Track how long jump has been active while on ground and moving
	local stepConn
	stepConn = RunService.RenderStepped:Connect(function(dt)
		if not hrp or not hrp.Parent then
			if stepConn then stepConn:Disconnect() end
			return
		end
		
		-- Ensure cosmetic ball exists and is visible
		local cosmeticCheck = character:FindFirstChild("CosmeticBall")
		if not cosmeticCheck or not cosmeticCheck:IsA("BasePart") then
			-- Recreate cosmetic ball if it was removed
			cosmetic = ensureCosmeticBall(character, hrp)
			applyCosmeticColorFromEquipped(character, cosmetic)
			applyCosmeticTexturesFromEquipped(character, cosmetic)
		else
			-- Ensure cosmetic ball is visible
			if cosmeticCheck.Transparency >= 1 then
				cosmeticCheck.Transparency = 0
			end
			-- Update cosmetic reference if it changed
			if cosmeticCheck ~= cosmetic then
				cosmetic = cosmeticCheck
			end
		end

		-- Physics movement via linear velocity (horizontal only)
		local cameraNow = workspace.CurrentCamera
		local dir = cameraNow and getMoveDirection(cameraNow) or Vector3.zero
		local speed = baseSpeed * getSpeedMultiplier()
		
		local targetHoriz = dir * speed
		local currentVel = hrp.AssemblyLinearVelocity
		local horiz = Vector3.new(currentVel.X, 0, currentVel.Z)

		-- Deceleration-only: instant target when input; otherwise, glide velocity decays
		local isInput = targetHoriz.Magnitude > 0.01
		local wrote = false
		if isInput then
			local newHoriz = targetHoriz
			if newHoriz.Magnitude < 0.0001 then newHoriz = Vector3.zero end
			glideHoriz = newHoriz
			hrp.AssemblyLinearVelocity = Vector3.new(newHoriz.X, currentVel.Y, newHoriz.Z)
			wrote = true
		else
			-- Decay glide horizontally to simulate ice friction
			local baseFactor = 0.99 -- per 60fps frame
			local frames = math.clamp(dt * 60, 0, 5)
			local reduce = character:GetAttribute("FrictionReduction")
			if reduce == nil then
				character:SetAttribute("FrictionReduction", 0)
				reduce = 0
			end
			local reduction = (typeof(reduce) == "number" and reduce or 0)
			local perFrame = 1 - (1 - baseFactor) * (1 - reduction)
			local factor = perFrame ^ frames
			glideHoriz = glideHoriz * factor
			if glideHoriz.Magnitude < 0.001 then
				glideHoriz = Vector3.zero
			end
			if glideHoriz ~= Vector3.zero then
				hrp.AssemblyLinearVelocity = Vector3.new(glideHoriz.X, currentVel.Y, glideHoriz.Z)
				wrote = true
			end
		end
		
		-- Apply jump boost if active
		if shouldApplyJumpBoost() then
			-- Apply upward velocity boost for jump/launch effect
			local jumpForce = 50 -- Half the original force (was 50)
			local newVel = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(newVel.X, jumpForce, newVel.Z)
			wrote = true
			print("[MarbleClient] Applied jump boost - velocity set to:", hrp.AssemblyLinearVelocity)
		end
		
		-- Apply Moon gravity reduction if active
		if shouldApplyMoonGravity() then
			-- Only reduce downward velocity (falling), leave upward velocity (jumping) unchanged
			local currentVel = hrp.AssemblyLinearVelocity
			if currentVel.Y < 0 then -- Only apply when falling (negative Y velocity)
				local gravityReduction = 0.6 -- Reduce gravity to 60% of normal (moon-like)
				local newYVel = currentVel.Y * gravityReduction
				hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, newYVel, currentVel.Z)
				wrote = true
			end
		end
		
		-- Fix for mobile jump button getting stuck: reset Humanoid.Jump when moving on ground
		-- This prevents continuous jumping on iPhone/iPad when the jump button is pressed while moving
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local currentVel = hrp.AssemblyLinearVelocity
			local isJumpingUpward = currentVel.Y > 5 -- If moving upward faster than 5 studs/sec, they're actively jumping
			local isOnGround = humanoid.FloorMaterial ~= Enum.Material.Air
			
			if isInput and humanoid.Jump and isOnGround and not isJumpingUpward then
				-- Player is on ground, moving, and jump is active - increment timer
				jumpStuckTimer = jumpStuckTimer + dt
				-- Only reset if jump has been stuck for more than 0.2 seconds
				-- This allows the initial jump to happen but prevents continuous jumping
				if jumpStuckTimer > 0.2 then
					humanoid.Jump = false
					jumpStuckTimer = 0
				end
			else
				-- Reset timer if conditions aren't met (not moving, not on ground, or not jumping)
				jumpStuckTimer = 0
			end
		end

		-- Movement debug logs (rate-limited)
		logAccum += dt
		if MOVEMENT_DEBUG and logAccum >= 0.5 then
			logAccum = 0
			local mat = hrp.Material
			local props = hrp.CustomPhysicalProperties
			local friction, fw
			pcall(function()
				friction = props and (props :: any).Friction or nil
				fw = props and (props :: any).FrictionWeight or nil
			end)
			mprint(string.format("input=%s wroteVel=%s horiz=%.2f target=%.2f glide=%.2f mat=%s fric=%s fw=%s", tostring(isInput), tostring(wrote), horiz.Magnitude, targetHoriz.Magnitude, glideHoriz.Magnitude, tostring(mat), tostring(friction), tostring(fw)))
		end
		if isInput ~= prevIsInput then
			prevIsInput = isInput
			mprint("input state changed:", isInput and "START" or "STOP")
		end

		-- Update cosmetic rotation to match traveled distance
		local currentPos = hrp.Position
		local deltaPos = currentPos - lastPos
		lastPos = currentPos
		local deltaXZ = Vector3.new(deltaPos.X, 0, deltaPos.Z)
		local dist = deltaXZ.Magnitude
		if dist > 0.0001 then
			local radius = (hrp.Size.X + hrp.Size.Y + hrp.Size.Z) / 6
			if radius <= 0 then radius = 2 end
			local angle = dist / radius
			local moveDir = deltaXZ.Unit
			local axis = Vector3.new(moveDir.Z, 0, -moveDir.X)
			visualCFrame = CFrame.fromAxisAngle(axis, angle) * visualCFrame
		end
		cosmetic.CFrame = CFrame.new(hrp.Position) * visualCFrame
	end)

	character.AncestryChanged:Connect(function(_, parent)
		if not parent and stepConn then
			stepConn:Disconnect()
		end
	end)

	-- Setup RedGlowTrail effect
	setupRedGlowEffect(character, hrp)
	
	-- Setup GumballGlowTrail effect
	setupGumballGlowEffect(character, hrp)
	
	-- Setup MoonGlowTrail effect
	setupMoonGlowEffect(character, hrp)
	
	-- Setup BlueGlowTrail effect
	setupBlueGlowEffect(character, hrp)
	
	-- Setup GreenGlowTrail effect
	setupGreenGlowEffect(character, hrp)
	
	-- Setup GoldGlowTrail effect
	setupGoldGlowEffect(character, hrp)
	
	-- Setup PharaohGlowTrail effect
	setupPharaohGlowEffect(character, hrp)
	
	-- Setup TsunamiWaterGlow effect
	setupTsunamiWaterGlowEffect(character, hrp)
	
	-- Setup MeteorFire effect
	setupMeteorFireEffect(character, hrp)
	
	-- Setup Red marble permanent fire effects
	setupRedFireEffect(character, cosmetic)
end

local function onCharacterAdded(character: Model)
	setupController(character)
end

-- Setup visual cosmetics only for other players' characters (no movement controls)
local function setupOtherPlayerVisuals(character: Model)
	if not character:GetAttribute("IsMarbleCharacter") then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		-- Wait for HumanoidRootPart to be added
		local conn
		conn = character.ChildAdded:Connect(function(child)
			if child.Name == "HumanoidRootPart" and child:IsA("BasePart") then
				conn:Disconnect()
				setupOtherPlayerVisuals(character)
			end
		end)
		return
	end
	
	-- Make physical root invisible
	hrp.Transparency = 1
	
	-- Create visual marble
	local cosmetic = ensureCosmeticBall(character, hrp)
	applyCosmeticColorFromEquipped(character, cosmetic)
	applyCosmeticTexturesFromEquipped(character, cosmetic)
	
	-- Listen for marble changes
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(function()
		applyCosmeticColorFromEquipped(character, cosmetic)
		applyCosmeticTexturesFromEquipped(character, cosmetic)
	end)
	
	-- Setup nameplate scaling and styling
	setupNameplateScaling(character)
	setupEnhancedNameplate(character)
	
	-- Setup glow effects
	setupRedGlowEffect(character, hrp)
	setupGumballGlowEffect(character, hrp)
	setupMoonGlowEffect(character, hrp)
	setupBlueGlowEffect(character, hrp)
	setupGreenGlowEffect(character, hrp)
	setupGoldGlowEffect(character, hrp)
	setupPharaohGlowEffect(character, hrp)
	setupTsunamiWaterGlowEffect(character, hrp)
	
	-- Setup Red marble permanent fire effects
	setupRedFireEffect(character, cosmetic)
	
	-- Track orientation for cosmetic rolling (visual only, no physics control)
	local visualCFrame = CFrame.new()
	local lastPos = hrp.Position
	
	local stepConn
	stepConn = RunService.RenderStepped:Connect(function(dt)
		if not hrp or not hrp.Parent then
			if stepConn then stepConn:Disconnect() end
			return
		end
		
		-- Ensure cosmetic ball exists and is visible
		local cosmeticCheck = character:FindFirstChild("CosmeticBall")
		if not cosmeticCheck or not cosmeticCheck:IsA("BasePart") then
			cosmetic = ensureCosmeticBall(character, hrp)
			applyCosmeticColorFromEquipped(character, cosmetic)
			applyCosmeticTexturesFromEquipped(character, cosmetic)
		else
			if cosmeticCheck.Transparency >= 1 then
				cosmeticCheck.Transparency = 0
			end
			if cosmeticCheck ~= cosmetic then
				cosmetic = cosmeticCheck
			end
		end
		
		-- Update cosmetic rotation to match traveled distance (visual only)
		local currentPos = hrp.Position
		local deltaPos = currentPos - lastPos
		lastPos = currentPos
		local deltaXZ = Vector3.new(deltaPos.X, 0, deltaPos.Z)
		local dist = deltaXZ.Magnitude
		if dist > 0.0001 then
			local radius = (hrp.Size.X + hrp.Size.Y + hrp.Size.Z) / 6
			if radius <= 0 then radius = 2 end
			local angle = dist / radius
			local moveDir = deltaXZ.Unit
			local axis = Vector3.new(moveDir.Z, 0, -moveDir.X)
			visualCFrame = CFrame.fromAxisAngle(axis, angle) * visualCFrame
		end
		cosmetic.CFrame = CFrame.new(hrp.Position) * visualCFrame
	end)
	
	character.AncestryChanged:Connect(function(_, parent)
		if not parent and stepConn then
			stepConn:Disconnect()
		end
	end)
end

-- Handle other players joining and their characters
local function onOtherPlayerAdded(otherPlayer: Player)
	if otherPlayer == player then return end -- Skip local player
	
	-- Setup existing character
	if otherPlayer.Character then
		setupOtherPlayerVisuals(otherPlayer.Character)
	end
	
	-- Setup future characters
	otherPlayer.CharacterAdded:Connect(function(character)
		-- Small delay to ensure attributes are replicated
		task.wait(0.1)
		setupOtherPlayerVisuals(character)
	end)
end

bindInputs()

-- Setup local player's character
if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Setup other players' characters (visuals only)
for _, otherPlayer in ipairs(Players:GetPlayers()) do
	onOtherPlayerAdded(otherPlayer)
end
Players.PlayerAdded:Connect(onOtherPlayerAdded) 