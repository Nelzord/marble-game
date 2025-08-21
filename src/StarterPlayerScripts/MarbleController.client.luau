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

local baseSpeed = 65 -- movement magnitude; abilities can scale via SpeedMultiplier

local function getMoveDirection(camera: Camera): Vector3
	local cf = camera.CFrame
	local forward = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	if forward.Magnitude > 0 then forward = forward.Unit end
	local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
	if right.Magnitude > 0 then right = right.Unit end
	local dir = forward * inputState.forward + right * inputState.right
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
		return existing
	end
	local ball = Instance.new("Part")
	ball.Name = "CosmeticBall"
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.SmoothPlastic
	ball.Color = Color3.fromRGB(230, 230, 230)
	ball.Size = hrp.Size
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

	local logAccum = 0
	local prevIsInput = false
	local glideHoriz = Vector3.zero
	local stepConn
	stepConn = RunService.RenderStepped:Connect(function(dt)
		if not hrp or not hrp.Parent then
			if stepConn then stepConn:Disconnect() end
			return
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
end

local function onCharacterAdded(character: Model)
	setupController(character)
end

bindInputs()

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded) 