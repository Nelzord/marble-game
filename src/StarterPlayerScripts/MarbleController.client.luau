-- Marble rolling controller (client-side)
-- Default Roblox camera; visual marble rotates around player while physics uses linear velocity

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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
	jump = false, -- Track actual jump button input
}

local boundCharacters: { [Model]: boolean } = {}

local baseSpeed = 35 -- movement magnitude; abilities can scale via SpeedMultiplier

-- Custom jump button UI
local jumpButtonGui = nil
local jumpButton = nil

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
		if input.KeyCode == Enum.KeyCode.Space then 
			inputState.jump = true
		end
		-- Handle mobile/touch jump button
		if input.KeyCode == Enum.KeyCode.ButtonA or input.UserInputType == Enum.UserInputType.Touch then
			-- Check if it's a jump action (mobile jump button)
			if input.KeyCode == Enum.KeyCode.ButtonA then
				inputState.jump = true
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input, _processed)
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then if inputState.forward == 1 then inputState.forward = 0 end end
		if input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then if inputState.forward == -1 then inputState.forward = 0 end end
		if input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then if inputState.right == 1 then inputState.right = 0 end end
		if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then if inputState.right == -1 then inputState.right = 0 end end
		if input.KeyCode == Enum.KeyCode.Space then 
			inputState.jump = false
		end
		-- Handle mobile/touch jump button release
		if input.KeyCode == Enum.KeyCode.ButtonA then
			inputState.jump = false
		end
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
	-- Remove existing effects if they exist
	local existingTrail = character:FindFirstChild("BlueGlowTrail")
	if existingTrail then
		existingTrail:Destroy()
	end
	
	local existingGlow = character:FindFirstChild("BlueGlowAura")
	if existingGlow then
		existingGlow:Destroy()
	end
	
	-- Create glow aura container
	local glowContainer = Instance.new("Model")
	glowContainer.Name = "BlueGlowAura"
	glowContainer.Parent = character
	
	-- Create blue point light for glow
	local blueLight = Instance.new("PointLight")
	blueLight.Name = "BlueGlowLight"
	blueLight.Color = Color3.fromRGB(60, 120, 220) -- Blue color
	blueLight.Brightness = 2.5
	blueLight.Range = 12
	blueLight.Parent = hrp
	
	-- Create attachment for water particles
	local waterAttachment = Instance.new("Attachment")
	waterAttachment.Name = "BlueWaterAttachment"
	waterAttachment.Parent = hrp
	
	-- Create water particle emitter
	local waterParticles = Instance.new("ParticleEmitter")
	waterParticles.Name = "BlueWaterParticles"
	waterParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	waterParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), -- White
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(200, 230, 255)), -- Light blue
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(100, 180, 255)), -- Blue
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 120, 220)) -- Dark blue
	})
	waterParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 1.0),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	waterParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.7, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	waterParticles.Rate = 40
	waterParticles.Lifetime = NumberRange.new(1, 2)
	waterParticles.Speed = NumberRange.new(2, 5)
	waterParticles.SpreadAngle = Vector2.new(360, 360)
	waterParticles.Acceleration = Vector3.new(0, -2, 0) -- Slight downward drift
	waterParticles.Parent = waterAttachment
	
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
	
	local glowAura = character:FindFirstChild("BlueGlowAura")
	if glowAura then
		glowAura:Destroy()
	end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local blueLight = hrp:FindFirstChild("BlueGlowLight")
		if blueLight then
			blueLight:Destroy()
		end
		
		local waterAttachment = hrp:FindFirstChild("BlueWaterAttachment")
		if waterAttachment then
			waterAttachment:Destroy()
		end
		
		-- Clean up trail attachments
		local trailAttachment0 = hrp:FindFirstChild("BlueTrailAttachment0")
		if trailAttachment0 then
			trailAttachment0:Destroy()
		end
		
		local trailAttachment1 = hrp:FindFirstChild("BlueTrailAttachment1")
		if trailAttachment1 then
			trailAttachment1:Destroy()
		end
	end
end

local function createGreenGlowTrail(character: Model, hrp: BasePart)
	-- Remove existing effects if they exist
	local existingTrail = character:FindFirstChild("GreenGlowTrail")
	if existingTrail then
		existingTrail:Destroy()
	end
	
	local existingGlow = character:FindFirstChild("GreenGlowAura")
	if existingGlow then
		existingGlow:Destroy()
	end
	
	-- Create glow aura container
	local glowContainer = Instance.new("Model")
	glowContainer.Name = "GreenGlowAura"
	glowContainer.Parent = character
	
	-- Create green point light for glow
	local greenLight = Instance.new("PointLight")
	greenLight.Name = "GreenGlowLight"
	greenLight.Color = Color3.fromRGB(70, 200, 90) -- Green color
	greenLight.Brightness = 2.5
	greenLight.Range = 12
	greenLight.Parent = hrp
	
	-- Create attachment for leaf particles
	local leafAttachment = Instance.new("Attachment")
	leafAttachment.Name = "GreenLeafAttachment"
	leafAttachment.Parent = hrp
	
	-- Create leaf particle emitter
	local leafParticles = Instance.new("ParticleEmitter")
	leafParticles.Name = "GreenLeafParticles"
	leafParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	leafParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 139, 34)), -- Forest green
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(50, 205, 50)), -- Lime green
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(154, 205, 50)), -- Yellow green
		ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 200, 90)) -- Bright green
	})
	leafParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	leafParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	leafParticles.Rate = 50
	leafParticles.Lifetime = NumberRange.new(0.8, 1.5)
	leafParticles.Speed = NumberRange.new(2, 6)
	leafParticles.SpreadAngle = Vector2.new(360, 360)
	leafParticles.RotSpeed = NumberRange.new(-180, 180)
	leafParticles.Rotation = NumberRange.new(0, 360)
	leafParticles.Acceleration = Vector3.new(0, 1, 0) -- Slight upward drift
	leafParticles.Parent = leafAttachment
	
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
	
	local glowAura = character:FindFirstChild("GreenGlowAura")
	if glowAura then
		glowAura:Destroy()
	end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local greenLight = hrp:FindFirstChild("GreenGlowLight")
		if greenLight then
			greenLight:Destroy()
		end
		
		local leafAttachment = hrp:FindFirstChild("GreenLeafAttachment")
		if leafAttachment then
			leafAttachment:Destroy()
		end
		
		-- Clean up trail attachments
		local trailAttachment0 = hrp:FindFirstChild("GreenTrailAttachment0")
		if trailAttachment0 then
			trailAttachment0:Destroy()
		end
		
		local trailAttachment1 = hrp:FindFirstChild("GreenTrailAttachment1")
		if trailAttachment1 then
			trailAttachment1:Destroy()
		end
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
	-- Remove existing effects if they exist
	local existingTrail = character:FindFirstChild("PharaohGlowTrail")
	if existingTrail then
		existingTrail:Destroy()
	end
	
	local existingGlow = character:FindFirstChild("PharaohGlowAura")
	if existingGlow then
		existingGlow:Destroy()
	end
	
	-- Create glow aura container
	local glowContainer = Instance.new("Model")
	glowContainer.Name = "PharaohGlowAura"
	glowContainer.Parent = character
	
	-- Create attachment for sand particles
	local sandAttachment = Instance.new("Attachment")
	sandAttachment.Name = "PharaohSandAttachment"
	sandAttachment.Parent = hrp
	
	-- Create sand particle emitter
	local sandParticles = Instance.new("ParticleEmitter")
	sandParticles.Name = "PharaohSandParticles"
	sandParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	sandParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 200)), -- Light sand/beige
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 215, 0)), -- Gold
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(218, 165, 32)), -- Goldenrod
		ColorSequenceKeypoint.new(1, Color3.fromRGB(184, 134, 11)) -- Dark goldenrod
	})
	sandParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	sandParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.7, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	sandParticles.Rate = 60
	sandParticles.Lifetime = NumberRange.new(1, 2)
	sandParticles.Speed = NumberRange.new(2, 6)
	sandParticles.SpreadAngle = Vector2.new(360, 360)
	sandParticles.RotSpeed = NumberRange.new(-90, 90)
	sandParticles.Rotation = NumberRange.new(0, 360)
	sandParticles.Acceleration = Vector3.new(0, -1, 0) -- Slight downward drift like sand
	sandParticles.Parent = sandAttachment
	
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
	
	local glowAura = character:FindFirstChild("PharaohGlowAura")
	if glowAura then
		glowAura:Destroy()
	end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local sandAttachment = hrp:FindFirstChild("PharaohSandAttachment")
		if sandAttachment then
			sandAttachment:Destroy()
		end
		
		-- Clean up trail attachments
		local trailAttachment0 = hrp:FindFirstChild("PharaohTrailAttachment0")
		if trailAttachment0 then
			trailAttachment0:Destroy()
		end
		
		local trailAttachment1 = hrp:FindFirstChild("PharaohTrailAttachment1")
		if trailAttachment1 then
			trailAttachment1:Destroy()
		end
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
	-- Function to update Pharaoh glow based on equipped marble
	local function updatePharaohGlow()
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "Pharaoh" then
			createPharaohGlowTrail(character, hrp)
		else
			removePharaohGlowTrail(character)
		end
	end
	
	-- Initial check
	updatePharaohGlow()
	
	-- Monitor for marble changes
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(updatePharaohGlow)
	
	-- Also monitor PharaohGlowActive for enhanced effects when ability is active
	character:GetAttributeChangedSignal("PharaohGlowActive"):Connect(function()
		local isActive = character:GetAttribute("PharaohGlowActive")
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "Pharaoh" then
			-- Enhance sand particles when ability is active
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local sandAttachment = hrp:FindFirstChild("PharaohSandAttachment")
				if sandAttachment then
					local sandParticles = sandAttachment:FindFirstChild("PharaohSandParticles")
					if sandParticles then
						sandParticles.Rate = isActive and 100 or 60
					end
				end
			end
		end
	end)
end

local function createFlashGlowAura(character: Model, hrp: BasePart)
	-- Remove existing effects if they exist
	local existingAura = character:FindFirstChild("FlashGlowAura")
	if existingAura then
		existingAura:Destroy()
	end
	
	-- Create aura container
	local auraContainer = Instance.new("Model")
	auraContainer.Name = "FlashGlowAura"
	auraContainer.Parent = character
	
	-- Create yellow point light for glow
	local yellowLight = Instance.new("PointLight")
	yellowLight.Name = "FlashYellowLight"
	yellowLight.Color = Color3.fromRGB(255, 220, 100) -- Bright yellow
	yellowLight.Brightness = 2.5
	yellowLight.Range = 12
	yellowLight.Parent = hrp
	
	-- Create sparkle attachment
	local sparkleAttachment = Instance.new("Attachment")
	sparkleAttachment.Name = "FlashSparkleAttachment"
	sparkleAttachment.Parent = hrp
	
	-- Yellow sparkles
	local yellowSparkles = Instance.new("ParticleEmitter")
	yellowSparkles.Name = "FlashYellowSparkles"
	yellowSparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	yellowSparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)), -- Bright yellow
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 50)), -- Yellow-orange
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 0))   -- Orange
	})
	yellowSparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0.1)
	})
	yellowSparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	yellowSparkles.Rate = 50
	yellowSparkles.Lifetime = NumberRange.new(0.8, 1.5)
	yellowSparkles.Speed = NumberRange.new(1, 4)
	yellowSparkles.SpreadAngle = Vector2.new(360, 360)
	yellowSparkles.LightEmission = 1
	yellowSparkles.Parent = sparkleAttachment
	
	-- Create trail with yellow/red gradient
	local trail = Instance.new("Trail")
	trail.Name = "FlashGlowTrail"
	trail.Attachment0 = Instance.new("Attachment")
	trail.Attachment0.Name = "FlashTrailAttachment0"
	trail.Attachment0.Parent = hrp
	
	trail.Attachment1 = Instance.new("Attachment")
	trail.Attachment1.Name = "FlashTrailAttachment1"
	trail.Attachment1.Parent = hrp
	
	-- Position attachments with separation for longer trail effect
	trail.Attachment0.Position = Vector3.new(0, 1, 0)
	trail.Attachment1.Position = Vector3.new(0, -1, 0)
	
	-- Configure trail appearance with yellow/red gradient
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)), -- Bright yellow
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 200, 50)), -- Yellow-orange
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 120, 0)), -- Orange
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 0))     -- Red
	})
	trail.Transparency = NumberSequence.new(0.1, 0.95) -- More opaque at start, fade to transparent
	trail.Lifetime = 4.0 -- Trail duration
	trail.MinLength = 1.5 -- Trail length
	trail.MaxLength = 15 -- Maximum trail length
	trail.WidthScale = NumberSequence.new(0.8, 2.0) -- Trail width
	trail.FaceCamera = true -- Trail faces the camera
	trail.Parent = character
	
	return auraContainer
end

local function removeFlashGlowAura(character: Model)
	local aura = character:FindFirstChild("FlashGlowAura")
	if aura then
		aura:Destroy()
	end
	
	local trail = character:FindFirstChild("FlashGlowTrail")
	if trail then
		trail:Destroy()
	end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local yellowLight = hrp:FindFirstChild("FlashYellowLight")
		if yellowLight then
			yellowLight:Destroy()
		end
		
		local sparkleAttachment = hrp:FindFirstChild("FlashSparkleAttachment")
		if sparkleAttachment then
			sparkleAttachment:Destroy()
		end
		
		-- Clean up trail attachments
		local trailAttachment0 = hrp:FindFirstChild("FlashTrailAttachment0")
		if trailAttachment0 then
			trailAttachment0:Destroy()
		end
		
		local trailAttachment1 = hrp:FindFirstChild("FlashTrailAttachment1")
		if trailAttachment1 then
			trailAttachment1:Destroy()
		end
	end
end

local function setupFlashGlowEffect(character: Model, hrp: BasePart)
	-- Function to update Flash glow based on equipped marble
	local function updateFlashGlow()
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "Flash" then
			createFlashGlowAura(character, hrp)
		else
			removeFlashGlowAura(character)
		end
	end
	
	-- Initial check
	updateFlashGlow()
	
	-- Monitor for marble changes
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(updateFlashGlow)
	
	-- Also monitor FlashGlowActive for enhanced effects when ability is active
	character:GetAttributeChangedSignal("FlashGlowActive"):Connect(function()
		local isActive = character:GetAttribute("FlashGlowActive")
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "Flash" then
			-- Enhance effects when ability is active (increase brightness, sparkle rate, etc.)
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local yellowLight = hrp:FindFirstChild("FlashYellowLight")
				if yellowLight then
					yellowLight.Brightness = isActive and 4.0 or 2.5
					yellowLight.Range = isActive and 18 or 12
				end
				
				local sparkleAttachment = hrp:FindFirstChild("FlashSparkleAttachment")
				if sparkleAttachment then
					local yellowSparkles = sparkleAttachment:FindFirstChild("FlashYellowSparkles")
					if yellowSparkles then
						yellowSparkles.Rate = isActive and 100 or 50
					end
				end
				
				local trail = character:FindFirstChild("FlashGlowTrail")
				if trail then
					trail.Lifetime = isActive and 7.0 or 4.0
					trail.MaxLength = isActive and 25 or 15
				end
			end
		end
	end)
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

local function createPhoenixGlowAura(character: Model, hrp: BasePart)
	-- Remove existing effects if they exist
	local existingAura = character:FindFirstChild("PhoenixGlowAura")
	if existingAura then
		existingAura:Destroy()
	end
	
	-- Create aura container
	local auraContainer = Instance.new("Model")
	auraContainer.Name = "PhoenixGlowAura"
	auraContainer.Parent = character
	
	-- Create yellow point light
	local yellowLight = Instance.new("PointLight")
	yellowLight.Name = "PhoenixYellowLight"
	yellowLight.Color = Color3.fromRGB(255, 200, 0) -- Golden yellow
	yellowLight.Brightness = 2.5
	yellowLight.Range = 12
	yellowLight.Parent = hrp
	
	-- Create blue point light
	local blueLight = Instance.new("PointLight")
	blueLight.Name = "PhoenixBlueLight"
	blueLight.Color = Color3.fromRGB(100, 180, 255) -- Bright blue
	blueLight.Brightness = 2.5
	blueLight.Range = 12
	blueLight.Parent = hrp
	
	-- Create yellow sparkle attachment
	local yellowSparkleAttachment = Instance.new("Attachment")
	yellowSparkleAttachment.Name = "PhoenixYellowSparkleAttachment"
	yellowSparkleAttachment.Parent = hrp
	
	local yellowSparkles = Instance.new("ParticleEmitter")
	yellowSparkles.Name = "PhoenixYellowSparkles"
	yellowSparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	yellowSparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 0))
	})
	yellowSparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0.1)
	})
	yellowSparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	yellowSparkles.Rate = 50
	yellowSparkles.Lifetime = NumberRange.new(0.8, 1.5)
	yellowSparkles.Speed = NumberRange.new(1, 4)
	yellowSparkles.SpreadAngle = Vector2.new(360, 360)
	yellowSparkles.LightEmission = 1
	yellowSparkles.Parent = yellowSparkleAttachment
	
	-- Create blue sparkle attachment
	local blueSparkleAttachment = Instance.new("Attachment")
	blueSparkleAttachment.Name = "PhoenixBlueSparkleAttachment"
	blueSparkleAttachment.Parent = hrp
	
	local blueSparkles = Instance.new("ParticleEmitter")
	blueSparkles.Name = "PhoenixBlueSparkles"
	blueSparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	blueSparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 220, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 180, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 150, 255))
	})
	blueSparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0.1)
	})
	blueSparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	blueSparkles.Rate = 50
	blueSparkles.Lifetime = NumberRange.new(0.8, 1.5)
	blueSparkles.Speed = NumberRange.new(1, 4)
	blueSparkles.SpreadAngle = Vector2.new(360, 360)
	blueSparkles.LightEmission = 1
	blueSparkles.Parent = blueSparkleAttachment
	
	-- Create aura flame particles (subtle)
	local auraAttachment = Instance.new("Attachment")
	auraAttachment.Name = "PhoenixAuraAttachment"
	auraAttachment.Parent = hrp
	
	local auraParticles = Instance.new("ParticleEmitter")
	auraParticles.Name = "PhoenixAuraParticles"
	auraParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
	auraParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)), -- Yellow
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)), -- Golden
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(100, 180, 255)), -- Blue
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 150, 255)) -- Deep blue
	})
	auraParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	auraParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	auraParticles.Rate = 20
	auraParticles.Lifetime = NumberRange.new(1, 2)
	auraParticles.Speed = NumberRange.new(0.5, 2)
	auraParticles.SpreadAngle = Vector2.new(360, 360)
	auraParticles.LightEmission = 0.8
	auraParticles.Parent = auraAttachment
	
	-- Create left wing attachment (permanent light wings)
	local leftWingAttachment = Instance.new("Attachment")
	leftWingAttachment.Name = "PhoenixLeftWingAttachment"
	leftWingAttachment.Position = Vector3.new(-2.5, 0, 0) -- Left side
	leftWingAttachment.Parent = hrp
	
	local leftWingParticles = Instance.new("ParticleEmitter")
	leftWingParticles.Name = "PhoenixLeftWingParticles"
	leftWingParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
	leftWingParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)), -- Yellow
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)), -- Golden
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(100, 180, 255)), -- Blue
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 150, 255)) -- Deep blue
	})
	leftWingParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 1.2),
		NumberSequenceKeypoint.new(0.7, 1.5),
		NumberSequenceKeypoint.new(1, 0.3)
	})
	leftWingParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	leftWingParticles.Rate = 60
	leftWingParticles.Lifetime = NumberRange.new(0.8, 1.2)
	leftWingParticles.Speed = NumberRange.new(3, 6)
	leftWingParticles.SpreadAngle = Vector2.new(60, 45) -- Wing-like spread
	leftWingParticles.Rotation = NumberRange.new(-45, 45)
	leftWingParticles.LightEmission = 1
	leftWingParticles.Parent = leftWingAttachment
	
	-- Create right wing attachment (permanent light wings)
	local rightWingAttachment = Instance.new("Attachment")
	rightWingAttachment.Name = "PhoenixRightWingAttachment"
	rightWingAttachment.Position = Vector3.new(2.5, 0, 0) -- Right side
	rightWingAttachment.Parent = hrp
	
	local rightWingParticles = Instance.new("ParticleEmitter")
	rightWingParticles.Name = "PhoenixRightWingParticles"
	rightWingParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
	rightWingParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)), -- Yellow
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)), -- Golden
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(100, 180, 255)), -- Blue
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 150, 255)) -- Deep blue
	})
	rightWingParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 1.2),
		NumberSequenceKeypoint.new(0.7, 1.5),
		NumberSequenceKeypoint.new(1, 0.3)
	})
	rightWingParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	rightWingParticles.Rate = 60
	rightWingParticles.Lifetime = NumberRange.new(0.8, 1.2)
	rightWingParticles.Speed = NumberRange.new(3, 6)
	rightWingParticles.SpreadAngle = Vector2.new(60, 45) -- Wing-like spread
	rightWingParticles.Rotation = NumberRange.new(-45, 45)
	rightWingParticles.LightEmission = 1
	rightWingParticles.Parent = rightWingAttachment
	
	return auraContainer
end

local function removePhoenixGlowAura(character: Model)
	local aura = character:FindFirstChild("PhoenixGlowAura")
	if aura then
		aura:Destroy()
	end
	
	-- Clean up attachments and lights on HRP
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local yellowLight = hrp:FindFirstChild("PhoenixYellowLight")
		if yellowLight then
			yellowLight:Destroy()
		end
		
		local blueLight = hrp:FindFirstChild("PhoenixBlueLight")
		if blueLight then
			blueLight:Destroy()
		end
		
		local yellowSparkleAttachment = hrp:FindFirstChild("PhoenixYellowSparkleAttachment")
		if yellowSparkleAttachment then
			yellowSparkleAttachment:Destroy()
		end
		
		local blueSparkleAttachment = hrp:FindFirstChild("PhoenixBlueSparkleAttachment")
		if blueSparkleAttachment then
			blueSparkleAttachment:Destroy()
		end
		
		local auraAttachment = hrp:FindFirstChild("PhoenixAuraAttachment")
		if auraAttachment then
			auraAttachment:Destroy()
		end
		
		local leftWingAttachment = hrp:FindFirstChild("PhoenixLeftWingAttachment")
		if leftWingAttachment then
			leftWingAttachment:Destroy()
		end
		
		local rightWingAttachment = hrp:FindFirstChild("PhoenixRightWingAttachment")
		if rightWingAttachment then
			rightWingAttachment:Destroy()
		end
	end
end

local function setupPhoenixGlowEffect(character: Model, hrp: BasePart)
	-- Function to update Phoenix glow based on equipped marble
	local function updatePhoenixGlow()
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "Phoenix" then
			createPhoenixGlowAura(character, hrp)
		else
			removePhoenixGlowAura(character)
		end
	end
	
	-- Initial check
	updatePhoenixGlow()
	
	-- Monitor for marble changes
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(updatePhoenixGlow)
end

local function createSpaceRainbowEffects(character: Model, hrp: BasePart)
	-- Remove existing effects if they exist
	local existingEffects = character:FindFirstChild("SpaceRainbowEffects")
	if existingEffects then
		existingEffects:Destroy()
	end
	
	-- Create effects container
	local effectsContainer = Instance.new("Model")
	effectsContainer.Name = "SpaceRainbowEffects"
	effectsContainer.Parent = character
	
	-- Create rainbow sparkle attachment
	local sparkleAttachment = Instance.new("Attachment")
	sparkleAttachment.Name = "SpaceRainbowSparkleAttachment"
	sparkleAttachment.Parent = hrp
	
	local rainbowSparkles = Instance.new("ParticleEmitter")
	rainbowSparkles.Name = "SpaceRainbowSparkles"
	rainbowSparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	rainbowSparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), -- Red
		ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 127, 0)), -- Orange
		ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 255, 0)), -- Yellow
		ColorSequenceKeypoint.new(0.42, Color3.fromRGB(0, 255, 0)), -- Green
		ColorSequenceKeypoint.new(0.57, Color3.fromRGB(0, 0, 255)), -- Blue
		ColorSequenceKeypoint.new(0.71, Color3.fromRGB(75, 0, 130)), -- Indigo
		ColorSequenceKeypoint.new(0.85, Color3.fromRGB(148, 0, 211)), -- Violet
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) -- Back to red
	})
	rainbowSparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	rainbowSparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	rainbowSparkles.Rate = 80
	rainbowSparkles.Lifetime = NumberRange.new(0.8, 1.5)
	rainbowSparkles.Speed = NumberRange.new(2, 6)
	rainbowSparkles.SpreadAngle = Vector2.new(360, 360)
	rainbowSparkles.LightEmission = 1
	rainbowSparkles.Parent = sparkleAttachment
	
	-- Create rainbow trail
	local trail = Instance.new("Trail")
	trail.Name = "SpaceRainbowTrail"
	trail.Attachment0 = Instance.new("Attachment")
	trail.Attachment0.Name = "SpaceTrailAttachment0"
	trail.Attachment0.Parent = hrp
	
	trail.Attachment1 = Instance.new("Attachment")
	trail.Attachment1.Name = "SpaceTrailAttachment1"
	trail.Attachment1.Parent = hrp
	
	-- Position attachments
	trail.Attachment0.Position = Vector3.new(0, 1, 0)
	trail.Attachment1.Position = Vector3.new(0, -1, 0)
	
	-- Configure rainbow trail appearance
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), -- Red
		ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 127, 0)), -- Orange
		ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 255, 0)), -- Yellow
		ColorSequenceKeypoint.new(0.42, Color3.fromRGB(0, 255, 0)), -- Green
		ColorSequenceKeypoint.new(0.57, Color3.fromRGB(0, 0, 255)), -- Blue
		ColorSequenceKeypoint.new(0.71, Color3.fromRGB(75, 0, 130)), -- Indigo
		ColorSequenceKeypoint.new(0.85, Color3.fromRGB(148, 0, 211)), -- Violet
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) -- Back to red
	})
	trail.Transparency = NumberSequence.new(0.1, 0.8)
	trail.Lifetime = 3.0
	trail.MinLength = 2.0
	trail.MaxLength = 25
	trail.WidthScale = NumberSequence.new(0.8, 2.5)
	trail.FaceCamera = true
	trail.Parent = character
	
	-- Create rainbow point light
	local rainbowLight = Instance.new("PointLight")
	rainbowLight.Name = "SpaceRainbowLight"
	rainbowLight.Color = Color3.fromRGB(255, 100, 255) -- Magenta/pink for rainbow effect
	rainbowLight.Brightness = 2
	rainbowLight.Range = 10
	rainbowLight.Parent = hrp
	
	-- Create rainbow glow aura attachment
	local glowAttachment = Instance.new("Attachment")
	glowAttachment.Name = "SpaceRainbowGlowAttachment"
	glowAttachment.Parent = hrp
	
	local rainbowGlow = Instance.new("ParticleEmitter")
	rainbowGlow.Name = "SpaceRainbowGlow"
	rainbowGlow.Texture = "rbxasset://textures/particles/fire_main.dds"
	rainbowGlow.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), -- Red
		ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 127, 0)), -- Orange
		ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 255, 0)), -- Yellow
		ColorSequenceKeypoint.new(0.42, Color3.fromRGB(0, 255, 0)), -- Green
		ColorSequenceKeypoint.new(0.57, Color3.fromRGB(0, 0, 255)), -- Blue
		ColorSequenceKeypoint.new(0.71, Color3.fromRGB(75, 0, 130)), -- Indigo
		ColorSequenceKeypoint.new(0.85, Color3.fromRGB(148, 0, 211)), -- Violet
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) -- Back to red
	})
	rainbowGlow.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 1.5),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	rainbowGlow.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	rainbowGlow.Rate = 100
	rainbowGlow.Lifetime = NumberRange.new(1, 2)
	rainbowGlow.Speed = NumberRange.new(0.5, 2)
	rainbowGlow.SpreadAngle = Vector2.new(360, 360)
	rainbowGlow.LightEmission = 1
	rainbowGlow.Parent = glowAttachment
	
	return effectsContainer
end

local function removeSpaceRainbowEffects(character: Model)
	local effects = character:FindFirstChild("SpaceRainbowEffects")
	if effects then
		effects:Destroy()
	end
	
	-- Clean up attachments and lights on HRP
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local sparkleAttachment = hrp:FindFirstChild("SpaceRainbowSparkleAttachment")
		if sparkleAttachment then
			sparkleAttachment:Destroy()
		end
		
		local rainbowLight = hrp:FindFirstChild("SpaceRainbowLight")
		if rainbowLight then
			rainbowLight:Destroy()
		end
		
		local glowAttachment = hrp:FindFirstChild("SpaceRainbowGlowAttachment")
		if glowAttachment then
			glowAttachment:Destroy()
		end
	end
	
	-- Clean up trail
	local trail = character:FindFirstChild("SpaceRainbowTrail")
	if trail then
		trail:Destroy()
	end
end

local function setupSpaceRainbowEffect(character: Model, hrp: BasePart)
	-- Function to update Space rainbow effects based on equipped marble
	local function updateSpaceRainbow()
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "Space" then
			createSpaceRainbowEffects(character, hrp)
		else
			removeSpaceRainbowEffects(character)
		end
	end
	
	-- Initial check
	updateSpaceRainbow()
	
	-- Monitor for marble changes
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(updateSpaceRainbow)
end

local function createDiamondRainbowEffects(character: Model, hrp: BasePart)
	-- Remove existing effects if they exist
	local existingEffects = character:FindFirstChild("DiamondRainbowEffects")
	if existingEffects then
		existingEffects:Destroy()
	end
	
	-- Create effects container
	local effectsContainer = Instance.new("Model")
	effectsContainer.Name = "DiamondRainbowEffects"
	effectsContainer.Parent = character
	
	-- Create rainbow sparkle attachment
	local sparkleAttachment = Instance.new("Attachment")
	sparkleAttachment.Name = "DiamondRainbowSparkleAttachment"
	sparkleAttachment.Parent = hrp
	
	local rainbowSparkles = Instance.new("ParticleEmitter")
	rainbowSparkles.Name = "DiamondRainbowSparkles"
	rainbowSparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	rainbowSparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), -- Red
		ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 127, 0)), -- Orange
		ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 255, 0)), -- Yellow
		ColorSequenceKeypoint.new(0.42, Color3.fromRGB(0, 255, 0)), -- Green
		ColorSequenceKeypoint.new(0.57, Color3.fromRGB(0, 0, 255)), -- Blue
		ColorSequenceKeypoint.new(0.71, Color3.fromRGB(75, 0, 130)), -- Indigo
		ColorSequenceKeypoint.new(0.85, Color3.fromRGB(148, 0, 211)), -- Violet
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) -- Back to red
	})
	rainbowSparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	rainbowSparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	rainbowSparkles.Rate = 100 -- More sparkles for Diamond
	rainbowSparkles.Lifetime = NumberRange.new(0.8, 1.5)
	rainbowSparkles.Speed = NumberRange.new(2, 6)
	rainbowSparkles.SpreadAngle = Vector2.new(360, 360)
	rainbowSparkles.LightEmission = 1
	rainbowSparkles.Parent = sparkleAttachment
	
	-- Create rainbow trail
	local trail = Instance.new("Trail")
	trail.Name = "DiamondRainbowTrail"
	trail.Attachment0 = Instance.new("Attachment")
	trail.Attachment0.Name = "DiamondTrailAttachment0"
	trail.Attachment0.Parent = hrp
	
	trail.Attachment1 = Instance.new("Attachment")
	trail.Attachment1.Name = "DiamondTrailAttachment1"
	trail.Attachment1.Parent = hrp
	
	-- Position attachments
	trail.Attachment0.Position = Vector3.new(0, 1, 0)
	trail.Attachment1.Position = Vector3.new(0, -1, 0)
	
	-- Configure rainbow trail appearance
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), -- Red
		ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 127, 0)), -- Orange
		ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 255, 0)), -- Yellow
		ColorSequenceKeypoint.new(0.42, Color3.fromRGB(0, 255, 0)), -- Green
		ColorSequenceKeypoint.new(0.57, Color3.fromRGB(0, 0, 255)), -- Blue
		ColorSequenceKeypoint.new(0.71, Color3.fromRGB(75, 0, 130)), -- Indigo
		ColorSequenceKeypoint.new(0.85, Color3.fromRGB(148, 0, 211)), -- Violet
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) -- Back to red
	})
	trail.Transparency = NumberSequence.new(0.1, 0.8)
	trail.Lifetime = 4.0 -- Longer trail for Diamond
	trail.MinLength = 2.0
	trail.MaxLength = 30 -- Longer max length
	trail.WidthScale = NumberSequence.new(1.0, 3.0) -- Wider trail
	trail.FaceCamera = true
	trail.Parent = character
	
	-- Create rainbow point light
	local rainbowLight = Instance.new("PointLight")
	rainbowLight.Name = "DiamondRainbowLight"
	rainbowLight.Color = Color3.fromRGB(255, 100, 255) -- Magenta/pink for rainbow effect
	rainbowLight.Brightness = 3.0 -- Brighter for Diamond
	rainbowLight.Range = 15 -- Larger range
	rainbowLight.Parent = hrp
	
	-- Create rainbow glow aura attachment
	local glowAttachment = Instance.new("Attachment")
	glowAttachment.Name = "DiamondRainbowGlowAttachment"
	glowAttachment.Parent = hrp
	
	local rainbowGlow = Instance.new("ParticleEmitter")
	rainbowGlow.Name = "DiamondRainbowGlow"
	rainbowGlow.Texture = "rbxasset://textures/particles/fire_main.dds"
	rainbowGlow.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), -- Red
		ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 127, 0)), -- Orange
		ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 255, 0)), -- Yellow
		ColorSequenceKeypoint.new(0.42, Color3.fromRGB(0, 255, 0)), -- Green
		ColorSequenceKeypoint.new(0.57, Color3.fromRGB(0, 0, 255)), -- Blue
		ColorSequenceKeypoint.new(0.71, Color3.fromRGB(75, 0, 130)), -- Indigo
		ColorSequenceKeypoint.new(0.85, Color3.fromRGB(148, 0, 211)), -- Violet
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) -- Back to red
	})
	rainbowGlow.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.0),
		NumberSequenceKeypoint.new(0.5, 2.0),
		NumberSequenceKeypoint.new(1, 0.8)
	})
	rainbowGlow.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})
	rainbowGlow.Rate = 120 -- More particles for Diamond
	rainbowGlow.Lifetime = NumberRange.new(1, 2)
	rainbowGlow.Speed = NumberRange.new(0.5, 2)
	rainbowGlow.SpreadAngle = Vector2.new(360, 360)
	rainbowGlow.LightEmission = 1
	rainbowGlow.Parent = glowAttachment
	
	return effectsContainer
end

local function removeDiamondRainbowEffects(character: Model)
	local effects = character:FindFirstChild("DiamondRainbowEffects")
	if effects then
		effects:Destroy()
	end
	
	-- Clean up attachments and lights on HRP
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local sparkleAttachment = hrp:FindFirstChild("DiamondRainbowSparkleAttachment")
		if sparkleAttachment then
			sparkleAttachment:Destroy()
		end
		
		local rainbowLight = hrp:FindFirstChild("DiamondRainbowLight")
		if rainbowLight then
			rainbowLight:Destroy()
		end
		
		local glowAttachment = hrp:FindFirstChild("DiamondRainbowGlowAttachment")
		if glowAttachment then
			glowAttachment:Destroy()
		end
		
		-- Clean up trail attachments
		local trailAttachment0 = hrp:FindFirstChild("DiamondTrailAttachment0")
		if trailAttachment0 then
			trailAttachment0:Destroy()
		end
		
		local trailAttachment1 = hrp:FindFirstChild("DiamondTrailAttachment1")
		if trailAttachment1 then
			trailAttachment1:Destroy()
		end
	end
	
	-- Clean up trail
	local trail = character:FindFirstChild("DiamondRainbowTrail")
	if trail then
		trail:Destroy()
	end
end

local function setupDiamondRainbowEffect(character: Model, hrp: BasePart)
	-- Function to update Diamond rainbow effects based on equipped marble
	local function updateDiamondRainbow()
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "Diamond" then
			createDiamondRainbowEffects(character, hrp)
		else
			removeDiamondRainbowEffects(character)
		end
	end
	
	-- Initial check
	updateDiamondRainbow()
	
	-- Monitor for marble changes
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(updateDiamondRainbow)
end

local function create67RainbowTrail(character: Model, hrp: BasePart)
	-- Remove existing trail if it exists
	local existingTrail = character:FindFirstChild("67RainbowTrail")
	if existingTrail then
		existingTrail:Destroy()
	end
	
	-- Create rainbow trail positioned behind the marble
	local trail = Instance.new("Trail")
	trail.Name = "67RainbowTrail"
	trail.Attachment0 = Instance.new("Attachment")
	trail.Attachment0.Name = "67TrailAttachment0"
	trail.Attachment0.Parent = hrp
	
	trail.Attachment1 = Instance.new("Attachment")
	trail.Attachment1.Name = "67TrailAttachment1"
	trail.Attachment1.Parent = hrp
	
	-- Position attachments behind the marble (negative Z)
	trail.Attachment0.Position = Vector3.new(0, 1, -1.5)
	trail.Attachment1.Position = Vector3.new(0, -1, -1.5)
	
	-- Configure rainbow trail appearance
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), -- Red
		ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 127, 0)), -- Orange
		ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 255, 0)), -- Yellow
		ColorSequenceKeypoint.new(0.42, Color3.fromRGB(0, 255, 0)), -- Green
		ColorSequenceKeypoint.new(0.57, Color3.fromRGB(0, 0, 255)), -- Blue
		ColorSequenceKeypoint.new(0.71, Color3.fromRGB(75, 0, 130)), -- Indigo
		ColorSequenceKeypoint.new(0.85, Color3.fromRGB(148, 0, 211)), -- Violet
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) -- Back to red
	})
	trail.Transparency = NumberSequence.new(0.1, 0.8)
	trail.Lifetime = 4.0
	trail.MinLength = 2.0
	trail.MaxLength = 25
	trail.WidthScale = NumberSequence.new(0.8, 2.5)
	trail.FaceCamera = true
	trail.Parent = character
	
	return trail
end

local function remove67RainbowTrail(character: Model)
	local trail = character:FindFirstChild("67RainbowTrail")
	if trail then
		trail:Destroy()
	end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		-- Clean up trail attachments
		local trailAttachment0 = hrp:FindFirstChild("67TrailAttachment0")
		if trailAttachment0 then
			trailAttachment0:Destroy()
		end
		
		local trailAttachment1 = hrp:FindFirstChild("67TrailAttachment1")
		if trailAttachment1 then
			trailAttachment1:Destroy()
		end
	end
end

local function setup67RainbowTrail(character: Model, hrp: BasePart)
	-- Function to update 67 rainbow trail based on equipped marble
	local function update67RainbowTrail()
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "67" then
			create67RainbowTrail(character, hrp)
		else
			remove67RainbowTrail(character)
		end
	end
	
	-- Initial check
	update67RainbowTrail()
	
	-- Monitor for marble changes
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(update67RainbowTrail)
end

local function createHackerBlackGreenEffects(character: Model, hrp: BasePart)
	-- Remove existing effects if they exist
	local existingEffects = character:FindFirstChild("HackerBlackGreenEffects")
	if existingEffects then
		existingEffects:Destroy()
	end
	
	-- Create effects container
	local effectsContainer = Instance.new("Model")
	effectsContainer.Name = "HackerBlackGreenEffects"
	effectsContainer.Parent = character
	
	-- Create black and green sparkle attachment
	local sparkleAttachment = Instance.new("Attachment")
	sparkleAttachment.Name = "HackerSparkleAttachment"
	sparkleAttachment.Parent = hrp
	
	local hackerSparkles = Instance.new("ParticleEmitter")
	hackerSparkles.Name = "HackerSparkles"
	hackerSparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	hackerSparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)), -- Bright green
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 200, 0)), -- Medium green
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)) -- Black
	})
	hackerSparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	hackerSparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	hackerSparkles.Rate = 70
	hackerSparkles.Lifetime = NumberRange.new(0.8, 1.5)
	hackerSparkles.Speed = NumberRange.new(2, 6)
	hackerSparkles.SpreadAngle = Vector2.new(360, 360)
	hackerSparkles.LightEmission = 1
	hackerSparkles.Parent = sparkleAttachment
	
	-- Create black and green trail
	local trail = Instance.new("Trail")
	trail.Name = "HackerBlackGreenTrail"
	trail.Attachment0 = Instance.new("Attachment")
	trail.Attachment0.Name = "HackerTrailAttachment0"
	trail.Attachment0.Parent = hrp
	
	trail.Attachment1 = Instance.new("Attachment")
	trail.Attachment1.Name = "HackerTrailAttachment1"
	trail.Attachment1.Parent = hrp
	
	-- Position attachments
	trail.Attachment0.Position = Vector3.new(0, 1, 0)
	trail.Attachment1.Position = Vector3.new(0, -1, 0)
	
	-- Configure black and green trail appearance
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)), -- Bright green
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 150, 0)), -- Dark green
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)) -- Black
	})
	trail.Transparency = NumberSequence.new(0.1, 0.8)
	trail.Lifetime = 2.5
	trail.MinLength = 1.5
	trail.MaxLength = 20
	trail.WidthScale = NumberSequence.new(0.8, 2.0)
	trail.FaceCamera = true
	trail.Parent = character
	
	-- Create black and green glow
	local glowAttachment = Instance.new("Attachment")
	glowAttachment.Name = "HackerGlowAttachment"
	glowAttachment.Parent = hrp
	
	local hackerGlow = Instance.new("ParticleEmitter")
	hackerGlow.Name = "HackerGlow"
	hackerGlow.Texture = "rbxasset://textures/particles/fire_main.dds"
	hackerGlow.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)), -- Bright green
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 150, 0)), -- Medium green
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)) -- Black
	})
	hackerGlow.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.5, 1.2),
		NumberSequenceKeypoint.new(1, 0.4)
	})
	hackerGlow.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	hackerGlow.Rate = 80
	hackerGlow.Lifetime = NumberRange.new(1, 2)
	hackerGlow.Speed = NumberRange.new(0.5, 2)
	hackerGlow.SpreadAngle = Vector2.new(360, 360)
	hackerGlow.LightEmission = 1
	hackerGlow.Parent = glowAttachment
	
	-- Create green point light
	local greenLight = Instance.new("PointLight")
	greenLight.Name = "HackerGreenLight"
	greenLight.Color = Color3.fromRGB(0, 255, 0) -- Bright green
	greenLight.Brightness = 2.5
	greenLight.Range = 10
	greenLight.Parent = hrp
	
	return effectsContainer
end

local function removeHackerBlackGreenEffects(character: Model)
	local effects = character:FindFirstChild("HackerBlackGreenEffects")
	if effects then
		effects:Destroy()
	end
	
	-- Clean up attachments and lights on HRP
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local sparkleAttachment = hrp:FindFirstChild("HackerSparkleAttachment")
		if sparkleAttachment then
			sparkleAttachment:Destroy()
		end
		
		local glowAttachment = hrp:FindFirstChild("HackerGlowAttachment")
		if glowAttachment then
			glowAttachment:Destroy()
		end
		
		local greenLight = hrp:FindFirstChild("HackerGreenLight")
		if greenLight then
			greenLight:Destroy()
		end
	end
	
	-- Clean up trail
	local trail = character:FindFirstChild("HackerBlackGreenTrail")
	if trail then
		trail:Destroy()
	end
end

local function setupHackerBlackGreenEffect(character: Model, hrp: BasePart)
	-- Function to update Hacker black/green effects based on equipped marble
	local function updateHackerEffects()
		local equippedId = character:GetAttribute("EquippedMarbleId")
		if equippedId == "Hacker" then
			createHackerBlackGreenEffects(character, hrp)
		else
			removeHackerBlackGreenEffects(character)
		end
	end
	
	-- Initial check
	updateHackerEffects()
	
	-- Monitor for marble changes
	character:GetAttributeChangedSignal("EquippedMarbleId"):Connect(updateHackerEffects)
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
		Castle = "rbxassetid://136095563046974", -- Castle texture
		Phoenix = "rbxassetid://124481451788068", -- Phoenix texture
		Space = "rbxassetid://119305575673092", -- Space texture
		Hacker = "rbxassetid://115836576619858", -- Hacker texture
		Flash = "rbxassetid://105677188379071", -- Flash texture
		["67"] = "rbxassetid://93952266843954", -- 67 texture
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
local nameplateTweens: { [Model]: { [string]: Tween } } = {}

local function setupEnhancedNameplate(character: Model)
	local gui = character:FindFirstChild("Nameplate")
	if not gui or not gui:IsA("BillboardGui") then return end
	
	local label = gui:FindFirstChild("Label")
	if not label or not label:IsA("TextLabel") then return end
	
	-- Clean up all existing tweens for this character
	if nameplateTweens[character] then
		for _, tween in pairs(nameplateTweens[character]) do
			if tween then
				tween:Cancel()
			end
		end
		nameplateTweens[character] = {}
	end
	
	-- Function to apply rarity-based styling
	local function applyRarityStyling()
		-- Clean up all existing effects and tweens first
		local effectsToRemove = {"RarityGlow", "RainbowGlow", "EpicStar", "RareDiamond", "LegendarySparkle", "UncommonLeaf"}
		for _, effectName in ipairs(effectsToRemove) do
			local existingEffect = gui:FindFirstChild(effectName)
			if existingEffect then
				existingEffect:Destroy()
			end
		end
		
		-- Cancel any existing tweens on the gui and label
		if nameplateTweens[character] then
			for _, tween in pairs(nameplateTweens[character]) do
				if tween then
					tween:Cancel()
				end
			end
			nameplateTweens[character] = {}
		end
		
		-- Reset gui and label properties to defaults
		local baseSize = UDim2.fromOffset(180, 36)
		gui.Size = baseSize
		gui.StudsOffset = Vector3.new(0, 3.5, 0)
		label.Size = UDim2.fromScale(1, 1)
		
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
		gui.Size = UDim2.fromOffset(180 * rarityScale, 36 * rarityScale)
		
		-- Add subtle floating animation for epic+ rarities
		if rarityTier == "Epic" or rarityTier == "Legendary" then
			local originalOffset = gui.StudsOffset
			local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local floatTween = game:GetService("TweenService"):Create(gui, tweenInfo, {
				StudsOffset = Vector3.new(originalOffset.X, originalOffset.Y + 0.3, originalOffset.Z)
			})
			floatTween:Play()
			if not nameplateTweens[character] then
				nameplateTweens[character] = {}
			end
			nameplateTweens[character]["float"] = floatTween
		end
		
		-- Add text scaling animation for legendary marbles
		if rarityTier == "Legendary" then
			local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local scaleTween = game:GetService("TweenService"):Create(label, tweenInfo, {
				Size = UDim2.fromScale(1.05, 1.05)
			})
			scaleTween:Play()
			if not nameplateTweens[character] then
				nameplateTweens[character] = {}
			end
			nameplateTweens[character]["scale"] = scaleTween
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
				if not nameplateTweens[character] then
					nameplateTweens[character] = {}
				end
				nameplateTweens[character]["glow"] = tween
			end
			
			-- Add rainbow effect for legendary marbles
			if rarityTier == "Legendary" then
				local rainbowTween = game:GetService("TweenService"):Create(glow, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
					TextColor3 = Color3.fromRGB(255, 100, 100)
				})
				rainbowTween:Play()
				if not nameplateTweens[character] then
					nameplateTweens[character] = {}
				end
				nameplateTweens[character]["rainbow1"] = rainbowTween
				
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
				nameplateTweens[character]["rainbow2"] = rainbowTween2
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
			if not nameplateTweens[character] then
				nameplateTweens[character] = {}
			end
			nameplateTweens[character]["star"] = tween
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
			if not nameplateTweens[character] then
				nameplateTweens[character] = {}
			end
			nameplateTweens[character]["diamond"] = tween
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
			if not nameplateTweens[character] then
				nameplateTweens[character] = {}
			end
			nameplateTweens[character]["leaf"] = tween
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
			if not nameplateTweens[character] then
				nameplateTweens[character] = {}
			end
			nameplateTweens[character]["sparkle"] = tween
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
	
	-- Clean up tweens when character is removed
	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			if nameplateTweens[character] then
				for _, tween in pairs(nameplateTweens[character]) do
					if tween then
						tween:Cancel()
					end
				end
				nameplateTweens[character] = nil
			end
		end
	end)
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
	
	-- Disable Humanoid's automatic jumping - we handle jumps manually via velocity
	if hum then
		hum.UseJumpPower = false
		hum.JumpPower = 0
		hum.JumpHeight = 0
		print("[MarbleClient] Disabled Humanoid automatic jumping")
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
	setupFlashGlowEffect(character, hrp)
	setupDiamondRainbowEffect(character, hrp)
	setup67RainbowTrail(character, hrp)
	setupTsunamiWaterGlowEffect(character, hrp)
	setupMeteorFireEffect(character, hrp)
	setupPhoenixGlowEffect(character, hrp)
	setupSpaceRainbowEffect(character, hrp)
	setupHackerBlackGreenEffect(character, hrp)
	
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
	
	local function shouldApplyLaunch(): boolean
		local launchActive = character:GetAttribute("LaunchActive")
		return typeof(launchActive) == "boolean" and launchActive
	end
	
	local function shouldApplyMoonGravity(): boolean
		local moonGravity = character:GetAttribute("MoonGravityActive")
		return typeof(moonGravity) == "boolean" and moonGravity
	end
	

	local logAccum = 0
	local prevIsInput = false
	local glideHoriz = Vector3.zero
	local jumpStuckTimer = 0 -- Track how long jump has been active while on ground and moving
	local lastJumpState = false -- Track jump state for safeguard
	local lastYVelocity = 0 -- Track previous Y velocity to detect unexpected changes
	local lastJumpInput = false -- Track previous jump input state
	local jumpCooldown = 0 -- Cooldown to prevent jump spam
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
		
		-- Track unexpected Y velocity changes (check BEFORE we modify velocity)
		local yVelChange = currentVel.Y - lastYVelocity
		if math.abs(yVelChange) > 5 and yVelChange > 0 then -- Significant upward velocity change
			local jumpBoostActive = character:GetAttribute("JumpBoostActive")
			local launchActive = character:GetAttribute("LaunchActive")
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local isOnGround = humanoid and humanoid.FloorMaterial ~= Enum.Material.Air or false
			local humanoidJump = humanoid and humanoid.Jump or false
			
			-- If this is an unexpected jump, try to cancel it
			-- Allow launches from launch pads (LaunchActive attribute)
			if not jumpBoostActive and not launchActive and not humanoidJump and not inputState.jump then
				hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, math.min(currentVel.Y, 0), currentVel.Z) -- Clamp to 0 or negative
			end
		end

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
		
		-- Manual jump system: Handle spacebar and jump button input
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local isOnGround = humanoid.FloorMaterial ~= Enum.Material.Air
			local velBeforeJump = hrp.AssemblyLinearVelocity
			-- More lenient check: only consider it "jumping upward" if velocity is significantly upward (like from an actual jump)
			-- Increased threshold to allow jumps on inclines where small upward velocity is normal
			local isJumpingUpward = velBeforeJump.Y > 20 -- Higher threshold to allow jumps on inclines
			
			-- Check for jump input from spacebar, mobile button, or Humanoid.Jump
			local humanoidJump = humanoid.Jump
			local currentJumpInput = inputState.jump or humanoidJump
			
			-- Update jump cooldown
			if jumpCooldown > 0 then
				jumpCooldown = jumpCooldown - dt
			end
			
			-- Detect jump button press (transition from false to true)
			if currentJumpInput and not lastJumpInput and jumpCooldown <= 0 then
				-- User just pressed jump button
				-- Allow jump if on ground, even with small upward velocity (for inclines)
				-- Only block if already in a significant jump (velocity > 20)
				if isOnGround and not isJumpingUpward then
					-- Apply jump force
					local jumpForce = 75 -- 1.5x higher jump (was 50)
					hrp.AssemblyLinearVelocity = Vector3.new(velBeforeJump.X, jumpForce, velBeforeJump.Z)
					wrote = true
					lastYVelocity = jumpForce
					jumpCooldown = 0.1 -- Small cooldown to prevent spam
				end
			end
			lastJumpInput = currentJumpInput
			
			-- Reset Humanoid.Jump after processing to prevent it from interfering
			if humanoidJump then
				humanoid.Jump = false
			end
		end
		
		-- Apply jump boost if active (ability-based jump)
		if shouldApplyJumpBoost() then
			-- Apply upward velocity boost for jump/launch effect
			local jumpForce = 75 -- 1.5x higher jump (was 50)
			local newVel = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(newVel.X, jumpForce, newVel.Z)
			wrote = true
			lastYVelocity = jumpForce -- Update tracked velocity
		elseif shouldApplyLaunch() then
			-- Apply launch pad force (multiplied by launch number)
			local launchForce = character:GetAttribute("LaunchForce")
			-- Default to base jump force if LaunchForce attribute is not set
			if typeof(launchForce) ~= "number" or launchForce <= 0 then
				launchForce = 75 -- Fallback to base jump force
			end
			local newVel = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(newVel.X, launchForce, newVel.Z)
			wrote = true
			lastYVelocity = launchForce -- Update tracked velocity
		else
			-- Update lastYVelocity after all our modifications
			if not currentJumpInput or not isOnGround then
				lastYVelocity = hrp.AssemblyLinearVelocity.Y
			end
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
				lastYVelocity = newYVel -- Update tracked velocity
			end
		end
		
		-- Update lastYVelocity at the end of the frame if we didn't modify it
		if not shouldApplyJumpBoost() and not shouldApplyLaunch() then
			lastYVelocity = hrp.AssemblyLinearVelocity.Y
		end
		
		-- Logging and monitoring (humanoid already processed above)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local currentVel = hrp.AssemblyLinearVelocity
			local isJumpingUpward = currentVel.Y > 20 -- Increased threshold to match jump logic (allows jumps on inclines)
			local isOnGround = humanoid.FloorMaterial ~= Enum.Material.Air
			
			-- Track jump state for safeguard
			local currentJumpState = humanoid.Jump
			if currentJumpState ~= lastJumpState then
				if currentJumpState then
					-- Jump button was just pressed
					local userPressedJump = inputState.jump
					local jumpBoostActive = character:GetAttribute("JumpBoostActive")
					
					-- SAFEGUARD: If humanoid.Jump is true but user didn't press spacebar, block it
					if not userPressedJump and not jumpBoostActive then
						humanoid.Jump = false
						currentJumpState = false
					end
				end
			end
			lastJumpState = currentJumpState
			
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
	
	-- Setup FlashGlowTrail effect
	setupFlashGlowEffect(character, hrp)
	
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
	setupFlashGlowEffect(character, hrp)
	setupDiamondRainbowEffect(character, hrp)
	setup67RainbowTrail(character, hrp)
	setupTsunamiWaterGlowEffect(character, hrp)
	setupMeteorFireEffect(character, hrp)
	setupPhoenixGlowEffect(character, hrp)
	setupSpaceRainbowEffect(character, hrp)
	setupHackerBlackGreenEffect(character, hrp)
	
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

-- Create custom jump button UI (only for mobile/touch devices)
local function createJumpButton()
	-- Check if device is mobile/touch
	local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local isGamepadDevice = UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled
	
	-- Only create button for touch or gamepad devices (not PC with keyboard/mouse)
	if not isTouchDevice and not isGamepadDevice then
		return
	end
	
	-- Determine button size based on device type
	local buttonSize = 120 -- Default size for gamepad
	if isTouchDevice then
		-- Get screen size to scale button appropriately
		local camera = workspace.CurrentCamera
		local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
		local screenWidth = viewportSize.X
		
		-- Scale button size based on screen width (larger screens get larger buttons)
		-- Minimum 140px, maximum 180px, scales with screen width
		buttonSize = math.clamp(screenWidth * 0.08, 140, 180)
	end
	
	-- Create ScreenGui for jump button
	jumpButtonGui = Instance.new("ScreenGui")
	jumpButtonGui.Name = "CustomJumpButton"
	jumpButtonGui.ResetOnSpawn = false
	jumpButtonGui.IgnoreGuiInset = true
	jumpButtonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	jumpButtonGui.Parent = playerGui
	
	-- Create the jump button
	jumpButton = Instance.new("ImageButton")
	jumpButton.Name = "JumpButton"
	jumpButton.Size = UDim2.new(0, buttonSize, 0, buttonSize) -- Dynamic size based on device
	-- Position scales with button size to maintain proper spacing
	local offsetX = math.max(145, buttonSize / 2 + 85) -- Ensure minimum spacing from right edge
	local offsetY = math.max(70, buttonSize / 2 + 20) -- Ensure minimum spacing from bottom edge
	jumpButton.Position = UDim2.new(1, -offsetX, 1, -offsetY) -- Bottom right, moved left to avoid nuke button
	jumpButton.AnchorPoint = Vector2.new(0.5, 0.5)
	jumpButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Same as Roll for Marble
	jumpButton.BackgroundTransparency = 0.4 -- Same as Roll for Marble
	jumpButton.BorderSizePixel = 0
	jumpButton.Parent = jumpButtonGui
	
	-- Add rounded corners (fully circular)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, buttonSize / 2) -- Fully circular based on button size
	corner.Parent = jumpButton
	
	-- Add jump icon (upward arrow)
	local jumpIcon = Instance.new("TextLabel")
	jumpIcon.Name = "JumpIcon"
	jumpIcon.Size = UDim2.new(1, -20, 1, -20)
	jumpIcon.Position = UDim2.new(0, 10, 0, 10)
	jumpIcon.BackgroundTransparency = 1
	jumpIcon.Text = "↑" -- Upward arrow
	jumpIcon.TextScaled = true
	jumpIcon.TextColor3 = Color3.new(1, 1, 1)
	jumpIcon.Font = Enum.Font.GothamBold
	jumpIcon.Parent = jumpButton
	
	-- Add shadow/glow effect
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 10, 1, 10)
	shadow.Position = UDim2.new(0, -5, 0, -5)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.7
	shadow.BorderSizePixel = 0
	shadow.ZIndex = jumpButton.ZIndex - 1
	shadow.Parent = jumpButton
	
	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, (buttonSize / 2) + 5) -- Slightly larger than button corner
	shadowCorner.Parent = shadow
	
	-- Add stroke for better visibility (scales with button size)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = math.max(2, buttonSize / 40) -- Scales proportionally (min 2px)
	stroke.Transparency = 0.3
	stroke.Parent = jumpButton
	
	-- Button press animation (scales to 83% of original size)
	local function animatePress()
		local pressedSize = math.floor(buttonSize * 0.83)
		local pressTween = TweenService:Create(jumpButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, pressedSize, 0, pressedSize)
		})
		pressTween:Play()
		pressTween.Completed:Connect(function()
			local releaseTween = TweenService:Create(jumpButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, buttonSize, 0, buttonSize)
			})
			releaseTween:Play()
		end)
	end
	
	-- Track button state
	local isButtonPressed = false
	
	-- Function to handle button press
	local function onButtonPress()
		if isButtonPressed then return end
		isButtonPressed = true
		animatePress()
		inputState.jump = true
		
		-- Visual feedback: brighten the button
		jumpButton.BackgroundTransparency = 0
		jumpIcon.TextColor3 = Color3.fromRGB(255, 255, 150) -- Yellow when pressed
	end
	
	-- Function to handle button release
	local function onButtonRelease()
		if not isButtonPressed then return end
		isButtonPressed = false
		inputState.jump = false
		
		-- Visual feedback: return to normal
		jumpButton.BackgroundTransparency = 0.4
		jumpIcon.TextColor3 = Color3.new(1, 1, 1) -- White when released
	end
	
	-- Connect button events (mouse)
	jumpButton.MouseButton1Down:Connect(onButtonPress)
	jumpButton.MouseButton1Up:Connect(onButtonRelease)
	jumpButton.MouseLeave:Connect(onButtonRelease)
	
	-- Connect touch events (mobile)
	jumpButton.TouchTap:Connect(function()
		onButtonPress()
		task.wait(0.1) -- Brief delay for visual feedback
		onButtonRelease()
	end)
	
	-- Add hover effect (desktop only)
	jumpButton.MouseEnter:Connect(function()
		if not isButtonPressed then
			local hoverTween = TweenService:Create(jumpButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.3
			})
			hoverTween:Play()
		end
	end)
	
	jumpButton.MouseLeave:Connect(function()
		if not isButtonPressed then
			local leaveTween = TweenService:Create(jumpButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.4
			})
			leaveTween:Play()
		end
	end)
	
	-- Add pulsing animation when idle
	local pulseTween = TweenService:Create(jumpButton, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.35
	})
	pulseTween:Play()
end

-- Initialize jump button UI
createJumpButton()

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